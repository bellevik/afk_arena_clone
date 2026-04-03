extends SceneTree

const SCENE_PATHS := [
	"res://project/scenes/boot/boot.tscn",
	"res://project/scenes/menus/app_shell.tscn",
	"res://project/scenes/menus/main_menu_screen.tscn",
	"res://project/scenes/menus/placeholder_screen.tscn",
	"res://project/scenes/common/debug_panel.tscn",
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
		instance = null
		packed_scene = null
		scene_resource = null

	var router_script := ResourceLoader.load("res://project/scripts/core/scene_router.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	if router_script == null:
		failures.append("Failed to load SceneRouter script.")
	else:
		var router = router_script.new()
		for screen_id in router.available_screens():
			var definition: Dictionary = router.get_screen_definition(screen_id)
			var scene_path := String(definition.get("scene", ""))
			if scene_path.is_empty():
				failures.append("SceneRouter definition for '%s' is missing a scene path." % screen_id)
			elif not ResourceLoader.exists(scene_path):
				failures.append("SceneRouter references a missing scene for '%s': %s" % [screen_id, scene_path])
		router.free()
		router = null
		router_script = null

	if failures.is_empty():
		print("Phase 1 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)

	quit(1)
