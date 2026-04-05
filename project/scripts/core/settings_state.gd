extends Node

signal settings_changed

const DEFAULTS := {
	"transitions_enabled": true,
	"button_feedback_enabled": true,
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 0.85,
}

var _settings: Dictionary = DEFAULTS.duplicate(true)


func _ready() -> void:
	_apply_runtime_settings()


func transitions_enabled() -> bool:
	return bool(_settings.get("transitions_enabled", true))


func button_feedback_enabled() -> bool:
	return bool(_settings.get("button_feedback_enabled", true))


func master_volume() -> float:
	return float(_settings.get("master_volume", 1.0))


func music_volume() -> float:
	return float(_settings.get("music_volume", 0.8))


func sfx_volume() -> float:
	return float(_settings.get("sfx_volume", 0.85))


func set_transitions_enabled(value: bool) -> void:
	_set_setting("transitions_enabled", value)


func set_button_feedback_enabled(value: bool) -> void:
	_set_setting("button_feedback_enabled", value)


func set_master_volume(value: float) -> void:
	_set_setting("master_volume", clampf(value, 0.0, 1.0))


func set_music_volume(value: float) -> void:
	_set_setting("music_volume", clampf(value, 0.0, 1.0))


func set_sfx_volume(value: float) -> void:
	_set_setting("sfx_volume", clampf(value, 0.0, 1.0))


func summary_lines() -> Array[String]:
	return [
		"Transitions: %s" % ("On" if transitions_enabled() else "Off"),
		"Button feedback: %s" % ("On" if button_feedback_enabled() else "Off"),
		"Master volume: %d%%" % int(round(master_volume() * 100.0)),
		"Music volume: %d%%" % int(round(music_volume() * 100.0)),
		"SFX volume: %d%%" % int(round(sfx_volume() * 100.0)),
	]


func serialize_state() -> Dictionary:
	return _settings.duplicate(true)


func apply_state(data: Dictionary) -> void:
	_settings = DEFAULTS.duplicate(true)
	for key in DEFAULTS.keys():
		if data.has(key):
			_settings[key] = data.get(key)
	_sanitize_settings()
	_apply_runtime_settings()
	settings_changed.emit()


func reset_persistent_state() -> void:
	_settings = DEFAULTS.duplicate(true)
	_apply_runtime_settings()
	settings_changed.emit()


func _set_setting(key: String, value) -> void:
	if _settings.get(key) == value:
		return
	_settings[key] = value
	_sanitize_settings()
	_apply_runtime_settings()
	settings_changed.emit()


func _sanitize_settings() -> void:
	_settings["transitions_enabled"] = bool(_settings.get("transitions_enabled", true))
	_settings["button_feedback_enabled"] = bool(_settings.get("button_feedback_enabled", true))
	_settings["master_volume"] = clampf(float(_settings.get("master_volume", 1.0)), 0.0, 1.0)
	_settings["music_volume"] = clampf(float(_settings.get("music_volume", 0.8)), 0.0, 1.0)
	_settings["sfx_volume"] = clampf(float(_settings.get("sfx_volume", 0.85)), 0.0, 1.0)


func _apply_runtime_settings() -> void:
	if AudioServer.get_bus_count() > 0:
		AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume(), 0.001)))
