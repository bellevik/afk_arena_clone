extends SceneTree

const BattleBuilderScript := preload("res://project/scripts/battle/battle_builder.gd")
const BattleSimulatorScript := preload("res://project/scripts/battle/battle_simulator.gd")
const SCENE_PATHS := [
	"res://project/scenes/boot/boot.tscn",
	"res://project/scenes/menus/app_shell.tscn",
	"res://project/scenes/menus/main_menu_screen.tscn",
	"res://project/scenes/menus/placeholder_screen.tscn",
	"res://project/scenes/common/debug_panel.tscn",
	"res://project/scenes/heroes/hero_roster_screen.tscn",
	"res://project/scenes/battle/formation_screen.tscn",
	"res://project/scenes/battle/battle_screen.tscn",
	"res://project/scenes/battle/battle_unit_card.tscn",
]

const FIXED_STEP_SECONDS := 0.1
const MAX_SIMULATION_STEPS := 1200


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
	formation_state.clear_formation()

	var assignments := {
		"front_left": "aurelian_guard",
		"front_right": "ironclad_brann",
		"back_left": "cinderstrike_nyra",
		"back_center": "duskwisp_iona",
		"back_right": "tidecaller_serin",
	}
	for slot_id in assignments.keys():
		var result: Dictionary = formation_state.assign(String(slot_id), String(assignments[slot_id]))
		if bool(result.get("ok", false)) == false:
			failures.append("Could not assign %s to %s." % [String(assignments[slot_id]), String(slot_id)])

	var battle_builder = BattleBuilderScript.new()
	if game_data.skill_count() < 8:
		failures.append("Expected at least 8 authored ultimate skill definitions.")

	var encounter: Dictionary = battle_builder.default_battle_encounter()
	var player_units: Array[Dictionary] = battle_builder.build_player_team_from_formation()
	var enemy_units: Array[Dictionary] = battle_builder.build_enemy_team_from_encounter(encounter)
	if player_units.size() != 5:
		failures.append("Expected the configured formation to build five allied battle units.")
	if enemy_units.size() < 5:
		failures.append("Expected the default encounter to provide five enemy units.")

	var skilled_units := 0
	for unit in player_units:
		if Dictionary(unit.get("skill", {})).is_empty() == false:
			skilled_units += 1
	if skilled_units < 5:
		failures.append("Expected all configured allied units to have ultimate skill data.")

	var simulator_a = BattleSimulatorScript.new()
	var simulator_b = BattleSimulatorScript.new()
	var duration := float(encounter.get("duration_seconds", 60.0))
	simulator_a.setup(player_units, enemy_units, {"duration_seconds": duration})
	simulator_b.setup(player_units, enemy_units, {"duration_seconds": duration})

	for _step in MAX_SIMULATION_STEPS:
		if simulator_a.is_finished():
			break
		simulator_a.step(FIXED_STEP_SECONDS)

	for _step in MAX_SIMULATION_STEPS:
		if simulator_b.is_finished():
			break
		simulator_b.step(FIXED_STEP_SECONDS)

	if simulator_a.is_finished() == false:
		failures.append("Primary Phase 5 battle simulation did not finish in the allowed number of steps.")
	if simulator_b.is_finished() == false:
		failures.append("Repeat Phase 5 battle simulation did not finish in the allowed number of steps.")
	if simulator_a.debug_signature() != simulator_b.debug_signature():
		failures.append("Phase 5 battle simulation is not deterministic for identical inputs.")
	if simulator_a.skill_cast_count() < 3:
		failures.append("Expected several ultimate casts during the Phase 5 smoke battle.")

	var used_skill := false
	for line in simulator_a.combat_log():
		if line.contains(" used "):
			used_skill = true
			break
	if used_skill == false:
		failures.append("Combat log should mention ultimate skill usage.")

	if simulator_a.healing_done() <= 0 and simulator_a.shielding_done() <= 0:
		failures.append("Expected at least one healing or shielding effect during the smoke battle.")

	formation_state.clear_formation()

	if failures.is_empty():
		print("Phase 5 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)

	quit(1)
