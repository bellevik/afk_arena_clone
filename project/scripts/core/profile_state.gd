extends Node

signal roster_changed
signal hero_leveled(hero_id: String, new_level: int)
signal hero_ascended(hero_id: String, new_tier: int, new_star_rank: int)

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
			"ascension_tier": int(previous_entry.get("ascension_tier", 0)),
			"star_rank": int(previous_entry.get("star_rank", 0)),
			"merge_copies": int(previous_entry.get("merge_copies", 0)),
		}

	_owned_heroes = next_owned_heroes
	roster_changed.emit()


func has_hero(hero_id: String) -> bool:
	return _owned_heroes.has(hero_id)


func hero_level(hero_id: String) -> int:
	return int(_owned_heroes.get(hero_id, {}).get("level", 1))


func hero_entry(hero_id: String) -> Dictionary:
	return _owned_heroes.get(hero_id, {}).duplicate(true)


func hero_ascension_tier(hero_id: String) -> int:
	return int(_owned_heroes.get(hero_id, {}).get("ascension_tier", 0))


func hero_star_rank(hero_id: String) -> int:
	return int(_owned_heroes.get(hero_id, {}).get("star_rank", 0))


func hero_merge_copies(hero_id: String) -> int:
	return int(_owned_heroes.get(hero_id, {}).get("merge_copies", 0))


func hero_level_cap(hero_id: String) -> int:
	return GameData.level_cap_for_ascension_tier(hero_ascension_tier(hero_id))


func copies_required_for_next_ascension(hero_id: String) -> int:
	return GameData.copies_required_for_ascension_tier(hero_ascension_tier(hero_id))


func can_ascend(hero_id: String) -> bool:
	if has_hero(hero_id) == false:
		return false
	var current_tier := hero_ascension_tier(hero_id)
	if current_tier >= GameData.max_ascension_tier():
		return false
	if hero_level(hero_id) < hero_level_cap(hero_id):
		return false
	return hero_merge_copies(hero_id) >= copies_required_for_next_ascension(hero_id)


func hero_stats(hero_id: String) -> Dictionary:
	var hero: Dictionary = GameData.get_hero(hero_id)
	if hero.is_empty():
		return {}
	var base_stats: Dictionary = GameData.hero_stats_for_level(hero, hero_level(hero_id))
	var equipment_bonus: Dictionary = {}
	if is_instance_valid(InventoryState):
		equipment_bonus = InventoryState.equipment_bonus_stats(hero_id)
	var combined_stats := {
		"hp": int(base_stats.get("hp", 0)) + int(equipment_bonus.get("hp", 0)),
		"attack": int(base_stats.get("attack", 0)) + int(equipment_bonus.get("attack", 0)),
		"defense": int(base_stats.get("defense", 0)) + int(equipment_bonus.get("defense", 0)),
		"speed": int(base_stats.get("speed", 0)) + int(equipment_bonus.get("speed", 0)),
	}
	var star_bonus_multiplier := 1.0 + float(hero_star_rank(hero_id)) * GameData.star_stat_bonus_per_rank()
	return {
		"hp": int(round(float(combined_stats.get("hp", 0)) * star_bonus_multiplier)),
		"attack": int(round(float(combined_stats.get("attack", 0)) * star_bonus_multiplier)),
		"defense": int(round(float(combined_stats.get("defense", 0)) * star_bonus_multiplier)),
		"speed": int(round(float(combined_stats.get("speed", 0)) * star_bonus_multiplier)),
	}


func level_up_cost(hero_id: String) -> Dictionary:
	if has_hero(hero_id) == false:
		return {}
	if hero_level(hero_id) >= hero_level_cap(hero_id):
		return {}
	return GameData.level_up_cost_for_level(hero_level(hero_id))


func can_level_up(hero_id: String) -> bool:
	var cost: Dictionary = level_up_cost(hero_id)
	return cost.is_empty() == false and RewardState.has_resources(cost)


func level_up_hero(hero_id: String) -> Dictionary:
	if has_hero(hero_id) == false:
		return {
			"ok": false,
			"reason": "missing_hero",
		}

	var current_level := hero_level(hero_id)
	var level_cap := hero_level_cap(hero_id)
	if current_level >= level_cap:
		return {
			"ok": false,
			"reason": "level_cap_reached",
			"level": current_level,
			"level_cap": level_cap,
		}

	var cost: Dictionary = level_up_cost(hero_id)
	if RewardState.spend_resources(cost) == false:
		return {
			"ok": false,
			"reason": "insufficient_resources",
			"cost": cost.duplicate(true),
			"level": current_level,
			"level_cap": level_cap,
		}

	_owned_heroes[hero_id]["level"] = current_level + 1
	roster_changed.emit()
	hero_leveled.emit(hero_id, current_level + 1)
	return {
		"ok": true,
		"reason": "leveled_up",
		"hero_id": hero_id,
		"new_level": current_level + 1,
		"cost": cost.duplicate(true),
		"level_cap": level_cap,
	}


