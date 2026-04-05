extends SceneTree

const BattleBuilderScript := preload("res://project/scripts/battle/battle_builder.gd")
const BattleSimulatorScript := preload("res://project/scripts/battle/battle_simulator.gd")
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
	var campaign_state = get_root().get_node_or_null("CampaignState")
	if game_data == null:
		failures.append("GameData autoload is missing.")
	if profile_state == null:
		failures.append("ProfileState autoload is missing.")
	if formation_state == null:
		failures.append("FormationState autoload is missing.")
	if campaign_state == null:
		failures.append("CampaignState autoload is missing.")

	if failures.is_empty() == false:
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	game_data.reload_content()
	profile_state.call("_sync_owned_heroes_to_catalog")
	formation_state.clear_formation()
	campaign_state.call("_sync_stage_progress")

	if game_data.stage_count() < 10:
		failures.append("Expected at least 10 authored campaign stages.")
	if campaign_state.is_stage_unlocked("chapter_01_stage_01") == false:
		failures.append("Stage 1 should be unlocked by default.")
	if campaign_state.is_stage_unlocked("chapter_01_stage_02"):
		failures.append("Stage 2 should start locked before any victory.")

	var formation_plan := {
		"front_left": "aurelian_guard",
		"front_right": "ironclad_brann",
		"back_left": "cinderstrike_nyra",
		"back_center": "duskwisp_iona",
		"back_right": "tidecaller_serin",
	}
	for slot_id in formation_plan.keys():
		var result: Dictionary = formation_state.assign(String(slot_id), String(formation_plan[slot_id]))
		if bool(result.get("ok", false)) == false:
			failures.append("Could not assign %s to %s for campaign smoke." % [String(formation_plan[slot_id]), String(slot_id)])

	campaign_state.select_stage("chapter_01_stage_01")
	if campaign_state.begin_stage_battle("chapter_01_stage_01") == false:
		failures.append("Could not begin battle for stage 1.")

	var pending_stage: Dictionary = campaign_state.pending_battle_definition()
	if pending_stage.is_empty():
		failures.append("Pending battle definition should be available after selecting stage 1.")

	var battle_builder = BattleBuilderScript.new()
	var player_units: Array[Dictionary] = battle_builder.build_player_team_from_formation()
	var enemy_units: Array[Dictionary] = battle_builder.build_enemy_team_from_encounter(pending_stage)

	var simulator = BattleSimulatorScript.new()
	simulator.setup(player_units, enemy_units, {"duration_seconds": float(pending_stage.get("duration_seconds", 60.0))})
	for _step in MAX_SIMULATION_STEPS:
		if simulator.is_finished():
			break
		simulator.step(FIXED_STEP_SECONDS)

	if simulator.is_finished() == false:
		failures.append("Campaign battle simulation did not finish in the allowed number of steps.")

	var won_stage := simulator.winner_team() == BattleSimulatorScript.TEAM_PLAYER
	campaign_state.report_battle_result(won_stage)
	if won_stage == false:
		failures.append("Expected the configured smoke test team to clear stage 1.")
	if campaign_state.is_stage_cleared("chapter_01_stage_01") == false:
		failures.append("Stage 1 should be marked cleared after victory.")
	if campaign_state.is_stage_unlocked("chapter_01_stage_02") == false:
		failures.append("Stage 2 should unlock after clearing stage 1.")

	var result_record: Dictionary = campaign_state.last_battle_result()
	if String(result_record.get("stage_id", "")) != "chapter_01_stage_01":
		failures.append("Last battle result should reference stage 1.")

	formation_state.clear_formation()

	if failures.is_empty():
		print("Phase 6 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)

	quit(1)
