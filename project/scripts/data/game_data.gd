extends Node

signal data_reloaded

const HERO_DATA_DIR := "res://project/data/heroes"
const ENEMY_DATA_DIR := "res://project/data/enemies"
const STAGE_DATA_DIR := "res://project/data/stages"
const ITEM_DATA_DIR := "res://project/data/items"
const BATTLE_TEST_DATA_PATH := "res://project/data/balance/battle_test_encounters.json"
const ULTIMATE_SKILL_DATA_PATH := "res://project/data/balance/ultimate_skills.json"
const HERO_PROGRESSION_DATA_PATH := "res://project/data/balance/hero_progression.json"
const FUTURE_FEATURE_DATA_PATH := "res://project/data/balance/future_feature_hooks.json"
const SUMMON_BANNER_DATA_PATH := "res://project/data/balance/summon_banners.json"
const QUEST_BOARD_DATA_PATH := "res://project/data/balance/quest_board.json"
const LIVE_EVENT_DATA_PATH := "res://project/data/balance/live_events.json"
const RARITIES := ["Common", "Rare", "Elite", "Legendary"]
const ROLES := ["Tank", "Warrior", "Ranger", "Mage", "Support"]
const ITEM_SLOTS := ["weapon", "armor", "accessory"]
const FACTIONS := [
	"Solaris",
	"Umbral",
	"Verdant Circle",
	"Tideborn",
	"Ironcrest",
	"Sky Dominion",
	"Ember Court",
]

var _heroes_by_id: Dictionary = {}
var _hero_ids: Array[String] = []
var _enemies_by_id: Dictionary = {}
var _enemy_ids: Array[String] = []
var _items_by_id: Dictionary = {}
var _item_ids: Array[String] = []
var _stages_by_id: Dictionary = {}
var _stage_ids: Array[String] = []
var _battle_encounters_by_id: Dictionary = {}
var _battle_encounter_ids: Array[String] = []
var _default_battle_encounter_id: String = ""
var _skills_by_id: Dictionary = {}
var _skill_ids: Array[String] = []
var _progression_rules: Dictionary = {}
var _future_features_by_id: Dictionary = {}
var _future_feature_ids: Array[String] = []
var _summon_banners_by_id: Dictionary = {}
var _summon_banner_ids: Array[String] = []
var _default_summon_banner_id := ""
var _quests_by_id: Dictionary = {}
var _quest_ids: Array[String] = []
var _live_events_by_id: Dictionary = {}
var _live_event_ids: Array[String] = []
var _default_live_event_id := ""
var _live_event_stages_by_id: Dictionary = {}
var _live_event_stage_ids: Array[String] = []


func _ready() -> void:
	reload_content()


func reload_content() -> void:
	_heroes_by_id.clear()
	_hero_ids.clear()
	_enemies_by_id.clear()
	_enemy_ids.clear()
	_items_by_id.clear()
	_item_ids.clear()
	_stages_by_id.clear()
	_stage_ids.clear()
	_battle_encounters_by_id.clear()
	_battle_encounter_ids.clear()
	_default_battle_encounter_id = ""
	_skills_by_id.clear()
	_skill_ids.clear()
	_progression_rules.clear()
	_future_features_by_id.clear()
	_future_feature_ids.clear()
	_summon_banners_by_id.clear()
	_summon_banner_ids.clear()
	_default_summon_banner_id = ""
	_quests_by_id.clear()
	_quest_ids.clear()
	_live_events_by_id.clear()
	_live_event_ids.clear()
	_default_live_event_id = ""
	_live_event_stages_by_id.clear()
	_live_event_stage_ids.clear()

	_load_hero_definitions()
	_load_enemy_definitions()
	_load_item_definitions()
	_load_stage_definitions()
	_load_battle_encounters()
	_load_skill_definitions()
	_load_progression_rules()
	_load_future_feature_definitions()
	_load_summon_banners()
	_load_quest_definitions()
	_load_live_event_definitions()
	data_reloaded.emit()


func hero_count() -> int:
	return _hero_ids.size()


func enemy_count() -> int:
	return _enemy_ids.size()


func battle_encounter_count() -> int:
	return _battle_encounter_ids.size()


func stage_count() -> int:
	return _stage_ids.size()


func item_count() -> int:
	return _item_ids.size()


func skill_count() -> int:
	return _skill_ids.size()


func future_feature_count() -> int:
	return _future_feature_ids.size()


func summon_banner_count() -> int:
	return _summon_banner_ids.size()


func quest_count() -> int:
	return _quest_ids.size()


func live_event_count() -> int:
	return _live_event_ids.size()


func live_event_stage_count() -> int:
	return _live_event_stage_ids.size()


func hero_ids() -> Array[String]:
	return _hero_ids.duplicate()


func enemy_ids() -> Array[String]:
	return _enemy_ids.duplicate()


func stage_ids() -> Array[String]:
	return _stage_ids.duplicate()


func item_ids() -> Array[String]:
	return _item_ids.duplicate()


func battle_encounter_ids() -> Array[String]:
	return _battle_encounter_ids.duplicate()


func skill_ids() -> Array[String]:
	return _skill_ids.duplicate()


func future_feature_ids() -> Array[String]:
	return _future_feature_ids.duplicate()


func summon_banner_ids() -> Array[String]:
	return _summon_banner_ids.duplicate()


