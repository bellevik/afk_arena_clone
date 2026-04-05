extends Node

signal inventory_changed

const EQUIPMENT_SLOTS := ["weapon", "armor", "accessory"]

var _inventory_counts: Dictionary = {}
var _equipped_by_hero: Dictionary = {}


func _ready() -> void:
	if GameData.data_reloaded.is_connected(_on_game_data_reloaded) == false:
		GameData.data_reloaded.connect(_on_game_data_reloaded)
	if ProfileState.roster_changed.is_connected(_on_roster_changed) == false:
		ProfileState.roster_changed.connect(_on_roster_changed)
	_sync_inventory_to_catalog()
	_sync_owned_heroes()


func equipment_slots() -> Array[String]:
	var slots: Array[String] = []
	for slot_id in EQUIPMENT_SLOTS:
		slots.append(String(slot_id))
	return slots


func inventory_count(item_id: String) -> int:
	return int(_inventory_counts.get(item_id, 0))


func inventory_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for item_id in GameData.item_ids():
		var item: Dictionary = GameData.get_item(item_id)
		if item.is_empty():
			continue

		entries.append({
			"item": item,
			"count": inventory_count(item_id),
		})
	return entries


func total_inventory_count() -> int:
	var total := 0
	for item_id in _inventory_counts.keys():
		total += int(_inventory_counts.get(item_id, 0))
	return total


func total_equipped_count() -> int:
	var total := 0
	for hero_id in _equipped_by_hero.keys():
		var slots: Dictionary = _equipped_by_hero.get(hero_id, {})
		for slot_type in EQUIPMENT_SLOTS:
			if String(slots.get(slot_type, "")).is_empty() == false:
				total += 1
	return total


func hero_equipment(hero_id: String) -> Dictionary:
	_ensure_hero_equipment_entry(hero_id)
	return _equipped_by_hero.get(hero_id, {}).duplicate(true)


func equipped_item_id(hero_id: String, slot_type: String) -> String:
	return String(hero_equipment(hero_id).get(slot_type, ""))


func equipped_item(hero_id: String, slot_type: String) -> Dictionary:
	var item_id := equipped_item_id(hero_id, slot_type)
	if item_id.is_empty():
		return {}
	return GameData.get_item(item_id)


func equipment_bonus_stats(hero_id: String) -> Dictionary:
	var totals := {"hp": 0, "attack": 0, "defense": 0, "speed": 0}
	for slot_type in EQUIPMENT_SLOTS:
		var item: Dictionary = equipped_item(hero_id, slot_type)
		if item.is_empty():
			continue
		var bonuses: Dictionary = item.get("stat_bonuses", {})
		totals["hp"] += int(bonuses.get("hp", 0))
		totals["attack"] += int(bonuses.get("attack", 0))
		totals["defense"] += int(bonuses.get("defense", 0))
		totals["speed"] += int(bonuses.get("speed", 0))
	return totals


func equip(hero_id: String, item_id: String) -> Dictionary:
	if ProfileState.has_hero(hero_id) == false:
		return {"ok": false, "reason": "missing_hero"}
	if inventory_count(item_id) <= 0:
		return {"ok": false, "reason": "missing_item"}

	var item: Dictionary = GameData.get_item(item_id)
	if item.is_empty():
		return {"ok": false, "reason": "unknown_item"}

	var slot_type := String(item.get("slot_type", ""))
	if EQUIPMENT_SLOTS.has(slot_type) == false:
		return {"ok": false, "reason": "invalid_slot"}

	_ensure_hero_equipment_entry(hero_id)

	var previous_item_id := String(_equipped_by_hero[hero_id].get(slot_type, ""))
	if previous_item_id == item_id:
		return {"ok": false, "reason": "already_equipped"}

	if previous_item_id.is_empty() == false:
		_inventory_counts[previous_item_id] = inventory_count(previous_item_id) + 1

	_inventory_counts[item_id] = inventory_count(item_id) - 1
	_equipped_by_hero[hero_id][slot_type] = item_id
	inventory_changed.emit()
	return {
		"ok": true,
		"hero_id": hero_id,
		"item_id": item_id,
		"slot_type": slot_type,
		"replaced_item_id": previous_item_id,
	}


