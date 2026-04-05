class_name BattleBuilder
extends RefCounted

const ENERGY_CAP := 1000


func default_battle_encounter() -> Dictionary:
	return _game_data().get_default_battle_encounter()


func build_player_team_from_formation(context: Dictionary = {}) -> Array[Dictionary]:
	var units: Array[Dictionary] = []
	var modifiers: Array = context.get("modifiers", [])
	for slot_id in _formation_state().slot_ids():
		var hero: Dictionary = _formation_state().get_assigned_hero(slot_id)
		if hero.is_empty():
			continue

		var hero_id := String(hero.get("hero_id", ""))
		var level: int = int(_profile_state().hero_level(hero_id))
		var stats: Dictionary = _profile_state().hero_stats(hero_id)
		units.append(_apply_event_modifiers(
			_build_unit_entry("player", "hero", slot_id, hero_id, hero, level, stats),
			modifiers
		))

	return units


func build_enemy_team_from_encounter(encounter: Dictionary, context: Dictionary = {}) -> Array[Dictionary]:
	var units: Array[Dictionary] = []
	var modifiers: Array = context.get("modifiers", encounter.get("modifiers", []))
	for entry in encounter.get("enemy_team", []):
		if entry is Dictionary == false:
			continue

		var enemy_id := String(entry.get("enemy_id", ""))
		var enemy: Dictionary = _game_data().get_enemy(enemy_id)
		if enemy.is_empty():
			continue

		var level: int = int(entry.get("level", 1))
		var stats: Dictionary = _game_data().enemy_stats_for_level(enemy, level)
		units.append(
			_apply_event_modifiers(
				_build_unit_entry(
				"enemy",
				"enemy",
				String(entry.get("slot_id", "")),
				enemy_id,
				enemy,
				level,
				stats
				),
				modifiers
			)
		)

	return units


func build_player_summary_line(units: Array[Dictionary]) -> String:
	var total_power := 0
	for unit in units:
		total_power += int(unit.get("power", 0))
	return "Allies deployed: %d  |  Team power: %d" % [units.size(), total_power]


func build_enemy_summary_line(units: Array[Dictionary]) -> String:
	var total_power := 0
	for unit in units:
		total_power += int(unit.get("power", 0))
	return "Enemies deployed: %d  |  Enemy power: %d" % [units.size(), total_power]


func _build_unit_entry(team: String, source_type: String, slot_id: String, source_id: String, source: Dictionary, level: int, stats: Dictionary) -> Dictionary:
	return {
		"team": team,
		"source_type": source_type,
		"slot_id": slot_id,
		"source_id": source_id,
		"display_name": String(source.get("display_name", "Unknown")),
		"role": String(source.get("role", "Unknown")),
		"faction": String(source.get("faction", "Unknown")),
		"portrait_glyph": String(source.get("portrait_glyph", "?")),
		"accent_color": source.get("accent_color", Color("607d8b")),
		"level": level,
		"ultimate_id": String(source.get("ultimate_id", "")),
		"ultimate_name": String(source.get("ultimate_name", "")),
		"ultimate_description": String(source.get("ultimate_description", "")),
		"skill": _game_data().get_skill(String(source.get("ultimate_id", ""))).duplicate(true),
		"stats": stats.duplicate(true),
		"initial_energy": 0,
		"power": _power_from_stats(stats),
	}


func _apply_event_modifiers(entry: Dictionary, modifiers: Array) -> Dictionary:
	var team := String(entry.get("team", ""))
	var next_entry := entry.duplicate(true)
	var stats: Dictionary = next_entry.get("stats", {}).duplicate(true)
	var initial_energy := int(next_entry.get("initial_energy", 0))

	for raw_modifier in modifiers:
		if raw_modifier is Dictionary == false:
			continue
		var modifier: Dictionary = raw_modifier
		if String(modifier.get("target_team", "")) != team:
			continue

		match String(modifier.get("effect_type", "")):
			"stat_scale":
				var stat_id := String(modifier.get("stat", ""))
				if stats.has(stat_id) == false:
					continue
				var current_value := int(stats.get(stat_id, 0))
				var scaled_value := int(round(float(current_value) * maxf(float(modifier.get("multiplier", 1.0)), 0.0)))
				stats[stat_id] = maxi(scaled_value, 1)
			"starting_energy":
				initial_energy = clampi(initial_energy + maxi(int(modifier.get("amount", 0)), 0), 0, ENERGY_CAP)

	next_entry["stats"] = stats
	next_entry["initial_energy"] = initial_energy
	next_entry["power"] = _power_from_stats(stats)
	return next_entry


func _power_from_stats(stats: Dictionary) -> int:
	return (
		int(stats.get("hp", 0))
		+ int(stats.get("attack", 0)) * 8
		+ int(stats.get("defense", 0)) * 6
		+ int(stats.get("speed", 0)) * 4
	)


func _game_data() -> Node:
	return (Engine.get_main_loop() as SceneTree).get_root().get_node("GameData")


func _profile_state() -> Node:
	return (Engine.get_main_loop() as SceneTree).get_root().get_node("ProfileState")


func _formation_state() -> Node:
	return (Engine.get_main_loop() as SceneTree).get_root().get_node("FormationState")