func summon_currency_ids() -> Array[String]:
	var currency_ids: Array[String] = []
	for banner_id in _summon_banner_ids:
		var currency_id := String(get_summon_banner(banner_id).get("currency_id", ""))
		if currency_id.is_empty():
			continue
		if currency_ids.has(currency_id):
			continue
		currency_ids.append(currency_id)
	return currency_ids


func quest_ids() -> Array[String]:
	return _quest_ids.duplicate()


func live_event_ids() -> Array[String]:
	return _live_event_ids.duplicate()


func live_event_stage_ids() -> Array[String]:
	return _live_event_stage_ids.duplicate()


func quest_ids_for_cadence(cadence: String) -> Array[String]:
	var ids: Array[String] = []
	for quest_id in _quest_ids:
		var quest: Dictionary = get_quest(quest_id)
		if String(quest.get("cadence", "milestone")) == cadence:
			ids.append(quest_id)
	return ids


func get_hero(hero_id: String):
	return _heroes_by_id.get(hero_id, {})


func get_enemy(enemy_id: String):
	return _enemies_by_id.get(enemy_id, {})


func get_item(item_id: String):
	return _items_by_id.get(item_id, {})


func get_stage(stage_id: String):
	return _stages_by_id.get(stage_id, {})


func get_battle_encounter(encounter_id: String):
	return _battle_encounters_by_id.get(encounter_id, {})


func get_default_battle_encounter():
	if _default_battle_encounter_id.is_empty():
		return {}
	return get_battle_encounter(_default_battle_encounter_id)


func get_skill(skill_id: String):
	return _skills_by_id.get(skill_id, {})


func get_future_feature(feature_id: String):
	return _future_features_by_id.get(feature_id, {})


func get_summon_banner(banner_id: String):
	return _summon_banners_by_id.get(banner_id, {})


func get_quest(quest_id: String):
	return _quests_by_id.get(quest_id, {})


func get_live_event(event_id: String):
	return _live_events_by_id.get(event_id, {})


func get_live_event_stage(stage_id: String):
	return _live_event_stages_by_id.get(stage_id, {})


func live_event_stage_modifier_summary_lines(stage_id: String) -> Array[String]:
	return event_modifier_summary_lines(get_live_event_stage(stage_id).get("modifiers", []))


func event_modifier_summary_lines(modifiers: Array) -> Array[String]:
	var lines: Array[String] = []
	for entry in modifiers:
		if entry is Dictionary == false:
			continue
		var label := String(entry.get("label", "Modifier"))
		var description := String(entry.get("description", ""))
		if description.is_empty():
			description = _event_modifier_fallback_text(entry)
		lines.append("%s: %s" % [label, description])
	return lines


func default_summon_banner_id() -> String:
	return _default_summon_banner_id


func default_live_event_id() -> String:
	return _default_live_event_id


func next_live_event_stage_id(event_id: String, stage_id: String) -> String:
	var event: Dictionary = get_live_event(event_id)
	var stages: Array = event.get("stages", [])
	for index in stages.size():
		var stage: Dictionary = stages[index]
		if String(stage.get("stage_id", "")) != stage_id:
			continue
		if index >= stages.size() - 1:
			return ""
		return String(stages[index + 1].get("stage_id", ""))
	return ""


func hero_progression_rules() -> Dictionary:
	return _progression_rules.duplicate(true)


func star_rank_cap() -> int:
	return int(_progression_rules.get("star_rank_cap", 10))


func star_stat_bonus_per_rank() -> float:
	return float(_progression_rules.get("star_stat_bonus_per_rank", 0.04))


func max_ascension_tier() -> int:
	var tiers: Array = _progression_rules.get("ascension_tiers", [])
	if tiers.is_empty():
		return 0
	return int(tiers[tiers.size() - 1].get("tier", 0))


func level_up_cost_for_level(level: int) -> Dictionary:
	var costs: Array = _progression_rules.get("level_costs", [])
	for entry in costs:
		if entry is Dictionary == false:
			continue
		if int(entry.get("level", -1)) != level:
			continue
		return {
			"gold": int(entry.get("gold", 0)),
			"hero_xp": int(entry.get("hero_xp", 0)),
		}
	return {}


func ascension_tier_data(tier: int) -> Dictionary:
	var tiers: Array = _progression_rules.get("ascension_tiers", [])
	for entry in tiers:
		if entry is Dictionary == false:
			continue
		if int(entry.get("tier", -1)) != tier:
			continue
		return entry.duplicate(true)
	return {}


func next_ascension_tier_data(tier: int) -> Dictionary:
	return ascension_tier_data(tier + 1)


func level_cap_for_ascension_tier(tier: int) -> int:
	var tier_data: Dictionary = ascension_tier_data(tier)
	if tier_data.is_empty():
		return 1
	return int(tier_data.get("level_cap", 1))


func copies_required_for_ascension_tier(tier: int) -> int:
	var tier_data: Dictionary = ascension_tier_data(tier)
	if tier_data.is_empty():
		return 0
	return maxi(int(tier_data.get("merge_copies_required", 0)), 0)


func star_bonus_gain_for_ascension_tier(tier: int) -> int:
	var tier_data: Dictionary = ascension_tier_data(tier)
	if tier_data.is_empty():
		return 0
	return maxi(int(tier_data.get("star_bonus_gain", 0)), 0)


func next_stage_id(stage_id: String) -> String:
	var index := _stage_ids.find(stage_id)
	if index == -1 or index >= _stage_ids.size() - 1:
		return ""
	return _stage_ids[index + 1]


