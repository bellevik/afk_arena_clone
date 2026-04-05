extends Node

const GAME_TITLE := "Shardfall Legends"
const BUILD_PHASE := "Phase 22 - Event Combat Modifiers"

var current_screen: String = "main_menu"
var navigation_history: Array[String] = []
var boot_count: int = 0


func register_boot() -> void:
	boot_count += 1


func set_current_screen(screen_id: String) -> void:
	if current_screen != screen_id:
		navigation_history.append(screen_id)
	current_screen = screen_id


func reset_session() -> void:
	current_screen = "main_menu"
	navigation_history.clear()


func summary_lines() -> Array[String]:
	var lines: Array[String] = [
		"Title: %s" % GAME_TITLE,
		"Build: %s" % BUILD_PHASE,
		"Current screen: %s" % current_screen,
		"Boot count: %d" % boot_count,
		"Visited screens: %d" % navigation_history.size(),
	]

	if is_instance_valid(GameData):
		lines.append("Hero defs: %d" % GameData.hero_count())
		lines.append("Enemy defs: %d" % GameData.enemy_count())
		lines.append("Stage defs: %d" % GameData.stage_count())
		lines.append("Item defs: %d" % GameData.item_count())
		lines.append("Future hooks: %d" % GameData.future_feature_count())
		lines.append("Summon banners: %d" % GameData.summon_banner_count())
		lines.append("Quest defs: %d" % GameData.quest_count())
		lines.append("Live events: %d" % GameData.live_event_count())
		lines.append("Event stages: %d" % GameData.live_event_stage_count())

	if is_instance_valid(ProfileState):
		lines.append("Owned heroes: %d" % ProfileState.owned_hero_count())

	if is_instance_valid(FormationState):
		lines.append("Formation slots: %d/5" % FormationState.assigned_count())
		lines.append("Team power: %d" % FormationState.team_power())

	if is_instance_valid(CampaignState):
		lines.append("Unlocked stages: %d" % CampaignState.unlocked_stage_ids().size())
		lines.append("Cleared stages: %d" % CampaignState.cleared_stage_ids().size())

	if is_instance_valid(InventoryState):
		lines.append("Inventory items: %d" % InventoryState.total_inventory_count())
		lines.append("Equipped items: %d" % InventoryState.total_equipped_count())

	if is_instance_valid(SummonState):
		lines.append("Total pulls: %d" % SummonState.total_pulls())

	if is_instance_valid(QuestState):
		lines.append("Claimed quests: %d" % QuestState.claimed_quest_ids().size())

	if is_instance_valid(EventState):
		lines.append("Active events: %d" % EventState.active_event_count())
		lines.append("Event points: %d" % EventState.selected_event_points())

	if is_instance_valid(SaveState):
		lines.append("Save exists: %s" % ("Yes" if SaveState.save_exists() else "No"))
		lines.append("Save status: %s" % SaveState.last_status())

	return lines
