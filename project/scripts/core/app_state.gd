extends Node

const GAME_TITLE := "Shardfall Legends"
const BUILD_PHASE := "Phase 3 - Team Formation System"

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
	var lines := [
		"Title: %s" % GAME_TITLE,
		"Build: %s" % BUILD_PHASE,
		"Current screen: %s" % current_screen,
		"Boot count: %d" % boot_count,
		"Visited screens: %d" % navigation_history.size(),
	]

	if is_instance_valid(GameData):
		lines.append("Hero defs: %d" % GameData.hero_count())
		lines.append("Enemy defs: %d" % GameData.enemy_count())

	if is_instance_valid(ProfileState):
		lines.append("Owned heroes: %d" % ProfileState.owned_hero_count())

	if is_instance_valid(FormationState):
		lines.append("Formation slots: %d/5" % FormationState.assigned_count())
		lines.append("Team power: %d" % FormationState.team_power())

	return lines