func get_all_heroes() -> Array:
	var heroes: Array = []
	for hero_id in _hero_ids:
		var hero = get_hero(hero_id)
		if hero.is_empty() == false:
			heroes.append(hero)
	return heroes


func get_all_enemies() -> Array:
	var enemies: Array = []
	for enemy_id in _enemy_ids:
		var enemy = get_enemy(enemy_id)
		if enemy.is_empty() == false:
			enemies.append(enemy)
	return enemies


func get_all_items() -> Array:
	var items: Array = []
	for item_id in _item_ids:
		var item = get_item(item_id)
		if item.is_empty() == false:
			items.append(item)
	return items


func get_all_future_features() -> Array:
	var features: Array = []
	for feature_id in _future_feature_ids:
		var feature = get_future_feature(feature_id)
		if feature.is_empty() == false:
			features.append(feature)
	return features


func get_all_summon_banners() -> Array:
	var banners: Array = []
	for banner_id in _summon_banner_ids:
		var banner = get_summon_banner(banner_id)
		if banner.is_empty() == false:
			banners.append(banner)
	return banners


func get_all_quests() -> Array:
	var quests: Array = []
	for quest_id in _quest_ids:
		var quest = get_quest(quest_id)
		if quest.is_empty() == false:
			quests.append(quest)
	return quests


func get_all_live_events() -> Array:
	var events: Array = []
	for event_id in _live_event_ids:
		var event = get_live_event(event_id)
		if event.is_empty() == false:
			events.append(event)
	return events


func hero_metadata_summary(hero: Dictionary) -> String:
	return "%s  |  %s  |  %s" % [
		String(hero.get("rarity", "Unknown")),
		String(hero.get("role", "Unknown")),
		String(hero.get("faction", "Unknown")),
	]


func hero_stats_for_level(hero: Dictionary, level: int) -> Dictionary:
	return _scaled_stats_for_level(hero.get("base_stats", {}), hero.get("growth", {}), level)


func enemy_stats_for_level(enemy: Dictionary, level: int) -> Dictionary:
	return _scaled_stats_for_level(enemy.get("base_stats", {}), enemy.get("growth", {}), level)


func stats_summary_lines(stats: Dictionary) -> Array[String]:
	return [
		"HP: %d" % int(stats.get("hp", 0)),
		"ATK: %d" % int(stats.get("attack", 0)),
		"DEF: %d" % int(stats.get("defense", 0)),
		"SPD: %d" % int(stats.get("speed", 0)),
	]


func _load_hero_definitions() -> void:
	for file_name in _list_json_files(HERO_DATA_DIR):
		var path := "%s/%s" % [HERO_DATA_DIR, file_name]
		var data := _load_json_dictionary(path)
		if data.is_empty():
			continue

		var definition := _build_hero_definition(data, path)
		if _hero_definition_valid(definition) == false:
			push_error("Invalid hero definition at %s" % path)
			continue

		_heroes_by_id[definition["hero_id"]] = definition
		_hero_ids.append(definition["hero_id"])


func _load_enemy_definitions() -> void:
	for file_name in _list_json_files(ENEMY_DATA_DIR):
		var path := "%s/%s" % [ENEMY_DATA_DIR, file_name]
		var data := _load_json_dictionary(path)
		if data.is_empty():
			continue

		var definition := _build_enemy_definition(data, path)
		if _enemy_definition_valid(definition) == false:
			push_error("Invalid enemy definition at %s" % path)
			continue

		_enemies_by_id[definition["enemy_id"]] = definition
		_enemy_ids.append(definition["enemy_id"])


func _load_item_definitions() -> void:
	for file_name in _list_json_files(ITEM_DATA_DIR):
		var path := "%s/%s" % [ITEM_DATA_DIR, file_name]
		var payload := _load_json_dictionary(path)
		if payload.is_empty():
			continue

		var items = payload.get("items", [])
		if items is Array == false:
			push_error("GameData expected an Array of items at %s" % path)
			continue

		for entry in items:
			if entry is Dictionary == false:
				continue

			var definition := _build_item_definition(entry, path)
			if _item_definition_valid(definition) == false:
				push_error("Invalid item definition in %s" % path)
				continue

			_items_by_id[definition["item_id"]] = definition
			_item_ids.append(definition["item_id"])


func _load_stage_definitions() -> void:
	for file_name in _list_json_files(STAGE_DATA_DIR):
		var path := "%s/%s" % [STAGE_DATA_DIR, file_name]
		var payload := _load_json_dictionary(path)
		if payload.is_empty():
			continue

		var stages = payload.get("stages", [])
		if stages is Array == false:
			push_error("GameData expected an Array of stages at %s" % path)
			continue

		for entry in stages:
			if entry is Dictionary == false:
				continue

			var definition := _build_stage_definition(entry, path)
			if _stage_definition_valid(definition) == false:
				push_error("Invalid stage definition in %s" % path)
				continue

			_stages_by_id[definition["stage_id"]] = definition
			_stage_ids.append(definition["stage_id"])


