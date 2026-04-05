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
const FORMATION_PLAN := {
	"front_left": "aurelian_guard",
	"front_right": "ironclad_brann",
	"back_left": "cinderstrike_nyra",
	"back_center": "duskwisp_iona",
	"back_right": "tidecaller_serin",
}


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
	var reward_state = get_root().get_node_or_null("RewardState")
	var inventory_state = get_root().get_node_or_null("InventoryState")
	if game_data == null:
		failures.append("GameData autoload is missing.")
	if profile_state == null:
		failures.append("ProfileState autoload is missing.")
	if formation_state == null:
		failures.append("FormationState autoload is missing.")
	if reward_state == null:
		failures.append("RewardState autoload is missing.")
	if inventory_state == null:
		failures.append("InventoryState autoload is missing.")

	if failures.is_empty() == false:
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	game_data.reload_content()
	profile_state.call("_sync_owned_heroes_to_catalog")
	profile_state.reset_progression_for_testing()
	formation_state.clear_formation()
	reward_state.reset_progress_for_testing()
	inventory_state.reset_inventory_for_testing()

	if game_data.item_count() < 6:
		failures.append("Expected at least six authored equipment items.")
	if inventory_state.inventory_count("bronze_blade") != 2:
		failures.append("Bronze Blade should start with count 2.")

	for slot_id in FORMATION_PLAN.keys():
		var assign_result: Dictionary = formation_state.assign(String(slot_id), String(FORMATION_PLAN[slot_id]))
		if bool(assign_result.get("ok", false)) == false:
			failures.append("Could not assign %s to %s for equipment smoke." % [String(FORMATION_PLAN[slot_id]), String(slot_id)])

	var stats_before: Dictionary = profile_state.hero_stats(TEST_HERO_ID)
	var team_power_before: int = formation_state.team_power()
	var battle_builder = BattleBuilderScript.new()
	var stage_data: Dictionary = game_data.get_stage(TEST_STAGE_ID)
	var player_before: Array[Dictionary] = battle_builder.build_player_team_from_formation()
	var enemy_units: Array[Dictionary] = battle_builder.build_enemy_team_from_encounter(stage_data)
	var hero_before: Dictionary = _unit_for_source(player_before, TEST_HERO_ID)
	var hp_before_battle: int = _simulate_battle_remaining_hp(player_before, enemy_units)

	var equip_weapon: Dictionary = inventory_state.equip(TEST_HERO_ID, "bronze_blade")
	var equip_armor: Dictionary = inventory_state.equip(TEST_HERO_ID, "wardsteel_cuirass")
	var equip_accessory: Dictionary = inventory_state.equip(TEST_HERO_ID, "ember_charm")
	if bool(equip_weapon.get("ok", false)) == false:
		failures.append("Expected Bronze Blade to equip successfully.")
	if bool(equip_armor.get("ok", false)) == false:
		failures.append("Expected Wardsteel Cuirass to equip successfully.")
	if bool(equip_accessory.get("ok", false)) == false:
		failures.append("Expected Ember Charm to equip successfully.")

	var stats_after: Dictionary = profile_state.hero_stats(TEST_HERO_ID)
	if int(stats_after.get("hp", 0)) != int(stats_before.get("hp", 0)) + 300:
		failures.append("HP should increase by the combined equipped bonuses.")
	if int(stats_after.get("attack", 0)) != int(stats_before.get("attack", 0)) + 40:
		failures.append("Attack should increase by the combined equipped bonuses.")
	if int(stats_after.get("defense", 0)) != int(stats_before.get("defense", 0)) + 18:
		failures.append("Defense should increase by the combined equipped bonuses.")
	if int(stats_after.get("speed", 0)) != int(stats_before.get("speed", 0)) + 4:
		failures.append("Speed should increase by the combined equipped bonuses.")

	if inventory_state.inventory_count("bronze_blade") != 1:
		failures.append("Equipping Bronze Blade should reduce its count by one.")
	if inventory_state.inventory_count("wardsteel_cuirass") != 1:
		failures.append("Equipping Wardsteel Cuirass should reduce its count by one.")
	if inventory_state.inventory_count("ember_charm") != 1:
		failures.append("Equipping Ember Charm should reduce its count by one.")

	var team_power_after: int = formation_state.team_power()
	if team_power_after <= team_power_before:
		failures.append("Team power should increase after equipping gear.")

	var player_after: Array[Dictionary] = battle_builder.build_player_team_from_formation()
	var hero_after: Dictionary = _unit_for_source(player_after, TEST_HERO_ID)
	var hero_after_stats: Dictionary = hero_after.get("stats", {})
	if int(hero_after_stats.get("attack", 0)) != int(stats_after.get("attack", 0)):
		failures.append("Battle payload should include equipped item bonuses.")

	var hp_after_battle: int = _simulate_battle_remaining_hp(player_after, enemy_units)
	if hp_after_battle < hp_before_battle:
		failures.append("Equipped formation should not perform worse in deterministic battle comparison.")

	var replace_weapon: Dictionary = inventory_state.equip(TEST_HERO_ID, "sunforged_spear")
	if bool(replace_weapon.get("ok", false)) == false:
		failures.append("Expected Sunforged Spear to replace the Bronze Blade.")
	if inventory_state.inventory_count("bronze_blade") != 2:
		failures.append("Replacing a weapon should return the old weapon to inventory.")
	if inventory_state.inventory_count("sunforged_spear") != 0:
		failures.append("Equipping Sunforged Spear should consume its only copy.")

	var replaced_stats: Dictionary = profile_state.hero_stats(TEST_HERO_ID)
	if int(replaced_stats.get("attack", 0)) != int(stats_before.get("attack", 0)) + 48:
		failures.append("Replacing the weapon should swap to the new attack bonus.")
	if int(replaced_stats.get("speed", 0)) != int(stats_before.get("speed", 0)) + 10:
		failures.append("Replacing the weapon should apply the new speed bonus.")

	var unequip_result: Dictionary = inventory_state.unequip(TEST_HERO_ID, "weapon")
	if bool(unequip_result.get("ok", false)) == false:
		failures.append("Expected equipped weapon to unequip successfully.")
	if inventory_state.inventory_count("sunforged_spear") != 1:
		failures.append("Unequipping should return the weapon to inventory.")

	var final_stats: Dictionary = profile_state.hero_stats(TEST_HERO_ID)
	if int(final_stats.get("attack", 0)) != int(stats_before.get("attack", 0)) + 14:
		failures.append("Unequipping the weapon should remove its attack bonus while keeping accessory bonuses.")

	formation_state.clear_formation()

	if failures.is_empty():
		print("Phase 9 smoke test passed.")
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
