extends Node

const APP_SHELL_SCENE := "res://project/scenes/menus/app_shell.tscn"
const DEFAULT_SCREEN := "main_menu"
const SCREEN_DEFINITIONS := {
	"main_menu": {
		"scene": "res://project/scenes/menus/main_menu_screen.tscn",
		"title": "Shardfall Legends",
		"subtitle": "Phase 4 build with authored heroes, formation setup, and deterministic battle simulation.",
	},
	"heroes": {
		"scene": "res://project/scenes/heroes/hero_roster_screen.tscn",
		"title": "Heroes",
		"subtitle": "Browse the current owned roster and inspect authored hero definitions.",
	},
	"formation": {
		"scene": "res://project/scenes/battle/formation_screen.tscn",
		"title": "Formation",
		"subtitle": "Assign the active five-hero team for later battle phases.",
	},
	"campaign": {
		"scene": "res://project/scenes/menus/placeholder_screen.tscn",
		"title": "Campaign",
		"subtitle": "Stage progression arrives after the battle core is in place.",
		"body": "Phase 4 now provides the deterministic battle foundation that campaign stages will call into. Phase 6 will add actual stage definitions, unlock flow, and battle launch from stage data.",
		"status": "Phase 1 placeholder: routed and testable.",
	},
	"battle": {
		"scene": "res://project/scenes/battle/battle_screen.tscn",
		"title": "Battle",
		"subtitle": "Run the active formation through a deterministic real-time auto-battle test encounter.",
	},
	"rewards": {
		"scene": "res://project/scenes/menus/placeholder_screen.tscn",
		"title": "Rewards",
		"subtitle": "Reward collection and AFK loops arrive in later phases.",
		"body": "The shell already includes the rewards destination so currencies, post-battle payouts, and idle collection can be added without changing top-level flow.",
		"status": "Phase 1 placeholder: routed and testable.",
	},
	"settings": {
		"scene": "res://project/scenes/menus/placeholder_screen.tscn",
		"title": "Settings",
		"subtitle": "Player-facing options and platform tuning come later.",
		"body": "This screen will later host audio, graphics, account, and debug-friendly tuning options. For now it validates scene routing and layout behavior.",
		"status": "Phase 1 placeholder: routed and testable.",
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
