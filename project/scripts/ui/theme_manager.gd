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


func apply_theme(control: Control) -> void:
	control.theme = _theme


func get_theme_resource() -> Theme:
	return _theme


func get_color(name: String) -> Color:
	return COLORS.get(name, Color.WHITE)