func _load_battle_encounters() -> void:
	var payload := _load_json_dictionary(BATTLE_TEST_DATA_PATH)
	if payload.is_empty():
		return

	var encounters = payload.get("encounters", [])
	if encounters is Array == false:
		push_error("GameData expected an Array of encounters at %s" % BATTLE_TEST_DATA_PATH)
		return

	for entry in encounters:
		if entry is Dictionary == false:
			continue

		var definition := _build_battle_encounter_definition(entry, BATTLE_TEST_DATA_PATH)
		if _battle_encounter_valid(definition) == false:
			push_error("Invalid battle encounter definition in %s" % BATTLE_TEST_DATA_PATH)
			continue

		_battle_encounters_by_id[definition["encounter_id"]] = definition
		_battle_encounter_ids.append(definition["encounter_id"])

	_default_battle_encounter_id = String(payload.get("default_encounter_id", ""))
	if _default_battle_encounter_id.is_empty() or _battle_encounters_by_id.has(_default_battle_encounter_id) == false:
		_default_battle_encounter_id = "" if _battle_encounter_ids.is_empty() else _battle_encounter_ids[0]


func _load_skill_definitions() -> void:
	var payload := _load_json_dictionary(ULTIMATE_SKILL_DATA_PATH)
	if payload.is_empty():
		return

	var skills = payload.get("skills", [])
	if skills is Array == false:
		push_error("GameData expected an Array of skills at %s" % ULTIMATE_SKILL_DATA_PATH)
		return

	for entry in skills:
		if entry is Dictionary == false:
			continue

		var definition := _build_skill_definition(entry, ULTIMATE_SKILL_DATA_PATH)
		if _skill_definition_valid(definition) == false:
			push_error("Invalid skill definition in %s" % ULTIMATE_SKILL_DATA_PATH)
			continue

		_skills_by_id[definition["skill_id"]] = definition
		_skill_ids.append(definition["skill_id"])


func _load_progression_rules() -> void:
	var payload := _load_json_dictionary(HERO_PROGRESSION_DATA_PATH)
	if payload.is_empty():
		return

	var level_costs: Array = []
	for entry in payload.get("level_costs", []):
		if entry is Dictionary == false:
			continue
		level_costs.append({
			"level": int(entry.get("level", 1)),
			"gold": int(entry.get("gold", 0)),
			"hero_xp": int(entry.get("hero_xp", 0)),
		})

	var ascension_tiers: Array = []
	for entry in payload.get("ascension_tiers", []):
		if entry is Dictionary == false:
			continue
		ascension_tiers.append({
			"tier": int(entry.get("tier", 0)),
			"label": String(entry.get("label", "Base")),
			"level_cap": int(entry.get("level_cap", 1)),
			"merge_copies_required": maxi(int(entry.get("merge_copies_required", 0)), 0),
			"star_bonus_gain": maxi(int(entry.get("star_bonus_gain", 0)), 0),
			"next_requirement": String(entry.get("next_requirement", "")),
		})

	_progression_rules = {
		"star_rank_cap": int(payload.get("star_rank_cap", 10)),
		"star_stat_bonus_per_rank": float(payload.get("star_stat_bonus_per_rank", 0.04)),
		"level_costs": level_costs,
		"ascension_tiers": ascension_tiers,
	}


func _load_future_feature_definitions() -> void:
	var payload := _load_json_dictionary(FUTURE_FEATURE_DATA_PATH)
	if payload.is_empty():
		return

	var features = payload.get("features", [])
	if features is Array == false:
		push_error("GameData expected an Array of future features at %s" % FUTURE_FEATURE_DATA_PATH)
		return

	for entry in features:
		if entry is Dictionary == false:
			continue

		var definition := _build_future_feature_definition(entry, FUTURE_FEATURE_DATA_PATH)
		if _future_feature_valid(definition) == false:
			push_error("Invalid future feature definition in %s" % FUTURE_FEATURE_DATA_PATH)
			continue

		_future_features_by_id[definition["feature_id"]] = definition
		_future_feature_ids.append(definition["feature_id"])


func _load_summon_banners() -> void:
	var payload := _load_json_dictionary(SUMMON_BANNER_DATA_PATH)
	if payload.is_empty():
		return

	var banners = payload.get("banners", [])
	if banners is Array == false:
		push_error("GameData expected an Array of summon banners at %s" % SUMMON_BANNER_DATA_PATH)
		return

	for entry in banners:
		if entry is Dictionary == false:
			continue

		var definition := _build_summon_banner_definition(entry, SUMMON_BANNER_DATA_PATH)
		if _summon_banner_valid(definition) == false:
			push_error("Invalid summon banner definition in %s" % SUMMON_BANNER_DATA_PATH)
			continue

		_summon_banners_by_id[definition["banner_id"]] = definition
		_summon_banner_ids.append(definition["banner_id"])

	_default_summon_banner_id = String(payload.get("default_banner_id", ""))
	if _summon_banners_by_id.has(_default_summon_banner_id) == false:
		_default_summon_banner_id = "" if _summon_banner_ids.is_empty() else _summon_banner_ids[0]


func _load_quest_definitions() -> void:
	var payload := _load_json_dictionary(QUEST_BOARD_DATA_PATH)
	if payload.is_empty():
		return

	var quests = payload.get("quests", [])
	if quests is Array == false:
		push_error("GameData expected an Array of quests at %s" % QUEST_BOARD_DATA_PATH)
		return

	for entry in quests:
		if entry is Dictionary == false:
			continue

		var definition := _build_quest_definition(entry, QUEST_BOARD_DATA_PATH)
		if _quest_valid(definition) == false:
			push_error("Invalid quest definition in %s" % QUEST_BOARD_DATA_PATH)
			continue

		_quests_by_id[definition["quest_id"]] = definition
		_quest_ids.append(definition["quest_id"])


