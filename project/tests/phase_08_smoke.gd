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
const TEST_HERO_ID := "aurelian_guard"
const TEST_STAGE_ID := "chapter_01_stage_03"


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
	profile_state.reset_progression_for_testing()
	formation_state.clear_formation()
	campaign_state.call("_sync_stage_progress")
	reward_state.reset_progress_for_testing()

	if game_data.level_cap_for_ascension_tier(0) != 20:
		failures.append("Base ascension tier should cap heroes at level 20.")
	var level_one_cost: Dictionary = game_data.level_up_cost_for_level(1)
	if int(level_one_cost.get("gold", 0)) <= 0 or int(level_one_cost.get("hero_xp", 0)) <= 0:
		failures.append("Level 1 upgrade costs should be authored in progression data.")

	var blocked_upgrade: Dictionary = profile_state.level_up_hero(TEST_HERO_ID)
	if bool(blocked_upgrade.get("ok", false)):
		failures.append("Hero should not level up without resources.")
	if String(blocked_upgrade.get("reason", "")) != "insufficient_resources":
		failures.append("Insufficient resources should block leveling.")

	reward_state.grant_resources({"gold": 12000, "hero_xp": 12000})
	var starting_gold: int = reward_state.gold_balance()
	var starting_hero_xp: int = reward_state.hero_xp_balance()

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
			failures.append("Could not assign %s to %s for progression smoke." % [String(formation_plan[slot_id]), String(slot_id)])

	var battle_builder = BattleBuilderScript.new()
	var stage_data: Dictionary = game_data.get_stage(TEST_STAGE_ID)
	var player_before: Array[Dictionary] = battle_builder.build_player_team_from_formation()
	var enemy_units: Array[Dictionary] = battle_builder.build_enemy_team_from_encounter(stage_data)
	var hero_before: Dictionary = _unit_for_source(player_before, TEST_HERO_ID)
	var hp_before_battle: int = _simulate_battle_remaining_hp(player_before, enemy_units)

	var total_gold_spent := 0
	var total_hero_xp_spent := 0
	for _index in 5:
		var step_cost: Dictionary = profile_state.level_up_cost(TEST_HERO_ID)
		total_gold_spent += int(step_cost.get("gold", 0))
		total_hero_xp_spent += int(step_cost.get("hero_xp", 0))
		var upgrade_result: Dictionary = profile_state.level_up_hero(TEST_HERO_ID)
		if bool(upgrade_result.get("ok", false)) == false:
			failures.append("Expected five successful level-ups for %s." % TEST_HERO_ID)
			break

	if profile_state.hero_level(TEST_HERO_ID) != 6:
		failures.append("Hero should reach level 6 after five upgrades.")
	if reward_state.gold_balance() != starting_gold - total_gold_spent:
		failures.append("Gold balance should decrease by the exact upgrade cost total.")
	if reward_state.hero_xp_balance() != starting_hero_xp - total_hero_xp_spent:
		failures.append("Hero XP balance should decrease by the exact upgrade cost total.")

	var player_after: Array[Dictionary] = battle_builder.build_player_team_from_formation()
	var hero_after: Dictionary = _unit_for_source(player_after, TEST_HERO_ID)
	if int(hero_after.get("level", 1)) != 6:
		failures.append("Battle payload should reflect the upgraded hero level.")
	if int(hero_after.get("power", 0)) <= int(hero_before.get("power", 0)):
		failures.append("Hero power should increase after leveling.")

	var stats_before: Dictionary = hero_before.get("stats", {})
	var stats_after: Dictionary = hero_after.get("stats", {})
	if int(stats_after.get("hp", 0)) <= int(stats_before.get("hp", 0)):
		failures.append("Hero HP should increase after leveling.")
	if int(stats_after.get("attack", 0)) <= int(stats_before.get("attack", 0)):
		failures.append("Hero attack should increase after leveling.")

	var hp_after_battle: int = _simulate_battle_remaining_hp(player_after, enemy_units)
	if hp_after_battle < hp_before_battle:
		failures.append("Upgraded formation should not perform worse in the deterministic battle comparison.")

	reward_state.grant_resources({"gold": 20000, "hero_xp": 20000})
	while profile_state.hero_level(TEST_HERO_ID) < profile_state.hero_level_cap(TEST_HERO_ID):
		var cap_result: Dictionary = profile_state.level_up_hero(TEST_HERO_ID)
		if bool(cap_result.get("ok", false)) == false:
			failures.append("Hero should keep leveling until the base cap is reached.")
			break

	var capped_result: Dictionary = profile_state.level_up_hero(TEST_HERO_ID)
	if String(capped_result.get("reason", "")) != "level_cap_reached":
		failures.append("Leveling beyond the current ascension cap should be blocked.")

	formation_state.clear_formation()

	if failures.is_empty():
		print("Phase 8 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)

	quit(1)


func _unit_for_source(units: Array[Dictionary], source_id: String) -> Dictionary:
	for unit in units:
		if String(unit.get("source_id", "")) == source_id:
			return unit
	return {}


func _simulate_battle_remaining_hp(player_units: Array[Dictionary], enemy_units: Array[Dictionary]) -> int:
	var game_data = get_root().get_node("GameData")
	var simulator = BattleSimulatorScript.new()
	simulator.setup(player_units, enemy_units, {"duration_seconds": float(game_data.get_stage(TEST_STAGE_ID).get("duration_seconds", 60.0))})
	for _step in MAX_SIMULATION_STEPS:
		if simulator.is_finished():
			break
		simulator.step(FIXED_STEP_SECONDS)

	var remaining_hp := 0
	for snapshot in simulator.units():
		if String(snapshot.get("team", "")) != BattleSimulatorScript.TEAM_PLAYER:
			continue
		remaining_hp += int(snapshot.get("hp", 0))
	return remaining_hp
