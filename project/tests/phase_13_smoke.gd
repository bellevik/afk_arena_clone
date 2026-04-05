extends SceneTree

const SCENE_PATHS := [
	"res://project/scenes/boot/boot.tscn",
	"res://project/scenes/menus/app_shell.tscn",
	"res://project/scenes/menus/main_menu_screen.tscn",
	"res://project/scenes/common/debug_panel.tscn",
	"res://project/scenes/heroes/hero_roster_screen.tscn",
	"res://project/scenes/summon/summon_screen.tscn",
	"res://project/scenes/battle/formation_screen.tscn",
	"res://project/scenes/battle/battle_screen.tscn",
	"res://project/scenes/campaign/campaign_screen.tscn",
	"res://project/scenes/rewards/rewards_screen.tscn",
]


func _initialize() -> void:
	var failures: Array[String] = []

	await process_frame
	await process_frame

	var root := get_root()
	var game_data = root.get_node_or_null("GameData")
	var reward_state = root.get_node_or_null("RewardState")
	var summon_state = root.get_node_or_null("SummonState")
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

	if game_data == null or reward_state == null or summon_state == null or scene_router == null:
		failures.append("Phase 13 smoke test requires GameData, RewardState, SummonState, and SceneRouter autoloads.")
	elif int(game_data.summon_banner_count()) < 2:
		failures.append("Phase 13 should expose at least 2 summon banners.")
	else:
		reward_state.grant_resources({"gold": 20000})
		summon_state.debug_seed_rng(1337)
		summon_state.select_banner(String(game_data.default_summon_banner_id()))
		var before_pulls := int(summon_state.total_pulls())
		var result = summon_state.perform_pull(10)
		if bool(result.get("ok", false)) == false:
			failures.append("SummonState should complete a 10-pull with sufficient gold.")
		elif int(summon_state.total_pulls()) != before_pulls + 10:
			failures.append("10-pull should increment the summon total by 10.")
		elif summon_state.last_results().size() != 10:
			failures.append("10-pull should populate 10 summon results.")

	var app_shell_scene := ResourceLoader.load("res://project/scenes/menus/app_shell.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if app_shell_scene == null:
		failures.append("Could not load app shell scene for Phase 13 smoke test.")
	else:
		var app_shell := app_shell_scene.instantiate()
		get_root().add_child(app_shell)
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
			if current_screen.get_node_or_null("Content/Stack/BannerPanel/BannerMargin/BannerStack/BannerList") == null:
				failures.append("Summon screen should build the banner list.")
			if current_screen.get_node_or_null("Content/Stack/ActionsPanel/ActionsMargin/ActionsRow/SinglePullButton") == null:
				failures.append("Summon screen should expose pull actions.")

		app_shell.queue_free()

	if failures.is_empty():
		print("Phase 13 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)

	quit(1)
