extends PanelContainer

@onready var glyph_panel: ColorRect = %GlyphPanel
@onready var glyph_label: Label = %GlyphLabel
@onready var name_label: Label = %NameLabel
@onready var meta_label: Label = %MetaLabel
@onready var hp_bar: ProgressBar = %HPBar
@onready var hp_label: Label = %HPLabel
@onready var status_label: Label = %StatusLabel


func sync(snapshot: Dictionary) -> void:
	glyph_panel.color = snapshot.get("accent_color", Color("607d8b"))
	glyph_label.text = String(snapshot.get("portrait_glyph", "?"))
	name_label.text = _short_name(String(snapshot.get("display_name", "Unknown")))
	meta_label.text = "Lv.%d  %s" % [
		int(snapshot.get("level", 1)),
		String(snapshot.get("role", "Unknown")),
	]
	hp_bar.max_value = float(maxi(int(snapshot.get("max_hp", 1)), 1))
	hp_bar.value = float(maxi(int(snapshot.get("hp", 0)), 0))
	hp_label.text = "%d / %d HP" % [
		int(snapshot.get("hp", 0)),
		int(snapshot.get("max_hp", 0)),
	]
	status_label.text = "KO" if bool(snapshot.get("alive", false)) == false else ""
	modulate = Color(1, 1, 1, 1) if bool(snapshot.get("alive", false)) else Color(0.55, 0.55, 0.6, 0.9)


func _short_name(name_text: String) -> String:
	var words := name_text.split(" ", false)
	if words.size() >= 2:
		return "%s\n%s" % [words[0], words[1]]
	return name_text
