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
const LOG_LIMIT := 80

var _units: Array[Dictionary] = []
var _elapsed_seconds := 0.0
var _remaining_seconds := 0.0
var _result_state := "ongoing"
var _winner_team := ""
var _result_label := "Battle in progress"
var _combat_log: Array[String] = []


func setup(player_units: Array[Dictionary], enemy_units: Array[Dictionary], config: Dictionary = {}) -> void:
	reset()

	_remaining_seconds = float(config.get("duration_seconds", DEFAULT_DURATION_SECONDS))

	for entry in player_units:
		_units.append(_build_unit_state(entry))
	for entry in enemy_units:
		_units.append(_build_unit_state(entry))

	_record_log("Deterministic battle started. No RNG is used in Phase 4.")
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


func debug_signature() -> String:
	var parts: Array[String] = [
		_result_state,
		_winner_team,
		str(snappedf(_elapsed_seconds, 0.1)),
	]
	for unit in _units:
		parts.append("%s:%d:%d" % [
			String(unit.get("unit_id", "")),
			int(unit.get("hp", 0)),
			int(bool(unit.get("alive", false))),
		])
	return "|".join(parts)


func _build_unit_state(entry: Dictionary) -> Dictionary:
	var stats: Dictionary = entry.get("stats", {})
	var slot_id := String(entry.get("slot_id", ""))
	var slot_priority := int(SLOT_PRIORITY.get(slot_id, 99))
	var attack_interval := _attack_interval_for_speed(int(stats.get("speed", 0)))
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
		"max_hp": int(stats.get("hp", 0)),
		"hp": int(stats.get("hp", 0)),
		"attack": int(stats.get("attack", 0)),
		"defense": int(stats.get("defense", 0)),
		"speed": int(stats.get("speed", 0)),
		"attack_interval": attack_interval,
		"cooldown": attack_interval * (0.35 + float(slot_priority) * 0.05),
		"alive": true,
		"status_text": "Holding formation",
	}


func _attack_interval_for_speed(speed: int) -> float:
	return clampf(2.2 - float(speed) / 100.0, 0.75, 1.9)


func _sort_ready_units(left: int, right: int) -> bool:
	var a: Dictionary = _units[left]
	var b: Dictionary = _units[right]

	var a_speed := int(a.get("speed", 0))
	var b_speed := int(b.get("speed", 0))
	if a_speed != b_speed:
		return a_speed > b_speed

	var a_team_order := 0 if String(a.get("team", "")) == TEAM_PLAYER else 1
	var b_team_order := 0 if String(b.get("team", "")) == TEAM_PLAYER else 1
	if a_team_order != b_team_order:
		return a_team_order < b_team_order

	return int(a.get("slot_priority", 99)) < int(b.get("slot_priority", 99))


func _select_target_index(attacker_index: int) -> int:
	var attacker: Dictionary = _units[attacker_index]
	var opposing_team := TEAM_ENEMY if String(attacker.get("team", "")) == TEAM_PLAYER else TEAM_PLAYER
	var frontline_candidates: Array[int] = []
	var all_candidates: Array[int] = []

	for index in _units.size():
		var unit: Dictionary = _units[index]
		if bool(unit.get("alive", false)) == false:
			continue
		if String(unit.get("team", "")) != opposing_team:
			continue
		all_candidates.append(index)
		if String(unit.get("line", "")) == "front":
			frontline_candidates.append(index)

	var candidates := frontline_candidates if frontline_candidates.is_empty() == false else all_candidates
	if candidates.is_empty():
		return -1

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
	var damage := _calculate_damage(attacker, target)

	target["hp"] = maxi(0, int(target.get("hp", 0)) - damage)
	attacker["cooldown"] = float(attacker.get("attack_interval", 1.0))
	attacker["status_text"] = "Hit %s for %d" % [String(target.get("display_name", "Target")), damage]
	target["status_text"] = "Took %d damage" % damage

	events.append({
		"type": "attack",
		"attacker_id": String(attacker.get("unit_id", "")),
		"target_id": String(target.get("unit_id", "")),
		"damage": damage,
	})
	_record_log(
		"%.1fs  %s hit %s for %d" % [
			snappedf(_elapsed_seconds, 0.1),
			String(attacker.get("display_name", "Attacker")),
			String(target.get("display_name", "Target")),
			damage,
		]
	)

	if int(target.get("hp", 0)) <= 0:
		target["alive"] = false
		target["status_text"] = "KO"
		events.append({
			"type": "death",
			"unit_id": String(target.get("unit_id", "")),
			"team": String(target.get("team", "")),
		})
		_record_log("%s was knocked out." % String(target.get("display_name", "Unit")))


func _calculate_damage(attacker: Dictionary, defender: Dictionary) -> int:
	var attack_value := float(attacker.get("attack", 0))
	var defense_value := float(defender.get("defense", 0))
	var raw_damage := maxf(attack_value * 0.30, attack_value - defense_value * 0.55)
	return maxi(1, int(round(raw_damage)))


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
