extends SceneTree

const SCENE_PATHS := [
	"res://project/scenes/boot/boot.tscn",
	"res://project/scenes/menus/app_shell.tscn",
	"res://project/scenes/menus/main_menu_screen.tscn",
	"res://project/scenes/menus/placeholder_screen.tscn",
	"res://project/scenes/common/debug_panel.tscn",
	"res://project/scenes/heroes/hero_roster_screen.tscn",
	"res://project/scenes/heroes/hero_roster_card.tscn",
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

	var data_script := load("res://project/scripts/data/game_data.gd")
	if data_script == null:
		failures.append("Failed to load GameData script.")
	else:
		var game_data = data_script.new()
		game_data.reload_content()
		if game_data.hero_count() < 8:
			failures.append("Expected at least 8 hero definitions, found %d." % game_data.hero_count())
		if game_data.enemy_count() < 3:
			failures.append("Expected at least 3 enemy definitions, found %d." % game_data.enemy_count())

		for hero in game_data.get_all_heroes():
			if String(hero.get("hero_id", "")).is_empty() or String(hero.get("display_name", "")).is_empty():
				failures.append("Hero definition has missing id or name.")
			var base_stats: Dictionary = hero.get("base_stats", {})
			if int(base_stats.get("hp", 0)) <= 0 or int(base_stats.get("attack", 0)) <= 0:
				failures.append("Hero definition %s has invalid base stats." % String(hero.get("hero_id", "")))

		game_data.free()

	if failures.is_empty():
		print("Phase 2 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)

	quit(1)
