extends ScrollContainer

var _reset_armed := false

@onready var settings_summary_label: Label = %SettingsSummaryLabel
@onready var save_status_label: Label = %SaveStatusLabel
@onready var master_value_label: Label = %MasterValueLabel
@onready var music_value_label: Label = %MusicValueLabel
@onready var sfx_value_label: Label = %SfxValueLabel
@onready var transitions_toggle: CheckButton = %TransitionsToggle
@onready var feedback_toggle: CheckButton = %FeedbackToggle
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var save_button: Button = %SaveButton
@onready var reload_button: Button = %ReloadButton
@onready var reset_button: Button = %ResetButton
@onready var debug_button: Button = %DebugButton


func _ready() -> void:
	transitions_toggle.toggled.connect(_on_transitions_toggled)
	feedback_toggle.toggled.connect(_on_feedback_toggled)
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	save_button.pressed.connect(_on_save_pressed)
	reload_button.pressed.connect(_on_reload_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	debug_button.pressed.connect(DebugTools.toggle_menu)
	if SettingsState.settings_changed.is_connected(_refresh_screen) == false:
		SettingsState.settings_changed.connect(_refresh_screen)
	if SaveState.save_state_changed.is_connected(_refresh_screen) == false:
		SaveState.save_state_changed.connect(_refresh_screen)
	_refresh_screen()


func configure(_metadata: Dictionary) -> void:
	pass


func _refresh_screen() -> void:
	settings_summary_label.text = "%s\nSave path: %s\nBuild: %s" % [
		"\n".join(SettingsState.summary_lines()),
		SaveState.save_path(),
		AppState.BUILD_PHASE,
	]
	save_status_label.text = "Save status: %s" % SaveState.last_status()

	transitions_toggle.set_pressed_no_signal(SettingsState.transitions_enabled())
	feedback_toggle.set_pressed_no_signal(SettingsState.button_feedback_enabled())
	master_slider.set_value_no_signal(SettingsState.master_volume())
	music_slider.set_value_no_signal(SettingsState.music_volume())
	sfx_slider.set_value_no_signal(SettingsState.sfx_volume())

	master_value_label.text = "%d%%" % int(round(SettingsState.master_volume() * 100.0))
	music_value_label.text = "%d%%" % int(round(SettingsState.music_volume() * 100.0))
	sfx_value_label.text = "%d%%" % int(round(SettingsState.sfx_volume() * 100.0))
	reset_button.text = "Reset Save" if _reset_armed == false else "Confirm Reset Save"


func _on_transitions_toggled(value: bool) -> void:
	SettingsState.set_transitions_enabled(value)


func _on_feedback_toggled(value: bool) -> void:
	SettingsState.set_button_feedback_enabled(value)


func _on_master_changed(value: float) -> void:
	SettingsState.set_master_volume(value)
	master_value_label.text = "%d%%" % int(round(value * 100.0))


func _on_music_changed(value: float) -> void:
	SettingsState.set_music_volume(value)
	music_value_label.text = "%d%%" % int(round(value * 100.0))


func _on_sfx_changed(value: float) -> void:
	SettingsState.set_sfx_volume(value)
	sfx_value_label.text = "%d%%" % int(round(value * 100.0))


func _on_save_pressed() -> void:
	_reset_armed = false
	SaveState.save_game()
	_refresh_screen()


func _on_reload_pressed() -> void:
	_reset_armed = false
	SaveState.load_game()
	_refresh_screen()


func _on_reset_pressed() -> void:
	if _reset_armed == false:
		_reset_armed = true
		_refresh_screen()
		return

	_reset_armed = false
	SaveState.reset_save()
	DebugTools.reset_navigation()

