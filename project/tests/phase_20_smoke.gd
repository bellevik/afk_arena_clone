extends SceneTree

const SCENE_PATHS := [
	"res://project/scenes/boot/boot.tscn",
	"res://project/scenes/menus/app_shell.tscn",
	"res://project/scenes/menus/main_menu_screen.tscn",
	"res://project/scenes/common/debug_panel.tscn",
	"res://project/scenes/heroes/hero_roster_screen.tscn",
	"res://project/scenes/summon/summon_screen.tscn",
	"res://project/scenes/quests/quest_board_screen.tscn",
	"res://project/scenes/events/event_screen.tscn",
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
	var reward_state = root.get_node_or_null("RewardState")
	var event_state = root.get_node_or_null("EventState")
	var campaign_state = root.get_node_or_null("CampaignState")
	var summon_state = root.get_node_or_null("SummonState")
	var save_state = root.get_node_or_null("SaveState")
	var scene_router = root.get_node_or_null("SceneRouter")

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

	if game_data == null or reward_state == null or event_state == null or campaign_state == null or summon_state == null or save_state == null or scene_router == null:
		failures.append("Phase 20 smoke test requires GameData, RewardState, EventState, CampaignState, SummonState, SaveState, and SceneRouter autoloads.")

	if failures.is_empty() == false:
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	var had_original_save: bool = save_state.save_exists()
	var original_save_text: String = _read_text(save_state.save_path())

	save_state.reset_save(false)

	if game_data.live_event_count() < 1:
		failures.append("Phase 20 should author at least one live event.")

	var event_id := String(game_data.default_live_event_id())
	var event: Dictionary = game_data.get_live_event(event_id)
	if event.is_empty():
		failures.append("Default live event should resolve from GameData.")
	else:
		if event_state.is_event_active(event_id) == false:
			failures.append("The authored Phase 20 event should currently be active.")
		if String(event.get("linked_banner_id", "")).is_empty():
			failures.append("Live events should define a linked summon banner hook.")

	event_state.select_event(event_id)
	await process_frame

	campaign_state.stage_cleared.emit("chapter_01_stage_01")
	summon_state.summon_completed.emit({"pull_count": 10})
	await process_frame

	var points_after_progress: int = event_state.event_points(event_id)
	if points_after_progress != 120:
		failures.append("Stage clear plus a 10-pull should yield 120 event points in the default Phase 20 event.")

	var claim_result: Dictionary = event_state.claim_milestone(event_id, "emberwake_m1")
	if bool(claim_result.get("ok", false)) == false:
		failures.append("The first event milestone should be claimable after 120 points.")
	if reward_state.premium_shard_balance() != 120:
		failures.append("Claiming the first event milestone should grant 120 premium shards.")

	save_state.save_game()
	var saved_text: String = _read_text(save_state.save_path())
	if saved_text.find("\"version\":5") == -1:
		failures.append("Phase 20 should persist save version 5.")
	if saved_text.find("\"events\"") == -1 or saved_text.find("\"emberwake_m1\"") == -1:
		failures.append("Phase 20 save payload should persist event progress and claimed milestones.")

	event_state.debug_grant_points_to_active_event(250)
	if save_state.load_game() == false:
		failures.append("Phase 20 save should reload cleanly.")
	if event_state.event_points(event_id) != points_after_progress:
		failures.append("Event points should restore from save.")
	if event_state.is_milestone_claimed(event_id, "emberwake_m1") == false:
		failures.append("Claimed milestone state should restore from save.")

	var app_shell_scene := ResourceLoader.load("res://project/scenes/menus/app_shell.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if app_shell_scene == null:
		failures.append("Could not load app shell scene for Phase 20 smoke test.")
	else:
		var app_shell := app_shell_scene.instantiate()
		root.add_child(app_shell)
		await process_frame
		await process_frame

		scene_router.go_to("events")
		await process_frame
		await process_frame

		var screen_host = app_shell.get_node("RootMargin/Layout/ContentPanel/ContentMargin/ScreenHost")
		if screen_host.get_child_count() <= 0:
			failures.append("Events screen should load inside the app shell.")
		else:
			var current_screen: Node = screen_host.get_child(screen_host.get_child_count() - 1)
			if current_screen.get_node_or_null("Content/Stack/SummaryPanel/SummaryMargin/SummaryStack/OpenBannerButton") == null:
				failures.append("Events screen should expose the linked-banner action.")

		app_shell.queue_free()

	if had_original_save:
		_write_text(save_state.save_path(), original_save_text)
		save_state.load_game()
	else:
		save_state.reset_save()

	if failures.is_empty():
		print("Phase 20 smoke test passed.")
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