func _load_live_event_definitions() -> void:
	var payload := _load_json_dictionary(LIVE_EVENT_DATA_PATH)
	if payload.is_empty():
		return

	var events = payload.get("events", [])
	if events is Array == false:
		push_error("GameData expected an Array of live events at %s" % LIVE_EVENT_DATA_PATH)
		return

	for entry in events:
		if entry is Dictionary == false:
			continue

		var definition := _build_live_event_definition(entry, LIVE_EVENT_DATA_PATH)
		if _live_event_valid(definition) == false:
			push_error("Invalid live event definition in %s" % LIVE_EVENT_DATA_PATH)
			continue

		_live_events_by_id[definition["event_id"]] = definition
		_live_event_ids.append(definition["event_id"])
		for stage in definition.get("stages", []):
			_live_event_stages_by_id[String(stage.get("stage_id", ""))] = stage
			_live_event_stage_ids.append(String(stage.get("stage_id", "")))

	_default_live_event_id = String(payload.get("default_event_id", ""))
	if _live_events_by_id.has(_default_live_event_id) == false:
		_default_live_event_id = "" if _live_event_ids.is_empty() else _live_event_ids[0]


func _build_hero_definition(data: Dictionary, source_path: String) -> Dictionary:
	var portrait_data: Dictionary = data.get("portrait", {})
	return {
		"hero_id": String(data.get("id", "")),
		"display_name": String(data.get("name", "")),
		"rarity": String(data.get("rarity", "")),
		"role": String(data.get("role", "")),
		"faction": String(data.get("faction", "")),
		"base_stats": _normalize_stats(data.get("base_stats", {})),
		"growth": _normalize_stats(data.get("growth", {})),
		"ultimate_id": String(data.get("ultimate_id", "")),
		"ultimate_name": String(data.get("ultimate_name", "")),
		"ultimate_description": String(data.get("ultimate_description", "")),
		"portrait_glyph": String(portrait_data.get("glyph", String(data.get("name", "")).left(1))),
		"accent_color": Color(String(portrait_data.get("accent", "#607d8b"))),
		"lore": String(data.get("lore", "")),
		"source_path": source_path,
	}


func _build_enemy_definition(data: Dictionary, source_path: String) -> Dictionary:
	var portrait_data: Dictionary = data.get("portrait", {})
	return {
		"enemy_id": String(data.get("id", "")),
		"display_name": String(data.get("name", "")),
		"role": String(data.get("role", "")),
		"faction": String(data.get("faction", "")),
		"base_stats": _normalize_stats(data.get("base_stats", {})),
		"growth": _normalize_stats(data.get("growth", {})),
		"ultimate_id": String(data.get("ultimate_id", "")),
		"ultimate_name": String(data.get("ultimate_name", "")),
		"ultimate_description": String(data.get("ultimate_description", "")),
		"portrait_glyph": String(portrait_data.get("glyph", String(data.get("name", "")).left(1))),
		"accent_color": Color(String(portrait_data.get("accent", "#546e7a"))),
		"notes": String(data.get("notes", "")),
		"source_path": source_path,
	}


func _build_item_definition(data: Dictionary, source_path: String) -> Dictionary:
	return {
		"item_id": String(data.get("id", "")),
		"display_name": String(data.get("name", "")),
		"slot_type": String(data.get("slot_type", "")),
		"rarity": String(data.get("rarity", "")),
		"starting_count": int(data.get("starting_count", 0)),
		"stat_bonuses": _normalize_stats(data.get("stat_bonuses", {})),
		"lore": String(data.get("lore", "")),
		"source_path": source_path,
	}


func _build_battle_encounter_definition(data: Dictionary, source_path: String) -> Dictionary:
	var enemy_team: Array[Dictionary] = []
	for raw_entry in data.get("enemy_team", []):
		if raw_entry is Dictionary == false:
			continue
		enemy_team.append({
			"slot_id": String(raw_entry.get("slot_id", "")),
			"enemy_id": String(raw_entry.get("enemy_id", "")),
			"level": int(raw_entry.get("level", 1)),
		})

	return {
		"encounter_id": String(data.get("id", "")),
		"display_name": String(data.get("name", "")),
		"description": String(data.get("description", "")),
		"duration_seconds": float(data.get("duration_seconds", 60.0)),
		"enemy_team": enemy_team,
		"source_path": source_path,
	}


func _build_stage_definition(data: Dictionary, source_path: String) -> Dictionary:
	var enemy_team: Array[Dictionary] = []
	for raw_entry in data.get("enemy_team", []):
		if raw_entry is Dictionary == false:
			continue
		enemy_team.append({
			"slot_id": String(raw_entry.get("slot_id", "")),
			"enemy_id": String(raw_entry.get("enemy_id", "")),
			"level": int(raw_entry.get("level", 1)),
		})

	return {
		"stage_id": String(data.get("id", "")),
		"display_name": String(data.get("name", "")),
		"chapter": int(data.get("chapter", 1)),
		"stage_index": int(data.get("index", 1)),
		"recommended_power": int(data.get("recommended_power", 0)),
		"duration_seconds": float(data.get("duration_seconds", 60.0)),
		"description": String(data.get("description", "")),
		"enemy_team": enemy_team,
		"battle_rewards": {
			"gold": int(data.get("battle_rewards", {}).get("gold", 0)),
			"hero_xp": int(data.get("battle_rewards", {}).get("hero_xp", 0)),
		},
		"afk_hourly": {
			"gold": int(data.get("afk_hourly", {}).get("gold", 0)),
			"hero_xp": int(data.get("afk_hourly", {}).get("hero_xp", 0)),
		},
		"source_path": source_path,
	}


