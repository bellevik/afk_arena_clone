extends Node

signal data_reloaded

const HERO_DATA_DIR := "res://project/data/heroes"
const ENEMY_DATA_DIR := "res://project/data/enemies"
const BATTLE_TEST_DATA_PATH := "res://project/data/balance/battle_test_encounters.json"
const RARITIES := ["Common", "Rare", "Elite", "Legendary"]
const ROLES := ["Tank", "Warrior", "Ranger", "Mage", "Support"]
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
var _battle_encounters_by_id: Dictionary = {}
var _battle_encounter_ids: Array[String] = []
var _default_battle_encounter_id: String = ""


func _ready() -> void:
	reload_content()


func reload_content() -> void:
	_heroes_by_id.clear()
	_hero_ids.clear()
	_enemies_by_id.clear()
	_enemy_ids.clear()
	_battle_encounters_by_id.clear()
	_battle_encounter_ids.clear()
	_default_battle_encounter_id = ""

	_load_hero_definitions()
	_load_enemy_definitions()
	_load_battle_encounters()
	data_reloaded.emit()


func hero_count() -> int:
	return _hero_ids.size()


func enemy_count() -> int:
	return _enemy_ids.size()


func battle_encounter_count() -> int:
	return _battle_encounter_ids.size()


func hero_ids() -> Array[String]:
	return _hero_ids.duplicate()


func enemy_ids() -> Array[String]:
	return _enemy_ids.duplicate()


func battle_encounter_ids() -> Array[String]:
	return _battle_encounter_ids.duplicate()


func get_hero(hero_id: String):
	return _heroes_by_id.get(hero_id, {})


func get_enemy(enemy_id: String):
	return _enemies_by_id.get(enemy_id, {})


func get_battle_encounter(encounter_id: String):
	return _battle_encounters_by_id.get(encounter_id, {})


func get_default_battle_encounter():
	if _default_battle_encounter_id.is_empty():
		return {}
	return get_battle_encounter(_default_battle_encounter_id)


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
		"portrait_glyph": String(portrait_data.get("glyph", String(data.get("name", "")).left(1))),
		"accent_color": Color(String(portrait_data.get("accent", "#546e7a"))),
		"notes": String(data.get("notes", "")),
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
