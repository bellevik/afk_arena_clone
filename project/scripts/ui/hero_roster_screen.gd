extends Control

const HERO_CARD_SCENE := preload("res://project/scenes/heroes/hero_roster_card.tscn")

var _selected_hero_id: String = ""
var _hero_cards: Dictionary = {}

@onready var summary_label: Label = %SummaryLabel
@onready var hero_list: VBoxContainer = %HeroList
@onready var empty_label: Label = %EmptyLabel
@onready var reload_button: Button = %ReloadButton
@onready var portrait_panel: ColorRect = %PortraitPanel
@onready var portrait_glyph: Label = %PortraitGlyph
@onready var hero_name_label: Label = %HeroNameLabel
@onready var hero_meta_label: Label = %HeroMetaLabel
@onready var hero_lore_label: Label = %HeroLoreLabel
@onready var current_stats_label: Label = %CurrentStatsLabel
@onready var growth_stats_label: Label = %GrowthStatsLabel
@onready var ultimate_name_label: Label = %UltimateNameLabel
@onready var ultimate_description_label: Label = %UltimateDescriptionLabel
@onready var source_label: Label = %SourceLabel


func _ready() -> void:
	reload_button.pressed.connect(_on_reload_pressed)
	if ProfileState.roster_changed.is_connected(_on_roster_changed) == false:
		ProfileState.roster_changed.connect(_on_roster_changed)
	_refresh_roster()


func configure(_metadata: Dictionary) -> void:
	pass


func _on_reload_pressed() -> void:
	GameData.reload_content()


func _on_roster_changed() -> void:
	_refresh_roster()


func _refresh_roster() -> void:
	var entries := ProfileState.owned_roster_entries()
	_refresh_summary(entries)
	_rebuild_list(entries)
	_refresh_selection(entries)


func _refresh_summary(entries: Array[Dictionary]) -> void:
	summary_label.text = "Owned heroes: %d  |  Catalog entries: %d  |  Enemy prototypes: %d\nReload data after adding or editing JSON files in project/data/heroes or project/data/enemies." % [
		entries.size(),
		GameData.hero_count(),
		GameData.enemy_count(),
	]


func _rebuild_list(entries: Array[Dictionary]) -> void:
	for child in hero_list.get_children():
		child.queue_free()

	_hero_cards.clear()
	empty_label.visible = entries.is_empty()

	for entry in entries:
		var hero = entry.get("hero")
		if hero.is_empty():
			continue

		var card := HERO_CARD_SCENE.instantiate()
		hero_list.add_child(card)
		card.configure(entry)
		card.hero_selected.connect(_on_hero_selected)
		_hero_cards[String(hero.get("hero_id", ""))] = card


func _refresh_selection(entries: Array[Dictionary]) -> void:
	if entries.is_empty():
		_clear_detail()
		return

	if GameData.get_hero(_selected_hero_id).is_empty() or ProfileState.has_hero(_selected_hero_id) == false:
		_selected_hero_id = ProfileState.first_owned_hero_id()

	_display_selected_hero(_selected_hero_id)


func _on_hero_selected(hero_id: String) -> void:
	_display_selected_hero(hero_id)


func _display_selected_hero(hero_id: String) -> void:
	var hero = GameData.get_hero(hero_id)
	if hero.is_empty():
		_clear_detail()
		return

	_selected_hero_id = hero_id

	for card_id in _hero_cards.keys():
		var card = _hero_cards[card_id]
		card.set_selected(String(card_id) == hero_id)

	var level := ProfileState.hero_level(hero_id)
	var current_stats = GameData.hero_stats_for_level(hero, level)
	var growth_stats: Dictionary = hero.get("growth", {})
	portrait_panel.color = hero.get("accent_color", Color("607d8b"))
	portrait_glyph.text = String(hero.get("portrait_glyph", "?"))
	hero_name_label.text = "%s  Lv.%d" % [String(hero.get("display_name", "Unknown")), level]
	hero_meta_label.text = GameData.hero_metadata_summary(hero)
	hero_lore_label.text = String(hero.get("lore", ""))
	current_stats_label.text = "\n".join(GameData.stats_summary_lines(current_stats))
	growth_stats_label.text = "Per level:\n%s" % "\n".join(GameData.stats_summary_lines(growth_stats))
	ultimate_name_label.text = "%s  [%s]" % [String(hero.get("ultimate_name", "")), String(hero.get("ultimate_id", ""))]
	ultimate_description_label.text = String(hero.get("ultimate_description", ""))
	source_label.text = "Data source: %s" % String(hero.get("source_path", ""))


func _clear_detail() -> void:
	portrait_panel.color = Color("607d8b")
	portrait_glyph.text = "-"
	hero_name_label.text = "No hero selected"
	hero_meta_label.text = ""
	hero_lore_label.text = "No hero data is currently available."
	current_stats_label.text = ""
	growth_stats_label.text = ""
	ultimate_name_label.text = ""
	ultimate_description_label.text = ""
	source_label.text = ""
