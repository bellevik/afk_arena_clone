extends Node

const APP_SHELL_SCENE := "res://project/scenes/menus/app_shell.tscn"
const DEFAULT_SCREEN := "main_menu"
const SCREEN_DEFINITIONS := {
	"main_menu": {
		"scene": "res://project/scenes/menus/main_menu_screen.tscn",
		"title": "Shardfall Legends",
		"subtitle": "Phase 21 build with premium summon currencies, live-event milestone rewards, and event-exclusive stage variants.",
	},
	"heroes": {
		"scene": "res://project/scenes/heroes/hero_roster_screen.tscn",
		"title": "Heroes",
		"subtitle": "Inspect heroes, merge duplicate copies into ascension tiers, level them up, and manage equipped gear.",
	},
	"summon": {
		"scene": "res://project/scenes/summon/summon_screen.tscn",
		"title": "Summon",
		"subtitle": "Exchange premium shards into banner-specific tokens, spend those tokens on pulls, and bank duplicates as merge copies.",
	},
	"quests": {
		"scene": "res://project/scenes/quests/quest_board_screen.tscn",
		"title": "Quests",
		"subtitle": "Track milestone, daily, and weekly objectives tied to campaign wins, AFK claims, summons, and hero growth.",
	},
	"events": {
		"scene": "res://project/scenes/events/event_screen.tscn",
		"title": "Events",
		"subtitle": "Progress a live reward track, clear event-exclusive stages, and route into the linked summon banner from one event hub.",
	},
	"formation": {
		"scene": "res://project/scenes/battle/formation_screen.tscn",
		"title": "Formation",
		"subtitle": "Assign the active five-hero team for later battle phases.",
	},
	"campaign": {
		"scene": "res://project/scenes/campaign/campaign_screen.tscn",
		"title": "Campaign",
		"subtitle": "Select unlocked stages, launch battles, and push through the expanded sample campaign.",
	},
	"battle": {
		"scene": "res://project/scenes/battle/battle_screen.tscn",
		"title": "Battle",
		"subtitle": "Run the active formation through a deterministic auto-battle with energy, hero ultimates, and enemy ultimates.",
	},
	"rewards": {
		"scene": "res://project/scenes/rewards/rewards_screen.tscn",
		"title": "Rewards",
		"subtitle": "Collect post-battle rewards, inspect balances, and claim AFK income.",
	},
	"settings": {
		"scene": "res://project/scenes/settings/settings_screen.tscn",
		"title": "Settings",
		"subtitle": "Tune interface feedback, adjust audio preferences, and manage save data without opening the debug overlay.",
	},
}

var _shell: Control


func open_app_shell() -> void:
	get_tree().change_scene_to_file(APP_SHELL_SCENE)


func register_shell(shell: Control) -> void:
	_shell = shell


func shell_available() -> bool:
	return _shell != null


func available_screens() -> Array[String]:
	var screen_ids: Array[String] = []
	for screen_id in SCREEN_DEFINITIONS.keys():
		screen_ids.append(String(screen_id))
	return screen_ids


func get_screen_definition(screen_id: String) -> Dictionary:
	if SCREEN_DEFINITIONS.has(screen_id):
		return SCREEN_DEFINITIONS[screen_id].duplicate(true)
	return SCREEN_DEFINITIONS[DEFAULT_SCREEN].duplicate(true)


func go_to(screen_id: String) -> void:
	if _shell == null:
		push_warning("SceneRouter cannot route before the app shell registers itself.")
		return

	var resolved_id := screen_id if SCREEN_DEFINITIONS.has(screen_id) else DEFAULT_SCREEN
	var definition := get_screen_definition(resolved_id)
	var screen_scene := load(String(definition["scene"])) as PackedScene
	if screen_scene == null:
		push_error("Failed to load screen scene for '%s'." % resolved_id)
		return

	AppState.set_current_screen(resolved_id)
	_shell.show_screen(resolved_id, screen_scene, definition)


func cycle_forward() -> void:
	var screen_ids := available_screens()
	if screen_ids.is_empty():
		return

	var current_index := screen_ids.find(AppState.current_screen)
	var next_index := 0 if current_index == -1 else (current_index + 1) % screen_ids.size()
	go_to(screen_ids[next_index])
