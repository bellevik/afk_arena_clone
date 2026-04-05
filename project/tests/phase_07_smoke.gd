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
	"res://project/scenes/rewards/rewards_screen.tscn",
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
	var reward_state = get_root().get_node_or_null("RewardState")
	if game_data == null:
		failures.append("GameData autoload is missing.")
	if profile_state == null:
		failures.append("ProfileState autoload is missing.")
	if formation_state == null:
		failures.append("FormationState autoload is missing.")
	if campaign_state == null:
		failures.append("CampaignState autoload is missing.")
	if reward_state == null:
		failures.append("RewardState autoload is missing.")

	if failures.is_empty() == false:
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	game_data.reload_content()
	profile_state.call("_sync_owned_heroes_to_catalog")
	formation_state.clear_formation()
	campaign_state.call("_sync_stage_progress")
	reward_state.reset_progress_for_testing()

	var rewards_screen_scene := load("res://project/scenes/rewards/rewards_screen.tscn") as PackedScene
	var rewards_screen := rewards_screen_scene.instantiate()
	get_root().add_child(rewards_screen)
	await process_frame

	if reward_state.gold_balance() != 0 or reward_state.hero_xp_balance() != 0:
		failures.append("Reward balances should reset to zero for the smoke test.")

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
			failures.append("Could not assign %s to %s for reward smoke." % [String(formation_plan[slot_id]), String(slot_id)])

	campaign_state.select_stage("chapter_01_stage_01")
	if campaign_state.begin_stage_battle("chapter_01_stage_01") == false:
		failures.append("Could not begin battle for stage 1.")

	var pending_stage: Dictionary = campaign_state.pending_battle_definition()
	if pending_stage.is_empty():
		failures.append("Pending battle definition should be available for stage 1.")

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
		failures.append("Stage 1 reward smoke battle did not finish in the allowed number of steps.")

	var won_stage := simulator.winner_team() == BattleSimulatorScript.TEAM_PLAYER
	if won_stage == false:
		failures.append("Expected the configured smoke test team to clear stage 1.")
	else:
		var battle_rewards: Dictionary = reward_state.grant_battle_rewards("campaign_stage", "chapter_01_stage_01", true)
		campaign_state.report_battle_result(true)
		if int(battle_rewards.get("gold", 0)) != 120 or int(battle_rewards.get("hero_xp", 0)) != 80:
			failures.append("Stage 1 battle rewards should grant 120 gold and 80 hero XP.")
		if reward_state.gold_balance() != 120 or reward_state.hero_xp_balance() != 80:
			failures.append("Reward balances should reflect stage 1 battle rewards.")

	if reward_state.highest_stage_snapshot_id() != "chapter_01_stage_01":
		failures.append("Highest AFK snapshot should track the highest cleared stage.")

	reward_state.simulate_afk_elapsed(7200)
	var pending_afk: Dictionary = reward_state.current_afk_rewards()
	if int(pending_afk.get("gold", 0)) != 180 or int(pending_afk.get("hero_xp", 0)) != 110:
		failures.append("Two hours of stage 1 AFK rewards should yield 180 gold and 110 hero XP.")

	var claim_rewards: Dictionary = reward_state.claim_afk_rewards()
	if int(claim_rewards.get("gold", 0)) != 180 or int(claim_rewards.get("hero_xp", 0)) != 110:
		failures.append("AFK claim should return the pending AFK rewards.")
	if reward_state.gold_balance() != 300 or reward_state.hero_xp_balance() != 190:
		failures.append("Balances should include battle rewards plus claimed AFK rewards.")

	if campaign_state.begin_stage_battle("chapter_01_stage_02") == false:
		failures.append("Could not begin battle for stage 2 after clearing stage 1.")
	campaign_state.report_battle_result(true)
	if reward_state.highest_stage_snapshot_id() != "chapter_01_stage_02":
		failures.append("Highest AFK snapshot should advance after clearing stage 2.")

	reward_state.simulate_afk_elapsed(3600)
	var upgraded_afk: Dictionary = reward_state.current_afk_rewards()
	if int(upgraded_afk.get("gold", 0)) != 102 or int(upgraded_afk.get("hero_xp", 0)) != 62:
		failures.append("One hour of stage 2 AFK rewards should yield 102 gold and 62 hero XP.")

	rewards_screen.queue_free()
	formation_state.clear_formation()

	if failures.is_empty():
		print("Phase 7 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)

	quit(1)