func _build_skill_definition(data: Dictionary, source_path: String) -> Dictionary:
	return {
		"skill_id": String(data.get("id", "")),
		"display_name": String(data.get("name", "")),
		"effect_type": String(data.get("effect_type", "")),
		"damage_scale": float(data.get("damage_scale", 0.0)),
		"heal_scale": float(data.get("heal_scale", 0.0)),
		"shield_scale": float(data.get("shield_scale", 0.0)),
		"speed_buff_scale": float(data.get("speed_buff_scale", 0.0)),
		"defense_break_scale": float(data.get("defense_break_scale", 0.0)),
		"duration_seconds": float(data.get("duration_seconds", 0.0)),
		"target_count": int(data.get("target_count", 1)),
		"source_path": source_path,
	}


func _build_future_feature_definition(data: Dictionary, source_path: String) -> Dictionary:
	var dependencies: Array[String] = []
	for dependency in data.get("depends_on", []):
		dependencies.append(String(dependency))

	return {
		"feature_id": String(data.get("id", "")),
		"display_name": String(data.get("name", "")),
		"status_label": String(data.get("status", "Planned")),
		"primary_surface": String(data.get("primary_surface", "")),
		"planned_route": String(data.get("planned_route", "")),
		"save_domain": String(data.get("save_domain", "")),
		"depends_on": dependencies,
		"notes": String(data.get("notes", "")),
		"source_path": source_path,
	}


func _build_summon_banner_definition(data: Dictionary, source_path: String) -> Dictionary:
	var featured_hero_ids: Array[String] = []
	for hero_id in data.get("featured_hero_ids", []):
		featured_hero_ids.append(String(hero_id))

	return {
		"banner_id": String(data.get("id", "")),
		"display_name": String(data.get("name", "")),
		"description": String(data.get("description", "")),
		"currency_id": String(data.get("currency_id", "")),
		"currency_name": String(data.get("currency_name", "Summon Token")),
		"cost_currency": int(data.get("cost_currency", 0)),
		"cost_currency_ten_pull": int(data.get("cost_currency_ten_pull", 0)),
		"exchange_shards_single": int(data.get("exchange_shards_single", 0)),
		"exchange_shards_ten_pull": int(data.get("exchange_shards_ten_pull", 0)),
		"pity_threshold": int(data.get("pity_threshold", 10)),
		"rarity_weights": {
			"Legendary": int(data.get("rarity_weights", {}).get("Legendary", 0)),
			"Elite": int(data.get("rarity_weights", {}).get("Elite", 0)),
			"Rare": int(data.get("rarity_weights", {}).get("Rare", 0)),
		},
		"featured_hero_ids": featured_hero_ids,
		"featured_bonus_weight": int(data.get("featured_bonus_weight", 1)),
		"fallback_rewards": {
			"gold": int(data.get("fallback_rewards", {}).get("gold", 0)),
			"hero_xp": int(data.get("fallback_rewards", {}).get("hero_xp", 0)),
		},
		"source_path": source_path,
	}


func _build_quest_definition(data: Dictionary, source_path: String) -> Dictionary:
	var rewards: Dictionary = {}
	for reward_id in data.get("rewards", {}).keys():
		rewards[String(reward_id)] = int(data.get("rewards", {}).get(reward_id, 0))
	return {
		"quest_id": String(data.get("id", "")),
		"display_name": String(data.get("name", "")),
		"description": String(data.get("description", "")),
		"cadence": String(data.get("cadence", "milestone")),
		"event_type": String(data.get("event_type", "")),
		"target_count": int(data.get("target_count", 1)),
		"rewards": rewards,
		"source_path": source_path,
	}


func _build_live_event_definition(data: Dictionary, source_path: String) -> Dictionary:
	var point_sources: Array[Dictionary] = []
	for entry in data.get("point_sources", []):
		if entry is Dictionary == false:
			continue
		point_sources.append({
			"event_type": String(entry.get("event_type", "")),
			"label": String(entry.get("label", "")),
			"points": maxi(int(entry.get("points", 0)), 0),
		})

	var milestones: Array[Dictionary] = []
	for entry in data.get("milestones", []):
		if entry is Dictionary == false:
			continue
		var rewards: Dictionary = {}
		for reward_id in entry.get("rewards", {}).keys():
			rewards[String(reward_id)] = int(entry.get("rewards", {}).get(reward_id, 0))
		milestones.append({
			"milestone_id": String(entry.get("id", "")),
			"display_name": String(entry.get("name", "")),
			"target_points": maxi(int(entry.get("target_points", 0)), 0),
			"rewards": rewards,
		})

	var stages: Array[Dictionary] = []
	for entry in data.get("stages", []):
		if entry is Dictionary == false:
			continue
		stages.append(_build_live_event_stage_definition(entry, String(data.get("id", "")), source_path))

	return {
		"event_id": String(data.get("id", "")),
		"display_name": String(data.get("name", "")),
		"description": String(data.get("description", "")),
		"status_label": String(data.get("status", "Live")),
		"start_unix": int(data.get("start_unix", 0)),
		"end_unix": int(data.get("end_unix", 0)),
		"linked_banner_id": String(data.get("linked_banner_id", "")),
		"point_sources": point_sources,
		"stages": stages,
		"milestones": milestones,
		"source_path": source_path,
	}


