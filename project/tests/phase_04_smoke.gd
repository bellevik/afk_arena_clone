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
	formation_state.auto_fill()
	var battle_builder = BattleBuilderScript.new()

	if game_data.battle_encounter_count() < 1:
		failures.append("Expected at least one authored battle encounter.")

	var encounter: Dictionary = battle_builder.default_battle_encounter()
	if encounter.is_empty():
		failures.append("Default battle encounter is missing.")

	var player_units: Array[Dictionary] = battle_builder.build_player_team_from_formation()
	var enemy_units: Array[Dictionary] = battle_builder.build_enemy_team_from_encounter(encounter)
	if player_units.size() < 5:
		failures.append("Expected the smoke test player team to auto-fill five heroes.")
	if enemy_units.size() < 5:
		failures.append("Expected the default encounter to provide five enemies.")

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
		failures.append("Primary battle simulation did not finish in the allowed number of steps.")
	if simulator_b.is_finished() == false:
		failures.append("Repeat battle simulation did not finish in the allowed number of steps.")
	if simulator_a.debug_signature() != simulator_b.debug_signature():
		failures.append("Battle simulation is not deterministic for identical inputs.")
	if simulator_a.combat_log().is_empty():
		failures.append("Battle simulation should emit combat log lines.")

	formation_state.clear_formation()

	if failures.is_empty():
		print("Phase 4 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)

	quit(1)