func ascend_hero(hero_id: String) -> Dictionary:
	if has_hero(hero_id) == false:
		return {
			"ok": false,
			"reason": "missing_hero",
		}

	var current_tier := hero_ascension_tier(hero_id)
	if current_tier >= GameData.max_ascension_tier():
		return {
			"ok": false,
			"reason": "max_ascension_reached",
		}

	var level_cap := hero_level_cap(hero_id)
	if hero_level(hero_id) < level_cap:
		return {
			"ok": false,
			"reason": "level_cap_not_reached",
			"level": hero_level(hero_id),
			"level_cap": level_cap,
		}

	var copies_required := copies_required_for_next_ascension(hero_id)
	var current_copies := hero_merge_copies(hero_id)
	if current_copies < copies_required:
		return {
			"ok": false,
			"reason": "insufficient_copies",
			"copies_required": copies_required,
			"copies_owned": current_copies,
		}

	var star_gain := GameData.star_bonus_gain_for_ascension_tier(current_tier)
	var new_tier := current_tier + 1
	var new_star_rank := mini(hero_star_rank(hero_id) + star_gain, GameData.star_rank_cap())
	_owned_heroes[hero_id]["ascension_tier"] = new_tier
	_owned_heroes[hero_id]["star_rank"] = new_star_rank
	_owned_heroes[hero_id]["merge_copies"] = current_copies - copies_required
	roster_changed.emit()
	hero_ascended.emit(hero_id, new_tier, new_star_rank)
	return {
		"ok": true,
		"reason": "ascended",
		"hero_id": hero_id,
		"new_tier": new_tier,
		"new_star_rank": new_star_rank,
		"copies_spent": copies_required,
		"copies_remaining": hero_merge_copies(hero_id),
	}


func reset_progression_for_testing() -> void:
	for hero_id in _owned_heroes.keys():
		_owned_heroes[hero_id]["level"] = 1
		_owned_heroes[hero_id]["ascension_tier"] = 0
		_owned_heroes[hero_id]["star_rank"] = 0
		_owned_heroes[hero_id]["merge_copies"] = 0
	roster_changed.emit()


func set_hero_level(hero_id: String, level: int) -> bool:
	if has_hero(hero_id) == false:
		return false
	var clamped_level := clampi(level, 1, hero_level_cap(hero_id))
	_owned_heroes[hero_id]["level"] = clamped_level
	roster_changed.emit()
	return true


func cap_all_heroes_for_debug() -> void:
	for hero_id in _owned_heroes.keys():
		_owned_heroes[hero_id]["ascension_tier"] = GameData.max_ascension_tier()
		_owned_heroes[hero_id]["star_rank"] = GameData.star_rank_cap()
		_owned_heroes[hero_id]["merge_copies"] = 0
		_owned_heroes[hero_id]["level"] = hero_level_cap(hero_id)
	roster_changed.emit()


func award_summoned_hero(hero_id: String) -> Dictionary:
	if has_hero(hero_id) == false:
		return {
			"ok": false,
			"reason": "missing_hero",
		}

	var current_star_rank := hero_star_rank(hero_id)
	var current_tier := hero_ascension_tier(hero_id)
	var max_tier := GameData.max_ascension_tier()
	if current_tier < max_tier:
		_owned_heroes[hero_id]["merge_copies"] = hero_merge_copies(hero_id) + 1
		roster_changed.emit()
		return {
			"ok": true,
			"hero_id": hero_id,
			"star_rank": current_star_rank,
			"ascension_tier": current_tier,
			"merge_copies": hero_merge_copies(hero_id),
			"granted_copy": true,
			"converted": false,
		}

	var star_cap := GameData.star_rank_cap()
	if current_star_rank < star_cap:
		_owned_heroes[hero_id]["star_rank"] = current_star_rank + 1
		roster_changed.emit()
		return {
			"ok": true,
			"hero_id": hero_id,
			"star_rank": current_star_rank + 1,
			"ascension_tier": current_tier,
			"merge_copies": hero_merge_copies(hero_id),
			"granted_copy": false,
			"converted": false,
		}

	var fallback: Dictionary = SummonState.selected_banner().get("fallback_rewards", {
		"gold": 120,
		"hero_xp": 80,
	})
	RewardState.grant_resources(fallback)
	return {
		"ok": true,
		"hero_id": hero_id,
		"star_rank": current_star_rank,
		"ascension_tier": current_tier,
		"merge_copies": hero_merge_copies(hero_id),
		"granted_copy": false,
		"converted": true,
		"bonus_gold": int(fallback.get("gold", 0)),
		"bonus_hero_xp": int(fallback.get("hero_xp", 0)),
	}


func serialize_state() -> Dictionary:
	return {
		"owned_heroes": _owned_heroes.duplicate(true),
	}


func apply_state(data: Dictionary) -> void:
	var incoming_owned: Dictionary = data.get("owned_heroes", {})
	var next_owned: Dictionary = {}
	for hero_id in GameData.hero_ids():
		var previous_entry: Dictionary = incoming_owned.get(hero_id, {})
		var resolved_tier := clampi(int(previous_entry.get("ascension_tier", 0)), 0, GameData.max_ascension_tier())
		next_owned[hero_id] = {
			"level": clampi(int(previous_entry.get("level", 1)), 1, GameData.level_cap_for_ascension_tier(resolved_tier)),
			"ascension_tier": resolved_tier,
			"star_rank": clampi(int(previous_entry.get("star_rank", 0)), 0, GameData.star_rank_cap()),
			"merge_copies": maxi(int(previous_entry.get("merge_copies", 0)), 0),
		}
	_owned_heroes = next_owned
	roster_changed.emit()


func reset_persistent_state() -> void:
	_owned_heroes.clear()
	_sync_owned_heroes_to_catalog()


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
			"ascension_tier": hero_ascension_tier(hero_id),
			"star_rank": hero_star_rank(hero_id),
			"merge_copies": hero_merge_copies(hero_id),
			"stats": hero_stats(hero_id),
			"equipment": InventoryState.hero_equipment(hero_id) if is_instance_valid(InventoryState) else {},
		})

	return entries