func _build_live_event_stage_definition(data: Dictionary, event_id: String, source_path: String) -> Dictionary:
	var enemy_team: Array[Dictionary] = []
	for raw_entry in data.get("enemy_team", []):
		if raw_entry is Dictionary == false:
			continue
		enemy_team.append({
			"slot_id": String(raw_entry.get("slot_id", "")),
			"enemy_id": String(raw_entry.get("enemy_id", "")),
			"level": int(raw_entry.get("level", 1)),
		})

	var rewards: Dictionary = {}
	for reward_id in data.get("battle_rewards", {}).keys():
		rewards[String(reward_id)] = int(data.get("battle_rewards", {}).get(reward_id, 0))

	var modifiers: Array[Dictionary] = []
	for raw_modifier in data.get("modifiers", []):
		if raw_modifier is Dictionary == false:
			continue
		modifiers.append({
			"modifier_id": String(raw_modifier.get("id", "")),
			"label": String(raw_modifier.get("label", "Modifier")),
			"description": String(raw_modifier.get("description", "")),
			"effect_type": String(raw_modifier.get("effect_type", "")),
			"target_team": String(raw_modifier.get("target_team", "")),
			"stat": String(raw_modifier.get("stat", "")),
			"multiplier": float(raw_modifier.get("multiplier", 1.0)),
			"amount": int(raw_modifier.get("amount", 0)),
		})

	return {
		"stage_id": String(data.get("id", "")),
		"event_id": event_id,
		"display_name": String(data.get("name", "")),
		"description": String(data.get("description", "")),
		"recommended_power": int(data.get("recommended_power", 0)),
		"duration_seconds": float(data.get("duration_seconds", 60.0)),
		"modifiers": modifiers,
		"enemy_team": enemy_team,
		"battle_rewards": rewards,
		"source_path": source_path,
	}


func _event_modifier_fallback_text(modifier: Dictionary) -> String:
	match String(modifier.get("effect_type", "")):
		"stat_scale":
			var multiplier := float(modifier.get("multiplier", 1.0))
			var percent_delta := int(round((multiplier - 1.0) * 100.0))
			var percent_text := "%+d%%" % percent_delta
			return "%s %s" % [String(modifier.get("target_team", "team")).capitalize(), "%s %s" % [String(modifier.get("stat", "stat")), percent_text]]
		"starting_energy":
			return "%s start with %d bonus energy" % [
				String(modifier.get("target_team", "team")).capitalize(),
				maxi(int(modifier.get("amount", 0)), 0),
			]
	return "Special event modifier"


func _hero_definition_valid(hero: Dictionary) -> bool:
	return (
		String(hero.get("hero_id", "")).is_empty() == false
		and String(hero.get("display_name", "")).is_empty() == false
		and RARITIES.has(String(hero.get("rarity", "")))
		and ROLES.has(String(hero.get("role", "")))
		and FACTIONS.has(String(hero.get("faction", "")))
		and String(hero.get("ultimate_id", "")).is_empty() == false
		and String(hero.get("ultimate_name", "")).is_empty() == false
	)


func _enemy_definition_valid(enemy: Dictionary) -> bool:
	return (
		String(enemy.get("enemy_id", "")).is_empty() == false
		and String(enemy.get("display_name", "")).is_empty() == false
		and ROLES.has(String(enemy.get("role", "")))
		and FACTIONS.has(String(enemy.get("faction", "")))
		and String(enemy.get("ultimate_id", "")).is_empty() == false
		and String(enemy.get("ultimate_name", "")).is_empty() == false
	)


func _item_definition_valid(item: Dictionary) -> bool:
	return (
		String(item.get("item_id", "")).is_empty() == false
		and String(item.get("display_name", "")).is_empty() == false
		and ITEM_SLOTS.has(String(item.get("slot_type", "")))
		and RARITIES.has(String(item.get("rarity", "")))
	)


func _battle_encounter_valid(encounter: Dictionary) -> bool:
	if String(encounter.get("encounter_id", "")).is_empty():
		return false
	if String(encounter.get("display_name", "")).is_empty():
		return false
	if float(encounter.get("duration_seconds", 0.0)) <= 0.0:
		return false

	var enemy_team = encounter.get("enemy_team", [])
	if enemy_team is Array == false or enemy_team.is_empty():
		return false

	for entry in enemy_team:
		if entry is Dictionary == false:
			return false
		if String(entry.get("slot_id", "")).is_empty():
			return false
		if _enemies_by_id.has(String(entry.get("enemy_id", ""))) == false:
			return false

	return true


func _stage_definition_valid(stage: Dictionary) -> bool:
	if String(stage.get("stage_id", "")).is_empty():
		return false
	if String(stage.get("display_name", "")).is_empty():
		return false
	if float(stage.get("duration_seconds", 0.0)) <= 0.0:
		return false
	var enemy_team = stage.get("enemy_team", [])
	if enemy_team is Array == false or enemy_team.is_empty():
		return false

	for entry in enemy_team:
		if entry is Dictionary == false:
			return false
		if String(entry.get("slot_id", "")).is_empty():
			return false
		if _enemies_by_id.has(String(entry.get("enemy_id", ""))) == false:
			return false

	return true


