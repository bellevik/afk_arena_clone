class_name BattleSimulator
extends RefCounted

const TEAM_PLAYER := "player"
const TEAM_ENEMY := "enemy"
const FRONTLINE_SLOT_IDS := ["front_left", "front_right"]
const SLOT_PRIORITY := {
	"front_left": 0,
	"front_right": 1,
	"back_left": 2,
	"back_center": 3,
	"back_right": 4,
}
const DEFAULT_DURATION_SECONDS := 60.0
const LOG_LIMIT := 120
const ENERGY_MAX := 1000
const PASSIVE_ENERGY_PER_SECOND := 65.0
const ATTACK_ENERGY_GAIN := 140
const HIT_ENERGY_GAIN := 90

var _units: Array[Dictionary] = []
var _elapsed_seconds := 0.0
var _remaining_seconds := 0.0
var _result_state := "ongoing"
var _winner_team := ""
var _result_label := "Battle in progress"
var _combat_log: Array[String] = []
var _skill_cast_count := 0
var _healing_done := 0
var _shielding_done := 0


func setup(player_units: Array[Dictionary], enemy_units: Array[Dictionary], config: Dictionary = {}) -> void:
	reset()

	_remaining_seconds = float(config.get("duration_seconds", DEFAULT_DURATION_SECONDS))

	for entry in player_units:
		_units.append(_build_unit_state(entry))
	for entry in enemy_units:
		_units.append(_build_unit_state(entry))

	_record_log("Deterministic battle started. No RNG is used in this prototype.")
	_record_log("Energy and ultimates are active in Phase 5.")
	_record_log("Player units: %d  |  Enemy units: %d" % [player_units.size(), enemy_units.size()])
	_check_opening_result()


func reset() -> void:
	_units.clear()
	_elapsed_seconds = 0.0
	_remaining_seconds = 0.0
	_result_state = "ongoing"
	_winner_team = ""
	_result_label = "Battle in progress"
	_combat_log.clear()
	_skill_cast_count = 0
	_healing_done = 0
	_shielding_done = 0


