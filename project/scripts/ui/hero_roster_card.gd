extends Button

signal hero_selected(hero_id: String)

var _hero_id: String = ""

@onready var glyph_panel: ColorRect = %GlyphPanel
@onready var glyph_label: Label = %GlyphLabel
@onready var name_label: Label = %NameLabel
@onready var meta_label: Label = %MetaLabel
@onready var stats_label: Label = %StatsLabel


func _ready() -> void:
	toggle_mode = true
	pressed.connect(_on_pressed)


func configure(entry: Dictionary) -> void:
	var hero = entry.get("hero")
	var level := int(entry.get("level", 1))
	if hero.is_empty():
		return

	var base_stats: Dictionary = hero.get("base_stats", {})
	_hero_id = String(hero.get("hero_id", ""))
	glyph_panel.color = hero.get("accent_color", Color("607d8b"))
	glyph_label.text = String(hero.get("portrait_glyph", "?"))
	name_label.text = "%s  Lv.%d" % [String(hero.get("display_name", "Unknown")), level]
	meta_label.text = GameData.hero_metadata_summary(hero)
	stats_label.text = "HP %d  |  ATK %d  |  DEF %d  |  SPD %d" % [
		int(base_stats.get("hp", 0)),
		int(base_stats.get("attack", 0)),
		int(base_stats.get("defense", 0)),
		int(base_stats.get("speed", 0)),
	]


func set_selected(is_selected: bool) -> void:
	button_pressed = is_selected


func _on_pressed() -> void:
	hero_selected.emit(_hero_id)
