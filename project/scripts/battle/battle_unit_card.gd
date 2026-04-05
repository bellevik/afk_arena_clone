extends PanelContainer

@onready var glyph_panel: ColorRect = %GlyphPanel
@onready var glyph_label: Label = %GlyphLabel
@onready var name_label: Label = %NameLabel
@onready var meta_label: Label = %MetaLabel
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var hp_bar: ProgressBar = %HPBar
@onready var hp_label: Label = %HPLabel
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	_apply_bar_style(energy_bar, Color("f0b35a"), Color("29354d"))
	_apply_bar_style(hp_bar, Color("5ecb9a"), Color("29354d"))


func sync(snapshot: Dictionary) -> void:
	glyph_panel.color = snapshot.get("accent_color", Color("607d8b"))
	glyph_label.text = String(snapshot.get("portrait_glyph", "?"))
	name_label.text = _short_name(String(snapshot.get("display_name", "Unknown")))
	meta_label.text = "Lv.%d  %s" % [
		int(snapshot.get("level", 1)),
		String(snapshot.get("role", "Unknown")),
	]
	energy_bar.max_value = float(maxi(int(snapshot.get("energy_max", 1000)), 1))
	energy_bar.value = float(maxi(int(snapshot.get("energy", 0)), 0))
	hp_bar.max_value = float(maxi(int(snapshot.get("max_hp", 1)), 1))
	hp_bar.value = float(maxi(int(snapshot.get("hp", 0)), 0))
	hp_label.text = "%d / %d HP" % [
		int(snapshot.get("hp", 0)),
		int(snapshot.get("max_hp", 0)),
	]
	var status_parts: Array[String] = []
	if int(snapshot.get("shield", 0)) > 0:
		status_parts.append("Shield %d" % int(snapshot.get("shield", 0)))
	if float(snapshot.get("speed_buff_remaining", 0.0)) > 0.0:
		status_parts.append("Haste")
	if float(snapshot.get("defense_break_remaining", 0.0)) > 0.0:
		status_parts.append("Break")
	if bool(snapshot.get("alive", false)) == false:
		status_parts = ["KO"]
	elif String(snapshot.get("status_text", "")).is_empty() == false:
		status_parts.append(String(snapshot.get("status_text", "")))
	status_label.text = " | ".join(status_parts)
	status_label.visible = status_parts.is_empty() == false
	modulate = Color(1, 1, 1, 1) if bool(snapshot.get("alive", false)) else Color(0.55, 0.55, 0.6, 0.9)


func _short_name(name_text: String) -> String:
	var words := name_text.split(" ", false)
	if words.size() >= 2:
		return "%s\n%s" % [words[0], words[1]]
	return name_text


func _apply_bar_style(bar: ProgressBar, fill_color: Color, background_color: Color) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = background_color
	background.corner_radius_top_left = 8
	background.corner_radius_top_right = 8
	background.corner_radius_bottom_left = 8
	background.corner_radius_bottom_right = 8

	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = 8
	fill.corner_radius_top_right = 8
	fill.corner_radius_bottom_left = 8
	fill.corner_radius_bottom_right = 8

	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
