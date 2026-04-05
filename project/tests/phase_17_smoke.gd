extends SceneTree

const TEST_HERO_ID := "aurelian_guard"
const SCENE_PATHS := [
	"res://project/scenes/boot/boot.tscn",
	"res://project/scenes/menus/app_shell.tscn",
	"res://project/scenes/menus/main_menu_screen.tscn",
	"res://project/scenes/common/debug_panel.tscn",
	"res://project/scenes/heroes/hero_roster_screen.tscn",
	"res://project/scenes/summon/summon_screen.tscn",
	"res://project/scenes/quests/quest_board_screen.tscn",
	"res://project/scenes/battle/formation_screen.tscn",
	"res://project/scenes/battle/battle_screen.tscn",
	"res://project/scenes/campaign/campaign_screen.tscn",
	"res://project/scenes/rewards/rewards_screen.tscn",
	"res://project/scenes/settings/settings_screen.tscn",
]


func _initialize() -> void:
	var failures: Array[String] = []

	await process_frame
	await process_frame

	var root := get_root()
	var game_data = root.get_node_or_null("GameData")
	var profile_state = root.get_node_or_null("ProfileState")
	var save_state = root.get_node_or_null("SaveState")
	var scene_router = root.get_node_or_null("SceneRouter")
	if game_data == null or profile_state == null or save_state == null or scene_router == null:
		failures.append("Phase 17 smoke test requires GameData, ProfileState, SaveState, and SceneRouter autoloads.")

	for scene_path in SCENE_PATHS:
		var scene_resource := ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if scene_resource == null:
			failures.append("Failed to load scene: %s" % scene_path)
			continue
		var packed_scene := scene_resource as PackedScene
		if packed_scene == null:
			failures.append("Resource is not a PackedScene: %s" % scene_path)
			continue
		var instance := packed_scene.instantiate()
		if instance == null:
			failures.append("Failed to instantiate scene: %s" % scene_path)
			continue
		instance.free()

	if failures.is_empty() == false:
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	var had_original_save: bool = save_state.save_exists()
	var original_save_text: String = _read_text(save_state.save_path())

	save_state.reset_save(false)

	if int(game_data.copies_required_for_ascension_tier(0)) <= 0:
		failures.append("Phase 17 should require duplicate copies for the first ascension tier.")
	if int(game_data.max_ascension_tier()) < 3:
		failures.append("Phase 17 should expose multiple authored ascension tiers.")

	profile_state.set_hero_level(TEST_HERO_ID, profile_state.hero_level_cap(TEST_HERO_ID))
	var first_copy: Dictionary = profile_state.award_summoned_hero(TEST_HERO_ID)
	var second_copy: Dictionary = profile_state.award_summoned_hero(TEST_HERO_ID)
	if bool(first_copy.get("granted_copy", false)) == false or bool(second_copy.get("granted_copy", false)) == false:
		failures.append("Duplicate summons should bank merge copies before max ascension.")
	if int(profile_state.hero_merge_copies(TEST_HERO_ID)) != 2:
		failures.append("Two duplicate summons should bank two merge copies for the test hero.")
	if profile_state.can_ascend(TEST_HERO_ID) == false:
		failures.append("Hero should be ascendable at level cap with enough copies.")

	var ascend_result: Dictionary = profile_state.ascend_hero(TEST_HERO_ID)
	if bool(ascend_result.get("ok", false)) == false:
		failures.append("Ascension should succeed once the hero meets the copy and level-cap requirements.")
	if int(profile_state.hero_ascension_tier(TEST_HERO_ID)) != 1:
		failures.append("Ascension should raise the hero to tier 1.")
	if int(profile_state.hero_star_rank(TEST_HERO_ID)) != 2:
		failures.append("First ascension should grant the authored star bonus.")
	if int(profile_state.hero_merge_copies(TEST_HERO_ID)) != 0:
		failures.append("Ascension should spend the required merge copies.")
	if int(profile_state.hero_level_cap(TEST_HERO_ID)) != 30:
		failures.append("Tier 1 ascension should raise the hero level cap to 30.")

	save_state.save_game()
	var saved_text: String = _read_text(save_state.save_path())
	if saved_text.find("\"version\":3") == -1:
		failures.append("Phase 17 should persist the new save version 3 payload.")
	if saved_text.find("\"merge_copies\"") == -1:
		failures.append("Profile save payload should persist banked merge-copy state.")

	profile_state.reset_progression_for_testing()
	if save_state.load_game() == false:
		failures.append("Phase 17 save should load cleanly.")
	if int(profile_state.hero_ascension_tier(TEST_HERO_ID)) != 1:
		failures.append("Ascension tier should restore from save.")
	if int(profile_state.hero_star_rank(TEST_HERO_ID)) != 2:
		failures.append("Star rank should restore from save.")

	var app_shell_scene := ResourceLoader.load("res://project/scenes/menus/app_shell.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if app_shell_scene == null:
		failures.append("Could not load app shell scene for Phase 17 smoke test.")
	else:
		var app_shell := app_shell_scene.instantiate()
		root.add_child(app_shell)
		await process_frame
		await process_frame

		scene_router.go_to("heroes")
		await process_frame
		await process_frame

		var screen_host = app_shell.get_node("RootMargin/Layout/ContentPanel/ContentMargin/ScreenHost")
		if screen_host.get_child_count() <= 0:
			failures.append("Heroes screen should load inside the app shell.")
		else:
			var current_screen: Node = screen_host.get_child(screen_host.get_child_count() - 1)
			if current_screen.get_node_or_null("Margin/Stack/DetailPanel/DetailMargin/DetailStack/ProgressionPanel/ProgressionMargin/ProgressionStack/AscendButton") == null:
				failures.append("Heroes screen should expose the Phase 17 ascend action.")

		app_shell.queue_free()

	if had_original_save:
		_write_text(save_state.save_path(), original_save_text)
		save_state.load_game()
	else:
		save_state.reset_save()

	if failures.is_empty():
		print("Phase 17 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)

	quit(1)


func _read_text(path: String) -> String:
	if FileAccess.file_exists(path) == false:
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(text)
