extends Node

signal formation_changed

const SLOT_ORDER := [
	"front_left",
	"front_right",
	"back_left",
	"back_center",
	"back_right",
]

const SLOT_DEFINITIONS := {
	"front_left": {"label": "Front Left", "line": "Frontline", "index": 0},
	"front_right": {"label": "Front Right", "line": "Frontline", "index": 1},
	"back_left": {"label": "Back Left", "line": "Backline", "index": 2},
	"back_center": {"label": "Back Center", "line": "Backline", "index": 3},
	"back_right": {"label": "Back Right", "line": "Backline", "index": 4},
}

var _assignments: Dictionary = {}


func _ready() -> void:
	if ProfileState.roster_changed.is_connected(_on_roster_changed) == false:
		ProfileState.roster_changed.connect(_on_roster_changed)
	_reset_missing_slots()
	_prune_invalid_assignments()


func _on_roster_changed() -> void:
	_prune_invalid_assignments()


func slot_ids() -> Array[String]:
	var slot_ids: Array[String] = []
	for slot_id in SLOT_ORDER:
		slot_ids.append(String(slot_id))
	return slot_ids


func slot_definition(slot_id: String) -> Dictionary:
	return SLOT_DEFINITIONS.get(slot_id, {}).duplicate(true)


func assigned_count() -> int:
	var count := 0
	for slot_id in SLOT_ORDER:
		if String(_assignments.get(slot_id, "")).is_empty() == false:
			count += 1
	return count


func front_count() -> int:
	return _count_line_assignments("Frontline")


func back_count() -> int:
	return _count_line_assignments("Backline")


func status_label() -> String:
	if assigned_count() == SLOT_ORDER.size():
		return "Full"
	if assigned_count() == 0:
		return "Empty"
	return "Partial"


func get_assigned_hero_id(slot_id: String) -> String:
	return String(_assignments.get(slot_id, ""))


func get_assigned_hero(slot_id: String) -> Dictionary:
	var hero_id := get_assigned_hero_id(slot_id)
	if hero_id.is_empty():
		return {}
	return GameData.get_hero(hero_id)


func is_hero_assigned(hero_id: String) -> bool:
	for slot_id in SLOT_ORDER:
		if get_assigned_hero_id(slot_id) == hero_id:
			return true
	return false


func slot_for_hero(hero_id: String) -> String:
	for slot_id in SLOT_ORDER:
		if get_assigned_hero_id(slot_id) == hero_id:
			return slot_id
	return ""


func assign(slot_id: String, hero_id: String) -> Dictionary:
	if SLOT_DEFINITIONS.has(slot_id) == false:
		return {"ok": false, "error": "Unknown slot."}
	if ProfileState.has_hero(hero_id) == false:
		return {"ok": false, "error": "Hero is not owned."}

	var existing_slot := slot_for_hero(hero_id)
	if existing_slot.is_empty() == false and existing_slot != slot_id:
		return {"ok": false, "error": "Hero is already assigned to %s." % slot_definition(existing_slot).get("label", existing_slot)}

	_assignments[slot_id] = hero_id
	formation_changed.emit()
	return {"ok": true}


func remove(slot_id: String) -> void:
	if SLOT_DEFINITIONS.has(slot_id) == false:
		return
	if get_assigned_hero_id(slot_id).is_empty():
		return

	_assignments[slot_id] = ""
	formation_changed.emit()


func clear_formation() -> void:
	var changed := false
	for slot_id in SLOT_ORDER:
		if get_assigned_hero_id(slot_id).is_empty() == false:
			_assignments[slot_id] = ""
			changed = true

	if changed:
		formation_changed.emit()


func auto_fill() -> void:
	var available_heroes := ProfileState.owned_hero_ids()
	var changed := false
	for slot_id in SLOT_ORDER:
		if get_assigned_hero_id(slot_id).is_empty() == false:
			continue

		for hero_id in available_heroes:
			if is_hero_assigned(hero_id):
				continue
			_assignments[slot_id] = hero_id
			changed = true
			break

	if changed:
		formation_changed.emit()


func team_power() -> int:
	var total := 0
	for slot_id in SLOT_ORDER:
		var hero := get_assigned_hero(slot_id)
		if hero.is_empty():
			continue

		var level := ProfileState.hero_level(String(hero.get("hero_id", "")))
		total += hero_power_for_entry(hero, level)
	return total


func hero_power_for_entry(hero: Dictionary, level: int) -> int:
	var stats := GameData.hero_stats_for_level(hero, level)
	return (
		int(stats.get("hp", 0))
		+ int(stats.get("attack", 0)) * 8
		+ int(stats.get("defense", 0)) * 6
		+ int(stats.get("speed", 0)) * 4
	)


func selection_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry in ProfileState.owned_roster_entries():
		var hero: Dictionary = entry.get("hero", {})
		var hero_id := String(hero.get("hero_id", ""))
		entries.append({
			"hero": hero,
			"level": int(entry.get("level", 1)),
			"assigned_slot": slot_for_hero(hero_id),
			"is_assigned": is_hero_assigned(hero_id),
		})
	return entries


func summary_lines() -> Array[String]:
	return [
		"Assigned: %d / %d" % [assigned_count(), SLOT_ORDER.size()],
		"Frontline: %d / 2" % front_count(),
		"Backline: %d / 3" % back_count(),
		"Status: %s" % status_label(),
		"Team power: %d" % team_power(),
	]


func _reset_missing_slots() -> void:
	for slot_id in SLOT_ORDER:
		if _assignments.has(slot_id) == false:
			_assignments[slot_id] = ""


func _prune_invalid_assignments() -> void:
	_reset_missing_slots()
	var changed := false
	var seen_heroes: Dictionary = {}
	for slot_id in SLOT_ORDER:
		var hero_id := get_assigned_hero_id(slot_id)
		if hero_id.is_empty():
			continue
		if ProfileState.has_hero(hero_id) == false or seen_heroes.has(hero_id):
			_assignments[slot_id] = ""
			changed = true
			continue
		seen_heroes[hero_id] = true

	if changed:
		formation_changed.emit()


func _count_line_assignments(line_name: String) -> int:
	var count := 0
	for slot_id in SLOT_ORDER:
		var definition := slot_definition(slot_id)
		if String(definition.get("line", "")) != line_name:
			continue
		if get_assigned_hero_id(slot_id).is_empty() == false:
			count += 1
	return count
