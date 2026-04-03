extends Control

const NAV_ITEMS := [
	{"id": "main_menu", "label": "Home"},
	{"id": "heroes", "label": "Heroes"},
	{"id": "campaign", "label": "Campaign"},
	{"id": "battle", "label": "Battle"},
	{"id": "rewards", "label": "Rewards"},
	{"id": "settings", "label": "Settings"},
]

var _current_screen: Control
var _nav_buttons: Dictionary = {}

@onready var screen_title_label: Label = %ScreenTitleLabel
@onready var screen_subtitle_label: Label = %ScreenSubtitleLabel
@onready var screen_host: VBoxContainer = %ScreenHost
@onready var nav_bar: HBoxContainer = %NavBar
@onready var debug_button: Button = %DebugButton
@onready var debug_overlay: Control = %DebugOverlay


func _ready() -> void:
	ThemeManager.apply_theme(self)
	SceneRouter.register_shell(self)
	_build_navigation()
	debug_button.pressed.connect(DebugTools.toggle_menu)
	DebugTools.menu_toggled.connect(_on_debug_menu_toggled)
	_on_debug_menu_toggled(DebugTools.is_menu_open())
	call_deferred("_show_initial_screen")


func show_screen(screen_id: String, scene_resource: PackedScene, metadata: Dictionary) -> void:
	if _current_screen != null:
		_current_screen.queue_free()

	var screen_instance := scene_resource.instantiate() as Control
	if screen_instance == null:
		push_error("AppShell expected a Control-based screen for '%s'." % screen_id)
		return

	screen_instance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen_instance.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if screen_instance.has_method("configure"):
		screen_instance.configure(metadata)

	screen_host.add_child(screen_instance)
	_current_screen = screen_instance
	_update_header(metadata)
	_refresh_navigation(screen_id)


func _show_initial_screen() -> void:
	SceneRouter.go_to(AppState.current_screen)


func _build_navigation() -> void:
	for child in nav_bar.get_children():
		child.queue_free()

	_nav_buttons.clear()

	for item in NAV_ITEMS:
		var button := Button.new()
		var screen_id := String(item["id"])
		button.text = String(item["label"])
		button.custom_minimum_size = Vector2(0.0, 96.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(SceneRouter.go_to.bind(screen_id))
		nav_bar.add_child(button)
		_nav_buttons[screen_id] = button


func _update_header(metadata: Dictionary) -> void:
	screen_title_label.text = String(metadata.get("title", AppState.GAME_TITLE))
	screen_subtitle_label.text = String(metadata.get("subtitle", ""))


func _refresh_navigation(active_screen_id: String) -> void:
	for screen_id in _nav_buttons.keys():
		var button := _nav_buttons[screen_id] as Button
		if button == null:
			continue
		button.disabled = String(screen_id) == active_screen_id


func _on_debug_menu_toggled(is_open: bool) -> void:
	debug_overlay.visible = is_open

