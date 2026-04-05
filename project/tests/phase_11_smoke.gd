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

	var app_shell_scene := ResourceLoader.load("res://project/scenes/menus/app_shell.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if app_shell_scene == null:
		push_error("Could not load app shell scene for Phase 11 smoke test.")
		quit(1)
		return
	var app_shell := app_shell_scene.instantiate()
	get_root().add_child(app_shell)
	await process_frame
	await process_frame

	var scene_router = get_root().get_node_or_null("SceneRouter")
	if scene_router == null or scene_router.shell_available() == false:
		failures.append("App shell should register itself with SceneRouter.")

	var transition_overlay := app_shell.get_node_or_null("TransitionOverlay")
	if transition_overlay == null:
		failures.append("App shell should include the transition overlay.")

	var nav_bar := app_shell.get_node_or_null("RootMargin/Layout/NavPanel/NavMargin/NavBar")
	if nav_bar == null or nav_bar.get_child_count() < 6:
		failures.append("Bottom navigation should build all main route buttons.")
	else:
		for child in nav_bar.get_children():
			if child is BaseButton == false:
				continue
			if child.has_meta("theme_feedback_wired") == false:
				failures.append("Navigation buttons should have shared button feedback wiring.")
				break

	scene_router.go_to("main_menu")
	await process_frame
	await process_frame
	var screen_host = app_shell.get_node("RootMargin/Layout/ContentPanel/ContentMargin/ScreenHost")
	var app_state = get_root().get_node_or_null("AppState")
	if app_state == null:
		failures.append("AppState autoload should be available during UI smoke test.")
	elif String(app_state.current_screen) != "main_menu" or screen_host.get_child_count() <= 0:
		failures.append("Main menu should load inside the app shell.")
	else:
		var current_screen: Node = screen_host.get_child(screen_host.get_child_count() - 1)
		var action_grid := current_screen.get_node_or_null("Content/Stack/ActionsPanel/ActionsMargin/ActionsStack/ActionGrid")
		if action_grid == null or int(action_grid.columns) != 1:
			failures.append("Main menu action grid should use a single portrait-friendly column.")

	scene_router.go_to("heroes")
	await process_frame
	await process_frame
	scene_router.go_to("battle")
	await process_frame
	await process_frame
	scene_router.go_to("rewards")
	await process_frame
	await process_frame

	if String(app_state.current_screen) != "rewards" or screen_host.get_child_count() <= 0:
		failures.append("Rewards screen should load after routed transitions.")

	app_shell.queue_free()

	if failures.is_empty():
		print("Phase 11 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)

	quit(1)
