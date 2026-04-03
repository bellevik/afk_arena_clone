extends Control

const SCREEN_LINKS := [
	{"id": "main_menu", "label": "Main Menu"},
	{"id": "heroes", "label": "Heroes"},
	{"id": "formation", "label": "Formation"},
	{"id": "campaign", "label": "Campaign"},
	{"id": "battle", "label": "Battle"},
	{"id": "rewards", "label": "Rewards"},
	{"id": "settings", "label": "Settings"},
]

@onready var backdrop: ColorRect = %Backdrop
@onready var state_label: Label = %StateLabel
@onready var close_button: Button = %CloseButton
@onready var reset_button: Button = %ResetButton
@onready var cycle_button: Button = %CycleButton
@onready var screen_buttons: GridContainer = %ScreenButtons


func _ready() -> void:
	close_button.pressed.connect(_close)
	reset_button.pressed.connect(DebugTools.reset_navigation)
	cycle_button.pressed.connect(DebugTools.cycle_screen)
	backdrop.gui_input.connect(_on_backdrop_gui_input)
	_build_screen_buttons()
	visible = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		_refresh_state()


func _build_screen_buttons() -> void:
	if screen_buttons.get_child_count() > 0:
		return

	for item in SCREEN_LINKS:
		var button := Button.new()
		button.text = String(item["label"])
		button.custom_minimum_size = Vector2(0.0, 88.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_open_screen.bind(String(item["id"])))
		screen_buttons.add_child(button)


func _refresh_state() -> void:
	state_label.text = "\n".join(AppState.summary_lines())


func _open_screen(screen_id: String) -> void:
	DebugTools.open_screen(screen_id)


func _close() -> void:
	DebugTools.set_menu_open(false)


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close()
