extends SceneTree

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
	var reward_state = root.get_node_or_null("RewardState")
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

	if game_data == null or reward_state == null or summon_state == null or save_state == null or scene_router == null:
		failures.append("Phase 19 smoke test requires GameData, RewardState, SummonState, SaveState, and SceneRouter autoloads.")

	if failures.is_empty() == false:
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	var had_original_save: bool = save_state.save_exists()
	var original_save_text: String = _read_text(save_state.save_path())

	if game_data.summon_banner_count() < 2:
		failures.append("Phase 19 should keep at least 2 summon banners.")

	var default_banner: Dictionary = game_data.get_summon_banner(game_data.default_summon_banner_id())
	if String(default_banner.get("currency_id", "")).is_empty():
		failures.append("Phase 19 summon banners should define a banner-specific currency id.")
	if int(default_banner.get("exchange_shards_single", 0)) <= 0:
		failures.append("Phase 19 summon banners should define premium shard exchange costs.")

	save_state.reset_save(false)

	var banner_id := String(game_data.default_summon_banner_id())
	var token_id := String(default_banner.get("currency_id", ""))
	summon_state.select_banner(banner_id)
	summon_state.debug_seed_rng(1337)
	reward_state.grant_resources({"premium_shards": 2000})

	if reward_state.premium_shard_balance() != 2000:
		failures.append("Premium shard balance should update through RewardState.")

	var exchange_result: Dictionary = summon_state.exchange_selected_banner_currency(10)
	if bool(exchange_result.get("ok", false)) == false:
		failures.append("Selected banner currency exchange should succeed with enough premium shards.")
	if reward_state.banner_token_balance(token_id) != 10:
		failures.append("Ten-pull exchange should grant 10 banner tokens.")

	var pull_result: Dictionary = summon_state.perform_pull(10)
	if bool(pull_result.get("ok", false)) == false:
		failures.append("SummonState should consume banner tokens to perform a 10-pull.")
	if reward_state.banner_token_balance(token_id) != 0:
		failures.append("Ten-pull should consume the exchanged banner tokens.")
	if summon_state.last_results().size() != 10:
		failures.append("Ten-pull should still populate 10 summon results.")

	save_state.save_game()
	var saved_text: String = _read_text(save_state.save_path())
	if saved_text.find("\"version\":4") == -1:
		failures.append("Phase 19 should persist save version 4.")
	if saved_text.find("\"premium_shards\"") == -1 or saved_text.find(token_id) == -1:
		failures.append("Phase 19 save payload should persist premium shards and banner tokens.")

	var saved_shards: int = reward_state.premium_shard_balance()
	reward_state.grant_resources({"premium_shards": 77, token_id: 4})
	if save_state.load_game() == false:
		failures.append("Phase 19 save should reload cleanly.")
	if reward_state.premium_shard_balance() != saved_shards:
		failures.append("Premium shard balance should restore from save.")
	if reward_state.banner_token_balance(token_id) != 0:
		failures.append("Banner token balance should restore from save.")

	var app_shell_scene := ResourceLoader.load("res://project/scenes/menus/app_shell.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if app_shell_scene == null:
		failures.append("Could not load app shell scene for Phase 19 smoke test.")
	else:
		var app_shell := app_shell_scene.instantiate()
		root.add_child(app_shell)
		await process_frame
		await process_frame

		scene_router.go_to("summon")
		await process_frame
		await process_frame

		var screen_host = app_shell.get_node("RootMargin/Layout/ContentPanel/ContentMargin/ScreenHost")
		if screen_host.get_child_count() <= 0:
			failures.append("Summon screen should load inside the app shell.")
		else:
			var current_screen: Node = screen_host.get_child(screen_host.get_child_count() - 1)
			if current_screen.get_node_or_null("Content/Stack/ActionsPanel/ActionsMargin/ActionsStack/ExchangeRow/ExchangeSingleButton") == null:
				failures.append("Summon screen should expose the Phase 19 exchange actions.")

		app_shell.queue_free()

	if had_original_save:
		_write_text(save_state.save_path(), original_save_text)
		save_state.load_game()
	else:
		save_state.reset_save()

	if failures.is_empty():
		print("Phase 19 smoke test passed.")
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