func step(delta: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if is_finished():
		return events

	var step_delta := maxf(delta, 0.0)
	_elapsed_seconds += step_delta
	_remaining_seconds = maxf(0.0, _remaining_seconds - step_delta)

	for unit in _units:
		if bool(unit.get("alive", false)) == false:
			continue
		_tick_unit_effects(unit, step_delta)
		unit["energy"] = mini(ENERGY_MAX, int(unit.get("energy", 0)) + int(round(PASSIVE_ENERGY_PER_SECOND * step_delta)))
		unit["cooldown"] = float(unit.get("cooldown", 0.0)) - step_delta

	var ready_indices: Array[int] = []
	for index in _units.size():
		var unit: Dictionary = _units[index]
		if bool(unit.get("alive", false)) == false:
			continue
		if float(unit.get("cooldown", 0.0)) <= 0.0:
			ready_indices.append(index)

	ready_indices.sort_custom(_sort_ready_units)

	for attacker_index in ready_indices:
		if is_finished():
			break
		if bool(_units[attacker_index].get("alive", false)) == false:
			continue

		var attacker: Dictionary = _units[attacker_index]
		if _should_cast_ultimate(attacker):
			_perform_ultimate(attacker_index, events)
			_check_winner(events)
			continue

		var target_index := _select_target_index(attacker_index)
		if target_index == -1:
			_check_winner(events)
			continue

		_perform_attack(attacker_index, target_index, events)
		_check_winner(events)

	if is_finished() == false and _remaining_seconds <= 0.0:
		_result_state = "timeout"
		_winner_team = TEAM_ENEMY
		_result_label = "Time Up"
		events.append({"type": "battle_end", "result": _result_state, "winner_team": _winner_team})
		_record_log("The timer expired. Enemy forces hold the field.")

	return events


func units() -> Array[Dictionary]:
	return _units.duplicate(true)


func combat_log() -> Array[String]:
	return _combat_log.duplicate()


func is_finished() -> bool:
	return _result_state != "ongoing"


func result_state() -> String:
	return _result_state


func winner_team() -> String:
	return _winner_team


func result_label() -> String:
	return _result_label


func elapsed_seconds() -> float:
	return _elapsed_seconds


func remaining_seconds() -> float:
	return _remaining_seconds


func team_alive_count(team: String) -> int:
	var count := 0
	for unit in _units:
		if String(unit.get("team", "")) == team and bool(unit.get("alive", false)):
			count += 1
	return count


func skill_cast_count() -> int:
	return _skill_cast_count


func healing_done() -> int:
	return _healing_done


func shielding_done() -> int:
	return _shielding_done


func debug_signature() -> String:
	var parts: Array[String] = [
		_result_state,
		_winner_team,
		str(_skill_cast_count),
		str(_healing_done),
		str(_shielding_done),
		str(snappedf(_elapsed_seconds, 0.1)),
	]
	for unit in _units:
		parts.append("%s:%d:%d:%d:%d" % [
			String(unit.get("unit_id", "")),
			int(unit.get("hp", 0)),
			int(unit.get("energy", 0)),
			int(unit.get("shield", 0)),
			int(bool(unit.get("alive", false))),
		])
	return "|".join(parts)


func _build_unit_state(entry: Dictionary) -> Dictionary:
	var stats: Dictionary = entry.get("stats", {})
	var slot_id := String(entry.get("slot_id", ""))
	var slot_priority := int(SLOT_PRIORITY.get(slot_id, 99))
	var speed := int(stats.get("speed", 0))
	var initial_energy := clampi(int(entry.get("initial_energy", 0)), 0, ENERGY_MAX)
	return {
		"unit_id": "%s_%s_%s" % [String(entry.get("team", "")), slot_id, String(entry.get("source_id", ""))],
		"team": String(entry.get("team", "")),
		"source_type": String(entry.get("source_type", "")),
		"source_id": String(entry.get("source_id", "")),
		"slot_id": slot_id,
		"slot_priority": slot_priority,
		"line": "front" if FRONTLINE_SLOT_IDS.has(slot_id) else "back",
		"display_name": String(entry.get("display_name", "Unknown")),
		"role": String(entry.get("role", "Unknown")),
		"faction": String(entry.get("faction", "Unknown")),
		"portrait_glyph": String(entry.get("portrait_glyph", "?")),
		"accent_color": entry.get("accent_color", Color("607d8b")),
		"level": int(entry.get("level", 1)),
		"power": int(entry.get("power", 0)),
		"ultimate_id": String(entry.get("ultimate_id", "")),
		"ultimate_name": String(entry.get("ultimate_name", "")),
		"ultimate_description": String(entry.get("ultimate_description", "")),
		"skill": entry.get("skill", {}).duplicate(true),
		"max_hp": int(stats.get("hp", 0)),
		"hp": int(stats.get("hp", 0)),
		"attack": int(stats.get("attack", 0)),
		"defense": int(stats.get("defense", 0)),
		"speed": speed,
		"energy_max": ENERGY_MAX,
		"energy": initial_energy,
		"shield": 0,
		"speed_buff_scale": 0.0,
		"speed_buff_remaining": 0.0,
		"defense_break_scale": 0.0,
		"defense_break_remaining": 0.0,
		"cooldown": _attack_interval_for_speed(speed) * (0.35 + float(slot_priority) * 0.05),
		"alive": true,
		"status_text": "Charged" if initial_energy > 0 else "Holding",
	}


func _attack_interval_for_speed(speed: int) -> float:
	return clampf(2.2 - float(speed) / 100.0, 0.65, 1.9)


func _effective_speed(unit: Dictionary) -> int:
	var buff_scale := 1.0 + float(unit.get("speed_buff_scale", 0.0))
	return int(round(int(unit.get("speed", 0)) * buff_scale))


func _attack_interval_for_unit(unit: Dictionary) -> float:
	return _attack_interval_for_speed(_effective_speed(unit))


func _sort_ready_units(left: int, right: int) -> bool:
	var a: Dictionary = _units[left]
	var b: Dictionary = _units[right]

	var a_speed := _effective_speed(a)
	var b_speed := _effective_speed(b)
	if a_speed != b_speed:
		return a_speed > b_speed

	var a_team_order := 0 if String(a.get("team", "")) == TEAM_PLAYER else 1
	var b_team_order := 0 if String(b.get("team", "")) == TEAM_PLAYER else 1
	if a_team_order != b_team_order:
		return a_team_order < b_team_order

	return int(a.get("slot_priority", 99)) < int(b.get("slot_priority", 99))


func _select_target_index(attacker_index: int) -> int:
	var attacker: Dictionary = _units[attacker_index]
	var target_indices := _enemy_indices_for_unit(attacker)
	if target_indices.is_empty():
		return -1

	var frontline_indices := _filter_frontline(target_indices)
	var candidates := frontline_indices if frontline_indices.is_empty() == false else target_indices
	var best_index := candidates[0]
	for candidate_index in candidates:
		if _is_better_target(attacker, candidate_index, best_index):
			best_index = candidate_index

	return best_index


func _is_better_target(attacker: Dictionary, candidate_index: int, current_index: int) -> bool:
	var attacker_role := String(attacker.get("role", ""))
	var candidate: Dictionary = _units[candidate_index]
	var current: Dictionary = _units[current_index]

	if attacker_role == "Tank" or attacker_role == "Warrior":
		var candidate_priority := int(candidate.get("slot_priority", 99))
		var current_priority := int(current.get("slot_priority", 99))
		if candidate_priority != current_priority:
			return candidate_priority < current_priority
		return int(candidate.get("hp", 0)) < int(current.get("hp", 0))

	var candidate_hp := int(candidate.get("hp", 0))
	var current_hp := int(current.get("hp", 0))
	if candidate_hp != current_hp:
		return candidate_hp < current_hp

	return int(candidate.get("slot_priority", 99)) < int(current.get("slot_priority", 99))


func _perform_attack(attacker_index: int, target_index: int, events: Array[Dictionary]) -> void:
	var attacker := _units[attacker_index]
	var target := _units[target_index]
	var damage := _calculate_damage(attacker, target, 1.0)
	var applied_damage := _apply_damage(target, damage)

	attacker["energy"] = mini(ENERGY_MAX, int(attacker.get("energy", 0)) + ATTACK_ENERGY_GAIN)
	target["energy"] = mini(ENERGY_MAX, int(target.get("energy", 0)) + HIT_ENERGY_GAIN)
	_set_next_action_cooldown(attacker, 1.0)
	attacker["status_text"] = "Hit %d" % applied_damage
	if bool(target.get("alive", false)):
		target["status_text"] = "Took %d" % applied_damage

	events.append({
		"type": "attack",
		"attacker_id": String(attacker.get("unit_id", "")),
		"target_id": String(target.get("unit_id", "")),
		"damage": applied_damage,
	})
	_record_log(
		"%.1fs  %s hit %s for %d" % [
			snappedf(_elapsed_seconds, 0.1),
			String(attacker.get("display_name", "Attacker")),
			String(target.get("display_name", "Target")),
			applied_damage,
		]
	)


func _should_cast_ultimate(unit: Dictionary) -> bool:
	return (
		bool(unit.get("alive", false))
		and Dictionary(unit.get("skill", {})).is_empty() == false
		and int(unit.get("energy", 0)) >= int(unit.get("energy_max", ENERGY_MAX))
	)


func _perform_ultimate(attacker_index: int, events: Array[Dictionary]) -> void:
	var attacker := _units[attacker_index]
	var skill: Dictionary = attacker.get("skill", {})
	if skill.is_empty():
		return

	attacker["energy"] = 0
	attacker["status_text"] = "Cast %s" % String(attacker.get("ultimate_name", "Ultimate"))
	_set_next_action_cooldown(attacker, 0.8)
	_skill_cast_count += 1

	events.append({
		"type": "skill_cast",
		"caster_id": String(attacker.get("unit_id", "")),
		"caster_name": String(attacker.get("display_name", "Caster")),
		"skill_id": String(skill.get("skill_id", "")),
		"skill_name": String(skill.get("display_name", "Ultimate")),
		"color": attacker.get("accent_color", Color("607d8b")),
	})
	_record_log(
		"%.1fs  %s used %s" % [
			snappedf(_elapsed_seconds, 0.1),
			String(attacker.get("display_name", "Caster")),
			String(skill.get("display_name", "Ultimate")),
		]
	)

	match String(skill.get("effect_type", "")):
		"frontline_bash":
			_cast_frontline_bash(attacker_index, skill, events)
		"backline_volley":
			_cast_backline_volley(attacker_index, skill, events)
		"all_enemy_blast":
			_cast_all_enemy_blast(attacker_index, skill, events)
		"sweeping_arc":
			_cast_sweeping_arc(attacker_index, skill, events)
		"war_cry":
			_cast_war_cry(attacker_index, skill, events)
		"single_target_burst":
			_cast_single_target_burst(attacker_index, skill, events)
		"rune_barrage":
			_cast_rune_barrage(attacker_index, skill, events)
		"team_heal_shield":
			_cast_team_heal_shield(attacker_index, skill, events)


func _cast_frontline_bash(attacker_index: int, skill: Dictionary, events: Array[Dictionary]) -> void:
	var attacker := _units[attacker_index]
	var candidates := _enemy_indices_for_unit(attacker)
	candidates = _filter_frontline(candidates) if _filter_frontline(candidates).is_empty() == false else candidates
	candidates = _sort_indices_by_slot(candidates)
	var target_count := maxi(int(skill.get("target_count", 2)), 1)
	for target_index in candidates.slice(0, target_count):
		_skill_damage(attacker_index, target_index, float(skill.get("damage_scale", 1.0)), events, "Bashed")

	var shield_amount := int(round(int(attacker.get("max_hp", 0)) * float(skill.get("shield_scale", 0.0))))
	if shield_amount > 0:
		var gained := _grant_shield(attacker, shield_amount)
		if gained > 0:
			attacker["status_text"] = "Shield +%d" % gained
			_record_log("%s gained a bastion shield of %d." % [String(attacker.get("display_name", "Unit")), gained])


func _cast_backline_volley(attacker_index: int, skill: Dictionary, events: Array[Dictionary]) -> void:
	var attacker := _units[attacker_index]
	var candidates := _enemy_indices_for_unit(attacker)
	var preferred := _filter_backline(candidates)
	var working := preferred if preferred.is_empty() == false else candidates
	var targets := _select_lowest_hp_indices(working, int(skill.get("target_count", 3)))
	for target_index in targets:
		_skill_damage(attacker_index, target_index, float(skill.get("damage_scale", 1.0)), events, "Scorched")


func _cast_all_enemy_blast(attacker_index: int, skill: Dictionary, events: Array[Dictionary]) -> void:
	for target_index in _enemy_indices_for_unit(_units[attacker_index]):
		_skill_damage(attacker_index, target_index, float(skill.get("damage_scale", 1.0)), events, "Comet hit")


func _cast_sweeping_arc(attacker_index: int, skill: Dictionary, events: Array[Dictionary]) -> void:
	var attacker := _units[attacker_index]
	var targets := _sort_indices_by_slot(_enemy_indices_for_unit(attacker))
	var target_count := maxi(int(skill.get("target_count", 3)), 1)
	for target_index in targets.slice(0, target_count):
		_skill_damage(attacker_index, target_index, float(skill.get("damage_scale", 1.0)), events, "Arc cut")


func _cast_war_cry(attacker_index: int, skill: Dictionary, events: Array[Dictionary]) -> void:
	var attacker := _units[attacker_index]
	for ally_index in _ally_indices_for_unit(attacker):
		var ally := _units[ally_index]
		_apply_speed_buff(ally, float(skill.get("speed_buff_scale", 0.0)), float(skill.get("duration_seconds", 0.0)))
		if ally_index == attacker_index:
			ally["status_text"] = "Roaring"
		else:
			ally["status_text"] = "Haste"

	var candidates := _enemy_indices_for_unit(attacker)
	candidates = _filter_frontline(candidates) if _filter_frontline(candidates).is_empty() == false else candidates
	for target_index in candidates:
		_skill_damage(attacker_index, target_index, float(skill.get("damage_scale", 0.5)), events, "Shaken")

	_record_log("%s sped up the allied team." % String(attacker.get("display_name", "Unit")))


func _cast_single_target_burst(attacker_index: int, skill: Dictionary, events: Array[Dictionary]) -> void:
	var target_index := _select_target_index(attacker_index)
	if target_index == -1:
		return
	_skill_damage(attacker_index, target_index, float(skill.get("damage_scale", 2.0)), events, "Ruptured")


func _cast_rune_barrage(attacker_index: int, skill: Dictionary, events: Array[Dictionary]) -> void:
	var attacker := _units[attacker_index]
	var targets := _select_lowest_hp_indices(_enemy_indices_for_unit(attacker), int(skill.get("target_count", 3)))
	for target_index in targets:
		_skill_damage(attacker_index, target_index, float(skill.get("damage_scale", 1.0)), events, "Runeburn")
		var target := _units[target_index]
		_apply_defense_break(target, float(skill.get("defense_break_scale", 0.0)), float(skill.get("duration_seconds", 0.0)))
		target["status_text"] = "Defense down"


func _cast_team_heal_shield(attacker_index: int, skill: Dictionary, events: Array[Dictionary]) -> void:
	var attacker := _units[attacker_index]
	for ally_index in _ally_indices_for_unit(attacker):
		var ally := _units[ally_index]
		var heal_amount := int(round(int(ally.get("max_hp", 0)) * float(skill.get("heal_scale", 0.0))))
		var shield_amount := int(round(int(ally.get("max_hp", 0)) * float(skill.get("shield_scale", 0.0))))
		var healed := _heal_unit(ally, heal_amount)
		var shielded := _grant_shield(ally, shield_amount)
		if healed > 0:
			_healing_done += healed
		if shielded > 0:
			_shielding_done += shielded
		ally["status_text"] = "Recovered"
		events.append({
			"type": "heal",
			"unit_id": String(ally.get("unit_id", "")),
			"amount": healed,
			"shield": shielded,
		})

	_record_log("%s restored and shielded the allied team." % String(attacker.get("display_name", "Unit")))


func _skill_damage(attacker_index: int, target_index: int, scale: float, events: Array[Dictionary], target_status: String) -> void:
	var attacker := _units[attacker_index]
	var target := _units[target_index]
	var damage := _calculate_damage(attacker, target, scale)
	var applied_damage := _apply_damage(target, damage)
	target["energy"] = mini(ENERGY_MAX, int(target.get("energy", 0)) + HIT_ENERGY_GAIN)

	events.append({
		"type": "skill_hit",
		"attacker_id": String(attacker.get("unit_id", "")),
		"target_id": String(target.get("unit_id", "")),
		"damage": applied_damage,
	})
	if bool(target.get("alive", false)):
		target["status_text"] = "%s %d" % [target_status, applied_damage]

	_record_log("%s took %d from %s." % [
		String(target.get("display_name", "Target")),
		applied_damage,
		String(attacker.get("ultimate_name", attacker.get("display_name", "Skill"))),
	])


func _calculate_damage(attacker: Dictionary, defender: Dictionary, scale: float) -> int:
	var attack_value := float(attacker.get("attack", 0)) * maxf(scale, 0.1)
	var defense_multiplier := 1.0 - float(defender.get("defense_break_scale", 0.0))
	var defense_value := float(defender.get("defense", 0)) * clampf(defense_multiplier, 0.2, 1.0)
	var raw_damage := maxf(attack_value * 0.30, attack_value - defense_value * 0.55)
	return maxi(1, int(round(raw_damage)))


func _apply_damage(unit: Dictionary, amount: int) -> int:
	var pending := maxi(amount, 0)
	var shield := int(unit.get("shield", 0))
	if shield > 0 and pending > 0:
		var absorbed := mini(shield, pending)
		shield -= absorbed
		pending -= absorbed
		unit["shield"] = shield

	if pending > 0:
		unit["hp"] = maxi(0, int(unit.get("hp", 0)) - pending)

	if int(unit.get("hp", 0)) <= 0:
		unit["alive"] = false
		unit["shield"] = 0
		unit["status_text"] = "KO"
		_record_log("%s was knocked out." % String(unit.get("display_name", "Unit")))

	return amount


func _heal_unit(unit: Dictionary, amount: int) -> int:
	if bool(unit.get("alive", false)) == false or amount <= 0:
		return 0
	var current_hp := int(unit.get("hp", 0))
	var next_hp := mini(int(unit.get("max_hp", 0)), current_hp + amount)
	unit["hp"] = next_hp
	return next_hp - current_hp


func _grant_shield(unit: Dictionary, amount: int) -> int:
	if bool(unit.get("alive", false)) == false or amount <= 0:
		return 0
	unit["shield"] = int(unit.get("shield", 0)) + amount
	return amount


func _apply_speed_buff(unit: Dictionary, scale: float, duration: float) -> void:
	unit["speed_buff_scale"] = maxf(float(unit.get("speed_buff_scale", 0.0)), scale)
	unit["speed_buff_remaining"] = maxf(float(unit.get("speed_buff_remaining", 0.0)), duration)


func _apply_defense_break(unit: Dictionary, scale: float, duration: float) -> void:
	unit["defense_break_scale"] = maxf(float(unit.get("defense_break_scale", 0.0)), scale)
	unit["defense_break_remaining"] = maxf(float(unit.get("defense_break_remaining", 0.0)), duration)


func _tick_unit_effects(unit: Dictionary, delta: float) -> void:
	if float(unit.get("speed_buff_remaining", 0.0)) > 0.0:
		unit["speed_buff_remaining"] = maxf(0.0, float(unit.get("speed_buff_remaining", 0.0)) - delta)
		if float(unit.get("speed_buff_remaining", 0.0)) <= 0.0:
			unit["speed_buff_scale"] = 0.0

	if float(unit.get("defense_break_remaining", 0.0)) > 0.0:
		unit["defense_break_remaining"] = maxf(0.0, float(unit.get("defense_break_remaining", 0.0)) - delta)
		if float(unit.get("defense_break_remaining", 0.0)) <= 0.0:
			unit["defense_break_scale"] = 0.0


func _set_next_action_cooldown(unit: Dictionary, scale: float) -> void:
	unit["cooldown"] = _attack_interval_for_unit(unit) * scale


func _enemy_indices_for_unit(unit: Dictionary) -> Array[int]:
	var opposing_team := TEAM_ENEMY if String(unit.get("team", "")) == TEAM_PLAYER else TEAM_PLAYER
	return _alive_indices_for_team(opposing_team)


func _ally_indices_for_unit(unit: Dictionary) -> Array[int]:
	return _alive_indices_for_team(String(unit.get("team", "")))


func _alive_indices_for_team(team: String) -> Array[int]:
	var indices: Array[int] = []
	for index in _units.size():
		var unit: Dictionary = _units[index]
		if bool(unit.get("alive", false)) and String(unit.get("team", "")) == team:
			indices.append(index)
	return indices


func _filter_frontline(indices: Array[int]) -> Array[int]:
	var filtered: Array[int] = []
	for index in indices:
		if String(_units[index].get("line", "")) == "front":
			filtered.append(index)
	return filtered


func _filter_backline(indices: Array[int]) -> Array[int]:
	var filtered: Array[int] = []
	for index in indices:
		if String(_units[index].get("line", "")) == "back":
			filtered.append(index)
	return filtered


func _sort_indices_by_slot(indices: Array[int]) -> Array[int]:
	var sorted := indices.duplicate()
	sorted.sort_custom(_sort_indices_by_slot_priority)
	return sorted


func _sort_indices_by_slot_priority(left: int, right: int) -> bool:
	return int(_units[left].get("slot_priority", 99)) < int(_units[right].get("slot_priority", 99))


func _select_lowest_hp_indices(indices: Array[int], count: int) -> Array[int]:
	var sorted := indices.duplicate()
	sorted.sort_custom(_sort_indices_by_hp_then_slot)
	return sorted.slice(0, mini(count, sorted.size()))


func _sort_indices_by_hp_then_slot(left: int, right: int) -> bool:
	var left_hp := int(_units[left].get("hp", 0))
	var right_hp := int(_units[right].get("hp", 0))
	if left_hp != right_hp:
		return left_hp < right_hp
	return int(_units[left].get("slot_priority", 99)) < int(_units[right].get("slot_priority", 99))


func _check_opening_result() -> void:
	if team_alive_count(TEAM_ENEMY) == 0:
		_result_state = "victory"
		_winner_team = TEAM_PLAYER
		_result_label = "Victory"
	elif team_alive_count(TEAM_PLAYER) == 0:
		_result_state = "defeat"
		_winner_team = TEAM_ENEMY
		_result_label = "Defeat"


func _check_winner(events: Array[Dictionary]) -> void:
	if team_alive_count(TEAM_ENEMY) == 0:
		_result_state = "victory"
		_winner_team = TEAM_PLAYER
		_result_label = "Victory"
		events.append({"type": "battle_end", "result": _result_state, "winner_team": _winner_team})
		_record_log("All enemy units are down. Victory.")
	elif team_alive_count(TEAM_PLAYER) == 0:
		_result_state = "defeat"
		_winner_team = TEAM_ENEMY
		_result_label = "Defeat"
		events.append({"type": "battle_end", "result": _result_state, "winner_team": _winner_team})
		_record_log("The allied team collapsed. Defeat.")


func _record_log(line: String) -> void:
	_combat_log.append(line)
	while _combat_log.size() > LOG_LIMIT:
		_combat_log.remove_at(0)
