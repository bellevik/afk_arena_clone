extends Control

const HERO_CARD_SCENE := preload("res://project/scenes/heroes/hero_roster_card.tscn")

var _selected_hero_id: String = ""
var _hero_cards: Dictionary = {}
var _progress_message := ""

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
@onready var balance_label: Label = %BalanceLabel
@onready var ascension_label: Label = %AscensionLabel
@onready var upgrade_preview_label: Label = %UpgradePreviewLabel
@onready var upgrade_status_label: Label = %UpgradeStatusLabel
@onready var level_up_button: Button = %LevelUpButton
@onready var ascend_button: Button = %AscendButton
@onready var equipment_bonus_label: Label = %EquipmentBonusLabel
@onready var equipment_slot_list: VBoxContainer = %EquipmentSlotList
@onready var inventory_list: VBoxContainer = %InventoryList
@onready var ultimate_name_label: Label = %UltimateNameLabel
@onready var ultimate_description_label: Label = %UltimateDescriptionLabel
@onready var source_label: Label = %SourceLabel


func _ready() -> void:
	reload_button.pressed.connect(_on_reload_pressed)
	level_up_button.pressed.connect(_on_level_up_pressed)
	ascend_button.pressed.connect(_on_ascend_pressed)
	if ProfileState.roster_changed.is_connected(_on_roster_changed) == false:
		ProfileState.roster_changed.connect(_on_roster_changed)
	if RewardState.rewards_changed.is_connected(_on_rewards_changed) == false:
		RewardState.rewards_changed.connect(_on_rewards_changed)
	if InventoryState.inventory_changed.is_connected(_on_inventory_changed) == false:
		InventoryState.inventory_changed.connect(_on_inventory_changed)
	_refresh_roster()


func configure(_metadata: Dictionary) -> void:
	pass


func _on_reload_pressed() -> void:
	GameData.reload_content()


func _on_roster_changed() -> void:
	_refresh_roster()


func _on_rewards_changed() -> void:
	_refresh_roster()


func _on_inventory_changed() -> void:
	_refresh_roster()


func _refresh_roster() -> void:
	var entries := ProfileState.owned_roster_entries()
	_refresh_summary(entries)
	_rebuild_list(entries)
	_refresh_selection(entries)