func unequip(hero_id: String, slot_type: String) -> Dictionary:
	if ProfileState.has_hero(hero_id) == false:
		return {"ok": false, "reason": "missing_hero"}
	if EQUIPMENT_SLOTS.has(slot_type) == false:
		return {"ok": false, "reason": "invalid_slot"}

	var item_id := equipped_item_id(hero_id, slot_type)
	if item_id.is_empty():
		return {"ok": false, "reason": "slot_empty"}

	_inventory_counts[item_id] = inventory_count(item_id) + 1
	_equipped_by_hero[hero_id][slot_type] = ""
	inventory_changed.emit()
	return {
		"ok": true,
		"hero_id": hero_id,
		"slot_type": slot_type,
		"item_id": item_id,
	}


func reset_inventory_for_testing() -> void:
	_inventory_counts.clear()
	_equipped_by_hero.clear()
	_sync_inventory_to_catalog()
	_sync_owned_heroes()
	inventory_changed.emit()


func serialize_state() -> Dictionary:
	return {
		"inventory_counts": _inventory_counts.duplicate(true),
		"equipped_by_hero": _equipped_by_hero.duplicate(true),
	}


func apply_state(data: Dictionary) -> void:
	_sync_inventory_to_catalog()
	_sync_owned_heroes()

	var incoming_counts: Dictionary = data.get("inventory_counts", {})
	for item_id in GameData.item_ids():
		_inventory_counts[item_id] = maxi(int(incoming_counts.get(item_id, _inventory_counts.get(item_id, 0))), 0)

	var incoming_equipped: Dictionary = data.get("equipped_by_hero", {})
	for hero_id in ProfileState.owned_hero_ids():
		_ensure_hero_equipment_entry(hero_id)
		var hero_equipped: Dictionary = incoming_equipped.get(hero_id, {})
		for slot_type in EQUIPMENT_SLOTS:
			var item_id := String(hero_equipped.get(slot_type, ""))
			if item_id.is_empty() or GameData.get_item(item_id).is_empty():
				_equipped_by_hero[hero_id][slot_type] = ""
				continue
			_equipped_by_hero[hero_id][slot_type] = item_id
	inventory_changed.emit()


func reset_persistent_state() -> void:
	reset_inventory_for_testing()


func _on_game_data_reloaded() -> void:
	_sync_inventory_to_catalog()
	inventory_changed.emit()


func _on_roster_changed() -> void:
	_sync_owned_heroes()
	inventory_changed.emit()


func _sync_inventory_to_catalog() -> void:
	var next_counts: Dictionary = {}
	for item_id in GameData.item_ids():
		var item: Dictionary = GameData.get_item(item_id)
		var previous_count := inventory_count(item_id)
		if _inventory_counts.has(item_id):
			next_counts[item_id] = previous_count
		else:
			next_counts[item_id] = int(item.get("starting_count", 0))
	_inventory_counts = next_counts


func _sync_owned_heroes() -> void:
	var next_equipment: Dictionary = {}
	for hero_id in ProfileState.owned_hero_ids():
		var previous: Dictionary = _equipped_by_hero.get(hero_id, {})
		next_equipment[hero_id] = {}
		for slot_type in EQUIPMENT_SLOTS:
			var item_id := String(previous.get(slot_type, ""))
			if item_id.is_empty() == false and GameData.get_item(item_id).is_empty():
				item_id = ""
			next_equipment[hero_id][slot_type] = item_id
	_equipped_by_hero = next_equipment


func _ensure_hero_equipment_entry(hero_id: String) -> void:
	if _equipped_by_hero.has(hero_id):
		return
	_equipped_by_hero[hero_id] = {}
	for slot_type in EQUIPMENT_SLOTS:
		_equipped_by_hero[hero_id][slot_type] = ""
