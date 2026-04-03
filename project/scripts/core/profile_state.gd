extends Node

signal roster_changed

var _owned_heroes: Dictionary = {}


func _ready() -> void:
	if GameData.data_reloaded.is_connected(_on_game_data_reloaded) == false:
		GameData.data_reloaded.connect(_on_game_data_reloaded)
	_sync_owned_heroes_to_catalog()


func _on_game_data_reloaded() -> void:
	_sync_owned_heroes_to_catalog()


func _sync_owned_heroes_to_catalog() -> void:
	var next_owned_heroes: Dictionary = {}
	for hero_id in GameData.hero_ids():
		var previous_entry: Dictionary = _owned_heroes.get(hero_id, {})
		next_owned_heroes[hero_id] = {
			"level": int(previous_entry.get("level", 1)),
		}

	_owned_heroes = next_owned_heroes
	roster_changed.emit()


func has_hero(hero_id: String) -> bool:
	return _owned_heroes.has(hero_id)


func hero_level(hero_id: String) -> int:
	return int(_owned_heroes.get(hero_id, {}).get("level", 1))


func owned_hero_count() -> int:
	return _owned_heroes.size()


func owned_hero_ids() -> Array[String]:
	var hero_ids: Array[String] = []
	for hero_id in GameData.hero_ids():
		if _owned_heroes.has(hero_id):
			hero_ids.append(hero_id)
	return hero_ids


func first_owned_hero_id() -> String:
	var hero_ids := owned_hero_ids()
	return "" if hero_ids.is_empty() else hero_ids[0]


func owned_roster_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for hero_id in owned_hero_ids():
		var hero = GameData.get_hero(hero_id)
		if hero.is_empty():
			continue

		entries.append({
			"hero": hero,
			"level": hero_level(hero_id),
		})

	return entries
