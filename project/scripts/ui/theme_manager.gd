extends Node

const THEME_PATH := "res://project/assets/ui/theme/ui_theme.tres"
const COLORS := {
	"background": Color("101726"),
	"surface": Color("1a2740"),
	"surface_alt": Color("243757"),
	"text": Color("eef4ff"),
	"text_muted": Color("b2bfd7"),
	"accent": Color("f0b35a"),
	"accent_dark": Color("d08b32"),
}

var _theme: Theme = preload(THEME_PATH)
var _button_tweens: Dictionary = {}


func apply_theme(control: Control) -> void:
	control.theme = _theme
	wire_button_feedback(control)


func get_theme_resource() -> Theme:
	return _theme


func get_color(name: String) -> Color:
	return COLORS.get(name, Color.WHITE)


func wire_button_feedback(root: Node) -> void:
	if root == null:
		return

	if root is BaseButton:
		_wire_single_button(root as BaseButton)

	for child in root.get_children():
		wire_button_feedback(child)


func _wire_single_button(button: BaseButton) -> void:
	if button.has_meta("theme_feedback_wired"):
		return

	button.set_meta("theme_feedback_wired", true)
	button.button_down.connect(_animate_button_feedback.bind(button, 0.97, 0.92))
	button.button_up.connect(_animate_button_feedback.bind(button, 1.0, 1.0))
	button.mouse_exited.connect(_animate_button_feedback.bind(button, 1.0, 1.0))
	button.pressed.connect(_animate_button_feedback.bind(button, 1.0, 1.0))


func _animate_button_feedback(button: BaseButton, target_scale: float, target_alpha: float) -> void:
	if is_instance_valid(button) == false:
		return

	if is_instance_valid(SettingsState) and SettingsState.button_feedback_enabled() == false:
		button.scale = Vector2.ONE
		button.modulate.a = 1.0
		return

	button.pivot_offset = button.size * 0.5
	var button_id := button.get_instance_id()
	var active_tween: Tween = _button_tweens.get(button_id)
	if active_tween != null:
		active_tween.kill()

	var tween := button.create_tween()
	_button_tweens[button_id] = tween
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(button, "scale", Vector2.ONE * target_scale, 0.08)
	tween.parallel().tween_property(button, "modulate:a", target_alpha, 0.08)