func _skill_definition_valid(skill: Dictionary) -> bool:
	return (
		String(skill.get("skill_id", "")).is_empty() == false
		and String(skill.get("display_name", "")).is_empty() == false
		and String(skill.get("effect_type", "")).is_empty() == false
	)


func _future_feature_valid(feature: Dictionary) -> bool:
	return (
		String(feature.get("feature_id", "")).is_empty() == false
		and String(feature.get("display_name", "")).is_empty() == false
		and String(feature.get("status_label", "")).is_empty() == false
		and String(feature.get("planned_route", "")).is_empty() == false
	)


func _summon_banner_valid(banner: Dictionary) -> bool:
	if String(banner.get("banner_id", "")).is_empty():
		return false
	if String(banner.get("display_name", "")).is_empty():
		return false
	if String(banner.get("currency_id", "")).is_empty():
		return false
	if int(banner.get("cost_currency", 0)) <= 0:
		return false
	if int(banner.get("cost_currency_ten_pull", 0)) <= 0:
		return false
	if int(banner.get("exchange_shards_single", 0)) <= 0:
		return false
	if int(banner.get("exchange_shards_ten_pull", 0)) <= 0:
		return false
	for hero_id in banner.get("featured_hero_ids", []):
		if _heroes_by_id.has(String(hero_id)) == false:
			return false
	return true


func _quest_valid(quest: Dictionary) -> bool:
	return (
		String(quest.get("quest_id", "")).is_empty() == false
		and String(quest.get("display_name", "")).is_empty() == false
		and ["milestone", "daily", "weekly"].has(String(quest.get("cadence", "milestone")))
		and String(quest.get("event_type", "")).is_empty() == false
		and int(quest.get("target_count", 0)) > 0
	)


func _live_event_valid(event: Dictionary) -> bool:
	if String(event.get("event_id", "")).is_empty():
		return false
	if String(event.get("display_name", "")).is_empty():
		return false
	var linked_banner_id := String(event.get("linked_banner_id", ""))
	if linked_banner_id.is_empty() == false and _summon_banners_by_id.has(linked_banner_id) == false:
		return false
	var point_sources = event.get("point_sources", [])
	if point_sources is Array == false or point_sources.is_empty():
		return false
	for source in point_sources:
		if source is Dictionary == false:
			return false
		if String(source.get("event_type", "")).is_empty():
			return false
		if maxi(int(source.get("points", 0)), 0) <= 0:
			return false
	var milestones = event.get("milestones", [])
	if milestones is Array == false or milestones.is_empty():
		return false
	for milestone in milestones:
		if milestone is Dictionary == false:
			return false
		if String(milestone.get("milestone_id", "")).is_empty():
			return false
		if maxi(int(milestone.get("target_points", 0)), 0) <= 0:
			return false
	var stages = event.get("stages", [])
	if stages is Array == false or stages.is_empty():
		return false
	for stage in stages:
		if stage is Dictionary == false:
			return false
		if String(stage.get("stage_id", "")).is_empty():
			return false
		if String(stage.get("display_name", "")).is_empty():
			return false
		if float(stage.get("duration_seconds", 0.0)) <= 0.0:
			return false
		var enemy_team = stage.get("enemy_team", [])
		if enemy_team is Array == false or enemy_team.is_empty():
			return false
		for entry in enemy_team:
			if entry is Dictionary == false:
				return false
			if String(entry.get("slot_id", "")).is_empty():
				return false
			if _enemies_by_id.has(String(entry.get("enemy_id", ""))) == false:
				return false
	return true


func _normalize_stats(raw_stats: Dictionary) -> Dictionary:
	return {
		"hp": int(raw_stats.get("hp", 0)),
		"attack": int(raw_stats.get("attack", 0)),
		"defense": int(raw_stats.get("defense", 0)),
		"speed": int(raw_stats.get("speed", 0)),
	}


func _scaled_stats_for_level(base_stats: Dictionary, growth: Dictionary, level: int) -> Dictionary:
	var level_offset := maxi(level - 1, 0)
	return {
		"hp": int(base_stats.get("hp", 0)) + int(growth.get("hp", 0)) * level_offset,
		"attack": int(base_stats.get("attack", 0)) + int(growth.get("attack", 0)) * level_offset,
		"defense": int(base_stats.get("defense", 0)) + int(growth.get("defense", 0)) * level_offset,
		"speed": int(base_stats.get("speed", 0)) + int(growth.get("speed", 0)) * level_offset,
	}


func _list_json_files(directory_path: String) -> Array[String]:
	var file_names: Array[String] = []
	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_error("GameData could not open data directory: %s" % directory_path)
		return file_names

	directory.list_dir_begin()
	while true:
		var entry_name := directory.get_next()
		if entry_name.is_empty():
			break
		if directory.current_is_dir():
			continue
		if entry_name.ends_with(".json"):
			file_names.append(entry_name)
	directory.list_dir_end()
	file_names.sort()
	return file_names


func _load_json_dictionary(file_path: String) -> Dictionary:
	if FileAccess.file_exists(file_path) == false:
		push_error("GameData could not find file: %s" % file_path)
		return {}

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("GameData could not open file: %s" % file_path)
		return {}

	var parser := JSON.new()
	var error_code := parser.parse(file.get_as_text())
	if error_code != OK:
		push_error("GameData failed parsing %s: %s" % [file_path, parser.get_error_message()])
		return {}

	var data = parser.data
	if data is Dictionary:
		return data

	push_error("GameData expected a Dictionary at %s" % file_path)
	return {}
