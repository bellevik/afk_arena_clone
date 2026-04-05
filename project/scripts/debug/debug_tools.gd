extends Node

signal menu_toggled(is_open: bool)

var _menu_open: bool = false


func toggle_menu() -> void:
	set_menu_open(not _menu_open)


func set_menu_open(value: bool) -> void:
	if _menu_open == value:
		return

	_menu_open = value
	menu_toggled.emit(_menu_open)


func is_menu_open() -> bool:
	return _menu_open


func reset_navigation() -> void:
	AppState.reset_session()
	set_menu_open(false)
	if SceneRouter.shell_available():
		SceneRouter.go_to("main_menu")


func cycle_screen() -> void:
	if SceneRouter.shell_available():
		SceneRouter.cycle_forward()


func open_screen(screen_id: String) -> void:
	if SceneRouter.shell_available():
		SceneRouter.go_to(screen_id)
		set_menu_open(false)


func save_game() -> void:
	SaveState.save_game()


func reload_game() -> void:
	SaveState.load_game()


func reset_save() -> void:
	SaveState.reset_save()
	reset_navigation()


func grant_debug_resources() -> void:
	RewardState.grant_resources({
		"gold": 5000,
		"hero_xp": 5000,
		"premium_shards": 1500,
		"rally_sigil": 10,
		"astral_sigil": 10,
	})


func unlock_all_stages() -> void:
	CampaignState.unlock_all_stages_for_debug()


func instant_level_up_all_heroes() -> void:
	ProfileState.cap_all_heroes_for_debug()


func grant_event_progress() -> void:
	EventState.debug_grant_points_to_active_event()
