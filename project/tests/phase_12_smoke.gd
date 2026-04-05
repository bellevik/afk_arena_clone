extends SceneTree

const SCENE_PATHS := [
	"res://project/scenes/boot/boot.tscn",
	"res://project/scenes/menus/app_shell.tscn",
	"res://project/scenes/menus/main_menu_screen.tscn",
	"res://project/scenes/common/debug_panel.tscn",
	"res://project/scenes/heroes/hero_roster_screen.tscn",
	"res://project/scenes/battle/formation_screen.tscn",
	"res://project/scenes/battle/battle_screen.tscn",
	"res://project/scenes/battle/battle_unit_card.tscn",
	"res://project/scenes/campaign/campaign_screen.tscn",
	"res://project/scenes/rewards/rewards_screen.tscn",
]


func _initialize() -> void:
	var failures: Array[String] = []

	await process_frame
	await process_frame

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

	var root := get_root()
	var game_data = root.get_node_or_null("GameData")
	if game_data == null:
		failures.append("GameData autoload should exist for Phase 12 smoke test.")
	else:
		if int(game_data.hero_count()) < 12:
			failures.append("Phase 12 should expose at least 12 authored hero definitions.")
		if int(game_data.enemy_count()) < 6:
			failures.append("Phase 12 should expose at least 6 authored enemy definitions.")
		if int(game_data.stage_count()) < 20:
			failures.append("Phase 12 should expose at least 20 campaign stages.")
		if int(game_data.future_feature_count()) != 5:
			failures.append("Phase 12 should expose exactly 5 future feature hooks.")
		if int(game_data.battle_encounter_count()) < 2:
			failures.append("Phase 12 should expose at least 2 battle test encounters.")

	var app_shell_scene := ResourceLoader.load("res://project/scenes/menus/app_shell.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if app_shell_scene == null:
		failures.append("Could not load app shell scene for Phase 12 smoke test.")
	else:
		var app_shell := app_shell_scene.instantiate()
		root.add_child(app_shell)
		await process_frame
		await process_frame

		var scene_router = root.get_node_or_null("SceneRouter")
		if scene_router == null or scene_router.shell_available() == false:
			failures.append("App shell should register with SceneRouter.")
		else:
			scene_router.go_to("main_menu")
			await process_frame
			await process_frame

			var screen_host = app_shell.get_node("RootMargin/Layout/ContentPanel/ContentMargin/ScreenHost")
			if screen_host.get_child_count() <= 0:
				failures.append("Main menu should load inside the app shell.")
			else:
				var current_screen: Node = screen_host.get_child(screen_host.get_child_count() - 1)
				var content_label := current_screen.get_node_or_null("Content/Stack/ExpansionPanel/ExpansionMargin/ExpansionStack/ContentFootprintLabel")
				var hooks_label := current_screen.get_node_or_null("Content/Stack/ExpansionPanel/ExpansionMargin/ExpansionStack/FutureHooksLabel")
				if content_label == null or String(content_label.text).contains("Heroes: 12") == false:
					failures.append("Main menu should surface expanded content counts.")
				if hooks_label == null or String(hooks_label.text).contains("Summoning Banners") == false:
					failures.append("Main menu should surface future feature hooks.")

		app_shell.queue_free()

	if failures.is_empty():
		print("Phase 12 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)

	quit(1)
