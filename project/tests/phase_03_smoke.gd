extends SceneTree

const SCENE_PATHS := [
	"res://project/scenes/boot/boot.tscn",
	"res://project/scenes/menus/app_shell.tscn",
	"res://project/scenes/menus/main_menu_screen.tscn",
	"res://project/scenes/menus/placeholder_screen.tscn",
	"res://project/scenes/common/debug_panel.tscn",
	"res://project/scenes/heroes/hero_roster_screen.tscn",
	"res://project/scenes/battle/formation_screen.tscn",
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

	var game_data = get_root().get_node_or_null("GameData")
	var profile_state = get_root().get_node_or_null("ProfileState")
	var formation_state = get_root().get_node_or_null("FormationState")

	if game_data == null:
		failures.append("GameData autoload is missing.")
	if profile_state == null:
		failures.append("ProfileState autoload is missing.")
	if formation_state == null:
		failures.append("FormationState autoload is missing.")

	if failures.is_empty() == false:
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	game_data.reload_content()
	profile_state.call("_sync_owned_heroes_to_catalog")
	formation_state.call("_prune_invalid_assignments")

	if game_data.hero_count() < 8:
		failures.append("Expected at least 8 hero definitions, found %d." % game_data.hero_count())
	if profile_state.owned_hero_count() < 8:
		failures.append("Expected at least 8 owned heroes, found %d." % profile_state.owned_hero_count())

	formation_state.clear_formation()
	if formation_state.assigned_count() != 0:
		failures.append("Formation should be empty after clear.")

	var first_hero_id := String(profile_state.first_owned_hero_id())
	if first_hero_id.is_empty():
		failures.append("No owned heroes available for formation tests.")
	else:
		var assign_result: Dictionary = formation_state.assign("front_left", first_hero_id)
		if bool(assign_result.get("ok", false)) == false:
			failures.append("Could not assign first hero to front_left.")

		var duplicate_result: Dictionary = formation_state.assign("front_right", first_hero_id)
		if bool(duplicate_result.get("ok", false)):
			failures.append("Duplicate assignment should be rejected.")

	formation_state.auto_fill()
	if formation_state.assigned_count() < 5:
		failures.append("Auto-fill should populate all five slots when enough heroes are owned.")
	if formation_state.team_power() <= 0:
		failures.append("Team power should be positive after auto-fill.")

	formation_state.clear_formation()

	if failures.is_empty():
		print("Phase 3 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)

	quit(1)
