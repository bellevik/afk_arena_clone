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
	var ascension_tier := int(entry.get("ascension_tier", 0))
	var star_rank := int(entry.get("star_rank", 0))
	var merge_copies := int(entry.get("merge_copies", 0))
	var stats: Dictionary = entry.get("stats", hero.get("base_stats", {}))
	if hero.is_empty():
		return

	_hero_id = String(hero.get("hero_id", ""))
	var ascension_label := String(GameData.ascension_tier_data(ascension_tier).get("label", "Base"))
	glyph_panel.color = hero.get("accent_color", Color("607d8b"))
	glyph_label.text = String(hero.get("portrait_glyph", "?"))
	name_label.text = "%s  Lv.%d  |  %s" % [String(hero.get("display_name", "Unknown")), level, ascension_label]
	meta_label.text = "%s  |  Stars %d  |  Copies %d  |  +%d%% star bonus" % [
		GameData.hero_metadata_summary(hero),
		star_rank,
		merge_copies,
		int(round(GameData.star_stat_bonus_per_rank() * float(star_rank) * 100.0)),
	]
	stats_label.text = "HP %d  |  ATK %d  |  DEF %d  |  SPD %d" % [
		int(stats.get("hp", 0)),
		int(stats.get("attack", 0)),
		int(stats.get("defense", 0)),
		int(stats.get("speed", 0)),
	]


func set_selected(is_selected: bool) -> void:
	button_pressed = is_selected


func _on_pressed() -> void:
	hero_selected.emit(_hero_id)
