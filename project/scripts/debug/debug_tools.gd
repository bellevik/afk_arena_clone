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

