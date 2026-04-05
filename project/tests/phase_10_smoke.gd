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

const TEST_HERO_ID := "aurelian_guard"


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
	var inventory_state = get_root().get_node_or_null("InventoryState")
	var save_state = get_root().get_node_or_null("SaveState")
	var debug_tools = get_root().get_node_or_null("DebugTools")
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
	if inventory_state == null:
		failures.append("InventoryState autoload is missing.")
	if save_state == null:
		failures.append("SaveState autoload is missing.")
	if debug_tools == null:
		failures.append("DebugTools autoload is missing.")

	if failures.is_empty() == false:
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	game_data.reload_content()
	save_state.reset_save()

	reward_state.grant_resources({"gold": 1800, "hero_xp": 1400})
	profile_state.set_hero_level(TEST_HERO_ID, 4)
	inventory_state.equip(TEST_HERO_ID, "bronze_blade")
	inventory_state.equip(TEST_HERO_ID, "wardsteel_cuirass")
	formation_state.assign("front_left", TEST_HERO_ID)
	formation_state.assign("front_right", "ironclad_brann")
	campaign_state.begin_stage_battle("chapter_01_stage_01")
	campaign_state.report_battle_result(true)
	reward_state.simulate_afk_elapsed(3600)
	save_state.save_game()

	var saved_text := _read_text(save_state.save_path())
	if saved_text.is_empty():
		failures.append("Save file should exist after calling save_game().")

	reward_state.grant_resources({"gold": 999, "hero_xp": 999})
	profile_state.set_hero_level(TEST_HERO_ID, 1)
	inventory_state.unequip(TEST_HERO_ID, "weapon")
	inventory_state.unequip(TEST_HERO_ID, "armor")
	formation_state.clear_formation()
	campaign_state.reset_persistent_state()

	_write_text(save_state.save_path(), saved_text)
	if save_state.load_game() == false:
		failures.append("SaveState should load the valid save file.")

	if profile_state.hero_level(TEST_HERO_ID) != 4:
		failures.append("Hero level should restore from save.")
	if formation_state.get_assigned_hero_id("front_left") != TEST_HERO_ID:
		failures.append("Formation assignment should restore from save.")
	if campaign_state.is_stage_cleared("chapter_01_stage_01") == false:
		failures.append("Campaign clear state should restore from save.")
	if campaign_state.is_stage_unlocked("chapter_01_stage_02") == false:
		failures.append("Unlocked campaign stages should restore from save.")
	if inventory_state.equipped_item_id(TEST_HERO_ID, "weapon") != "bronze_blade":
		failures.append("Equipped weapon should restore from save.")
	if inventory_state.equipped_item_id(TEST_HERO_ID, "armor") != "wardsteel_cuirass":
		failures.append("Equipped armor should restore from save.")
	if reward_state.gold_balance() != 1800:
		failures.append("Gold balance should restore from save.")
	if reward_state.hero_xp_balance() != 1400:
		failures.append("Hero XP balance should restore from save.")
	if int(reward_state.current_afk_rewards().get("gold", 0)) <= 0:
		failures.append("AFK timestamp should restore enough state to produce pending rewards.")

	_write_text(save_state.save_path(), "{invalid_json")
	save_state.load_game()
	if reward_state.gold_balance() != 0 or reward_state.hero_xp_balance() != 0:
		failures.append("Corrupt save recovery should reset currencies to defaults.")
	if profile_state.hero_level(TEST_HERO_ID) != 1:
		failures.append("Corrupt save recovery should reset hero levels to defaults.")
	if formation_state.assigned_count() != 0:
		failures.append("Corrupt save recovery should clear the formation.")
	if campaign_state.is_stage_unlocked("chapter_01_stage_02"):
		failures.append("Corrupt save recovery should reset campaign unlocks.")
	if inventory_state.equipped_item_id(TEST_HERO_ID, "weapon").is_empty() == false:
		failures.append("Corrupt save recovery should clear equipped items.")
	if save_state.save_exists() == false:
		failures.append("Corrupt save recovery should rewrite a valid default save.")

	debug_tools.grant_debug_resources()
	if reward_state.gold_balance() < 5000 or reward_state.hero_xp_balance() < 5000:
		failures.append("Debug resource grant should add currencies.")

	debug_tools.unlock_all_stages()
	if campaign_state.unlocked_stage_ids().size() != game_data.stage_count():
		failures.append("Debug unlock should unlock all authored stages.")

	debug_tools.instant_level_up_all_heroes()
	if profile_state.hero_level(TEST_HERO_ID) != profile_state.hero_level_cap(TEST_HERO_ID):
		failures.append("Debug instant level-up should cap owned heroes.")

	save_state.reset_save()

	if failures.is_empty():
		print("Phase 10 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)

	quit(1)


func _read_text(path: String) -> String:
	if FileAccess.file_exists(path) == false:
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(text)