func _refresh_summary(entries: Array[Dictionary]) -> void:
	summary_label.text = "Owned heroes: %d  |  Catalog entries: %d  |  Enemy prototypes: %d\nGold: %d  |  Hero XP: %d\nReload data after adding or editing JSON files in project/data/heroes or project/data/enemies." % [
		entries.size(),
		GameData.hero_count(),
		GameData.enemy_count(),
		RewardState.gold_balance(),
		RewardState.hero_xp_balance(),
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
	_progress_message = ""
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
	var ascension_tier := ProfileState.hero_ascension_tier(hero_id)
	var ascension_data: Dictionary = GameData.ascension_tier_data(ascension_tier)
	var next_ascension_data: Dictionary = GameData.next_ascension_tier_data(ascension_tier)
	var level_cap := ProfileState.hero_level_cap(hero_id)
	var merge_copies := ProfileState.hero_merge_copies(hero_id)
	var copies_required := ProfileState.copies_required_for_next_ascension(hero_id)
	var max_ascension_reached := ascension_tier >= GameData.max_ascension_tier()
	var equipment_bonus: Dictionary = InventoryState.equipment_bonus_stats(hero_id)
	var current_stats := ProfileState.hero_stats(hero_id)
	var next_level := mini(level + 1, level_cap)
	var next_level_base_stats := GameData.hero_stats_for_level(hero, next_level)
	var next_level_stats := {
		"hp": int(next_level_base_stats.get("hp", 0)) + int(equipment_bonus.get("hp", 0)),
		"attack": int(next_level_base_stats.get("attack", 0)) + int(equipment_bonus.get("attack", 0)),
		"defense": int(next_level_base_stats.get("defense", 0)) + int(equipment_bonus.get("defense", 0)),
		"speed": int(next_level_base_stats.get("speed", 0)) + int(equipment_bonus.get("speed", 0)),
	}
	var growth_stats: Dictionary = hero.get("growth", {})
	var cost: Dictionary = ProfileState.level_up_cost(hero_id)
	portrait_panel.color = hero.get("accent_color", Color("607d8b"))
	portrait_glyph.text = String(hero.get("portrait_glyph", "?"))
	hero_name_label.text = "%s  Lv.%d  |  %s" % [
		String(hero.get("display_name", "Unknown")),
		level,
		String(ascension_data.get("label", "Base")),
	]
	hero_meta_label.text = "%s  |  Stars %d  |  Copies %d  |  +%d%% star bonus" % [
		GameData.hero_metadata_summary(hero),
		ProfileState.hero_star_rank(hero_id),
		merge_copies,
		int(round(GameData.star_stat_bonus_per_rank() * float(ProfileState.hero_star_rank(hero_id)) * 100.0)),
	]
	hero_lore_label.text = String(hero.get("lore", ""))
	current_stats_label.text = "Current stats:\n%s" % "\n".join(GameData.stats_summary_lines(current_stats))
	growth_stats_label.text = "Per level:\n%s" % "\n".join(GameData.stats_summary_lines(growth_stats))
	balance_label.text = "Available resources:\nGold %d  |  Hero XP %d" % [
		RewardState.gold_balance(),
		RewardState.hero_xp_balance(),
	]
	ascension_label.text = "Ascension: %s  |  Stars: %d  |  Level cap: %d\nMerge copies banked: %d" % [
		String(ascension_data.get("label", "Base")),
		ProfileState.hero_star_rank(hero_id),
		level_cap,
		merge_copies,
	]
	if max_ascension_reached:
		ascension_label.text += "\nMaximum ascension reached. Extra duplicates now become final star growth."
	else:
		ascension_label.text += "\nNext tier: %s  |  Need %d copies at level cap  |  Grants +%d stars" % [
			String(next_ascension_data.get("label", "Future ascension tier")),
			copies_required,
			GameData.star_bonus_gain_for_ascension_tier(ascension_tier),
		]
	equipment_bonus_label.text = "Equipment bonuses:\nHP %+d  |  ATK %+d  |  DEF %+d  |  SPD %+d" % [
		int(equipment_bonus.get("hp", 0)),
		int(equipment_bonus.get("attack", 0)),
		int(equipment_bonus.get("defense", 0)),
		int(equipment_bonus.get("speed", 0)),
	]
	if level < level_cap:
		upgrade_preview_label.text = "Next level preview (Lv.%d):\nHP %+d  |  ATK %+d  |  DEF %+d  |  SPD %+d" % [
			next_level,
			int(next_level_stats.get("hp", 0)) - int(current_stats.get("hp", 0)),
			int(next_level_stats.get("attack", 0)) - int(current_stats.get("attack", 0)),
			int(next_level_stats.get("defense", 0)) - int(current_stats.get("defense", 0)),
			int(next_level_stats.get("speed", 0)) - int(current_stats.get("speed", 0)),
		]
	else:
		upgrade_preview_label.text = "Next level preview:\nThis hero has reached its current level cap."
	if cost.is_empty():
		upgrade_status_label.text = "Upgrade cost:\nLevel cap reached for the current ascension tier."
		level_up_button.disabled = true
		level_up_button.text = "Level Cap Reached"
	else:
		upgrade_status_label.text = "Upgrade cost:\n%d gold  |  %d hero XP" % [
			int(cost.get("gold", 0)),
			int(cost.get("hero_xp", 0)),
		]
		if ProfileState.can_level_up(hero_id) == false and _progress_message.is_empty():
			upgrade_status_label.text += "\nEarn more gold and hero XP from battles or AFK rewards."
		if _progress_message.is_empty() == false:
			upgrade_status_label.text += "\n%s" % _progress_message
		level_up_button.disabled = ProfileState.can_level_up(hero_id) == false
		level_up_button.text = "Level Up To Lv.%d" % next_level
	if _progress_message.is_empty() == false and upgrade_status_label.text.find(_progress_message) == -1:
		upgrade_status_label.text += "\n%s" % _progress_message
	upgrade_status_label.text = "Star bonus: +%d%% to all current stats.\n%s" % [
		int(round(GameData.star_stat_bonus_per_rank() * float(ProfileState.hero_star_rank(hero_id)) * 100.0)),
		upgrade_status_label.text,
	]
	if max_ascension_reached:
		ascend_button.disabled = true
		ascend_button.text = "Max Ascension Reached"
	elif ProfileState.can_ascend(hero_id):
		ascend_button.disabled = false
		ascend_button.text = "Ascend To %s" % String(next_ascension_data.get("label", "Next Tier"))
	else:
		ascend_button.disabled = true
		if level < level_cap:
			ascend_button.text = "Reach Lv.%d To Ascend" % level_cap
		else:
			ascend_button.text = "Need %d Copies To Ascend" % copies_required
	_refresh_equipment_lists(hero_id)
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
	balance_label.text = ""
	ascension_label.text = ""
	upgrade_preview_label.text = ""
	upgrade_status_label.text = ""
	level_up_button.disabled = true
	level_up_button.text = "Level Up"
	ascend_button.disabled = true
	ascend_button.text = "Ascend"
	equipment_bonus_label.text = ""
	_clear_dynamic_list(equipment_slot_list)
	_clear_dynamic_list(inventory_list)
	ultimate_name_label.text = ""
	ultimate_description_label.text = ""
	source_label.text = ""


func _on_level_up_pressed() -> void:
	if _selected_hero_id.is_empty():
		return

	var result: Dictionary = ProfileState.level_up_hero(_selected_hero_id)
	if bool(result.get("ok", false)):
		_progress_message = "Upgraded to Lv.%d." % int(result.get("new_level", 1))
	else:
		var reason := String(result.get("reason", "upgrade_failed"))
		match reason:
			"insufficient_resources":
				_progress_message = "Not enough gold or hero XP for this upgrade."
			"level_cap_reached":
				_progress_message = "Level cap reached. Merge copies can now unlock the next ascension tier."
			_:
				_progress_message = "Upgrade unavailable."

	_refresh_roster()


func _on_ascend_pressed() -> void:
	if _selected_hero_id.is_empty():
		return

	var result: Dictionary = ProfileState.ascend_hero(_selected_hero_id)
	if bool(result.get("ok", false)):
		var tier_label := String(GameData.ascension_tier_data(int(result.get("new_tier", 0))).get("label", "Next Tier"))
		_progress_message = "Ascended to %s. Stars %d, copies left %d." % [
			tier_label,
			int(result.get("new_star_rank", 0)),
			int(result.get("copies_remaining", 0)),
		]
	else:
		var reason := String(result.get("reason", "ascend_failed"))
		match reason:
			"level_cap_not_reached":
				_progress_message = "Reach the current level cap before ascending."
			"insufficient_copies":
				_progress_message = "Not enough duplicate copies for ascension."
			"max_ascension_reached":
				_progress_message = "This hero is already at maximum ascension."
			_:
				_progress_message = "Ascension unavailable."

	_refresh_roster()


func _refresh_equipment_lists(hero_id: String) -> void:
	_clear_dynamic_list(equipment_slot_list)
	_clear_dynamic_list(inventory_list)

	for slot_type in InventoryState.equipment_slots():
		var item: Dictionary = InventoryState.equipped_item(hero_id, slot_type)
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 84.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if item.is_empty():
			button.text = "%s\nEmpty  |  Tap does nothing" % _slot_label(slot_type)
			button.disabled = true
		else:
			var bonuses: Dictionary = item.get("stat_bonuses", {})
			button.text = "%s\n%s  [%s]\nHP %+d  |  ATK %+d  |  DEF %+d  |  SPD %+d\nTap to unequip" % [
				_slot_label(slot_type),
				String(item.get("display_name", "Item")),
				String(item.get("rarity", "Common")),
				int(bonuses.get("hp", 0)),
				int(bonuses.get("attack", 0)),
				int(bonuses.get("defense", 0)),
				int(bonuses.get("speed", 0)),
			]
			button.pressed.connect(_on_unequip_pressed.bind(hero_id, slot_type))
		equipment_slot_list.add_child(button)

	for entry in InventoryState.inventory_entries():
		var item: Dictionary = entry.get("item", {})
		if item.is_empty():
			continue

		var button := Button.new()
		var count := int(entry.get("count", 0))
		var bonuses: Dictionary = item.get("stat_bonuses", {})
		button.custom_minimum_size = Vector2(0.0, 92.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = "%s  x%d\n%s  |  %s\nHP %+d  |  ATK %+d  |  DEF %+d  |  SPD %+d" % [
			String(item.get("display_name", "Item")),
			count,
			String(item.get("rarity", "Common")),
			_slot_label(String(item.get("slot_type", ""))),
			int(bonuses.get("hp", 0)),
			int(bonuses.get("attack", 0)),
			int(bonuses.get("defense", 0)),
			int(bonuses.get("speed", 0)),
		]
		button.disabled = count <= 0
		if count > 0:
			button.pressed.connect(_on_equip_pressed.bind(hero_id, String(item.get("item_id", ""))))
		inventory_list.add_child(button)


func _on_equip_pressed(hero_id: String, item_id: String) -> void:
	var result: Dictionary = InventoryState.equip(hero_id, item_id)
	if bool(result.get("ok", false)):
		var item: Dictionary = GameData.get_item(item_id)
		_progress_message = "Equipped %s." % String(item.get("display_name", "Item"))
	else:
		_progress_message = "Equip failed."
	_refresh_roster()


func _on_unequip_pressed(hero_id: String, slot_type: String) -> void:
	var result: Dictionary = InventoryState.unequip(hero_id, slot_type)
	if bool(result.get("ok", false)):
		_progress_message = "Unequipped %s." % _slot_label(slot_type)
	else:
		_progress_message = "Unequip failed."
	_refresh_roster()


func _slot_label(slot_type: String) -> String:
	match slot_type:
		"weapon":
			return "Weapon"
		"armor":
			return "Armor"
		"accessory":
			return "Accessory"
		_:
			return slot_type.capitalize()


func _clear_dynamic_list(container: VBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()
