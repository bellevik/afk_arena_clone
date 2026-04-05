extends Node

signal event_state_changed
signal milestone_claimed(event_id: String, milestone_id: String)
signal event_stage_cleared(event_id: String, stage_id: String)

var _selected_event_id := ""
var _selected_stage_id_by_event_id: Dictionary = {}
var _unlocked_stage_ids_by_event_id: Dictionary = {}
var _cleared_stage_ids_by_event_id: Dictionary = {}
var _pending_battle_event_id := ""
var _pending_battle_stage_id := ""
var _last_battle_result: Dictionary = {}
var _points_by_event_id: Dictionary = {}
var _claimed_milestones_by_event_id: Dictionary = {}


func _ready() -> void:
	if GameData.data_reloaded.is_connected(_on_game_data_reloaded) == false:
		GameData.data_reloaded.connect(_on_game_data_reloaded)
	if CampaignState.stage_cleared.is_connected(_on_stage_cleared) == false:
		CampaignState.stage_cleared.connect(_on_stage_cleared)
	if RewardState.afk_rewards_claimed.is_connected(_on_afk_rewards_claimed) == false:
		RewardState.afk_rewards_claimed.connect(_on_afk_rewards_claimed)
	if SummonState.summon_completed.is_connected(_on_summon_completed) == false:
		SummonState.summon_completed.connect(_on_summon_completed)
	if QuestState.quest_claimed.is_connected(_on_quest_claimed) == false:
		QuestState.quest_claimed.connect(_on_quest_claimed)
	_sync_to_catalog()


func event_ids() -> Array[String]:
	return GameData.live_event_ids()


func active_event_ids() -> Array[String]:
	var ids: Array[String] = []
	for event_id in GameData.live_event_ids():
		if is_event_active(event_id):
			ids.append(event_id)
	return ids


func selected_event_id() -> String:
	return _selected_event_id


func selected_event() -> Dictionary:
	return GameData.get_live_event(_selected_event_id)


func active_event_count() -> int:
	return active_event_ids().size()


func event_points(event_id: String) -> int:
	return int(_points_by_event_id.get(event_id, 0))


func selected_event_points() -> int:
	return event_points(_selected_event_id)


func selected_stage_id() -> String:
	return selected_stage_id_for_event(_selected_event_id)


func selected_stage_id_for_event(event_id: String) -> String:
	return String(_selected_stage_id_by_event_id.get(event_id, _first_stage_id_for_event(event_id)))


func selected_stage() -> Dictionary:
	return GameData.get_live_event_stage(selected_stage_id())


func is_event_active(event_id: String) -> bool:
	var event: Dictionary = GameData.get_live_event(event_id)
	if event.is_empty():
		return false
	var now := _now_unix()
	var start_unix := int(event.get("start_unix", 0))
	var end_unix := int(event.get("end_unix", 0))
	if start_unix > 0 and now < start_unix:
		return false
	if end_unix > 0 and now > end_unix:
		return false
	return true


func event_time_label(event_id: String) -> String:
	var event: Dictionary = GameData.get_live_event(event_id)
	if event.is_empty():
		return "Unavailable"
	if is_event_active(event_id) == false:
		var start_unix := int(event.get("start_unix", 0))
		if start_unix > _now_unix():
			return "Starts in %s" % _format_duration(start_unix - _now_unix())
		return "Ended"
	var end_unix := int(event.get("end_unix", 0))
	if end_unix <= 0:
		return "No event end set"
	return "Ends in %s" % _format_duration(maxi(end_unix - _now_unix(), 0))


func event_summary_lines(event_id: String) -> Array[String]:
	var event: Dictionary = GameData.get_live_event(event_id)
	if event.is_empty():
		return ["No active event selected."]
	var linked_banner_id := String(event.get("linked_banner_id", ""))
	var linked_banner: Dictionary = GameData.get_summon_banner(linked_banner_id)
	return [
		"%s  |  %s" % [
			String(event.get("display_name", "Event")),
			String(event.get("status_label", "Live")),
		],
		String(event.get("description", "")),
		"Points: %d" % event_points(event_id),
		"Stages cleared: %d / %d" % [cleared_stage_ids(event_id).size(), event_stage_entries(event_id).size()],
		"State: %s" % ("Active" if is_event_active(event_id) else "Inactive"),
		event_time_label(event_id),
		"Linked banner: %s" % String(linked_banner.get("display_name", linked_banner_id if linked_banner_id.is_empty() == false else "None")),
	]


func point_source_entries(event_id: String) -> Array[Dictionary]:
	var event: Dictionary = GameData.get_live_event(event_id)
	var entries: Array[Dictionary] = []
	for source in event.get("point_sources", []):
		if source is Dictionary == false:
			continue
		entries.append(source.duplicate(true))
	return entries


func milestone_entries(event_id: String) -> Array[Dictionary]:
	var event: Dictionary = GameData.get_live_event(event_id)
	var entries: Array[Dictionary] = []
	var current_points := event_points(event_id)
	for milestone in event.get("milestones", []):
		if milestone is Dictionary == false:
			continue
		var milestone_id := String(milestone.get("milestone_id", ""))
		var target_points := int(milestone.get("target_points", 0))
		var claimed := is_milestone_claimed(event_id, milestone_id)
		entries.append({
			"milestone": milestone.duplicate(true),
			"progress": mini(current_points, target_points),
			"target_points": target_points,
			"is_claimed": claimed,
			"can_claim": current_points >= target_points and claimed == false,
		})
	return entries


func event_stage_entries(event_id: String) -> Array[Dictionary]:
	var event: Dictionary = GameData.get_live_event(event_id)
	var entries: Array[Dictionary] = []
	for stage in event.get("stages", []):
		if stage is Dictionary == false:
			continue
		var stage_id := String(stage.get("stage_id", ""))
		entries.append({
			"stage": stage.duplicate(true),
			"is_unlocked": is_stage_unlocked(event_id, stage_id),
			"is_cleared": is_stage_cleared(event_id, stage_id),
			"is_selected": selected_stage_id_for_event(event_id) == stage_id,
		})
	return entries


func is_stage_unlocked(event_id: String, stage_id: String) -> bool:
	return bool(_unlocked_ids_for_event(event_id).get(stage_id, false))


func is_stage_cleared(event_id: String, stage_id: String) -> bool:
	return bool(_cleared_ids_for_event(event_id).get(stage_id, false))


func cleared_stage_ids(event_id: String) -> Array[String]:
	var ids: Array[String] = []
	for stage in GameData.get_live_event(event_id).get("stages", []):
		if stage is Dictionary == false:
			continue
		var stage_id := String(stage.get("stage_id", ""))
		if is_stage_cleared(event_id, stage_id):
			ids.append(stage_id)
	return ids


func last_battle_result() -> Dictionary:
	return _last_battle_result.duplicate(true)


func select_event(event_id: String) -> void:
	if GameData.get_live_event(event_id).is_empty():
		return
	_selected_event_id = event_id
	event_state_changed.emit()


func select_stage(event_id: String, stage_id: String) -> void:
	if GameData.get_live_event(event_id).is_empty():
		return
	if GameData.get_live_event_stage(stage_id).is_empty():
		return
	if String(GameData.get_live_event_stage(stage_id).get("event_id", "")) != event_id:
		return
	_selected_event_id = event_id
	_selected_stage_id_by_event_id[event_id] = stage_id
	event_state_changed.emit()


func can_launch_selected_stage() -> bool:
	var event_id := _selected_event_id
	var stage_id := selected_stage_id_for_event(event_id)
	return event_id.is_empty() == false and stage_id.is_empty() == false and is_stage_unlocked(event_id, stage_id)


func begin_stage_battle(event_id: String, stage_id: String) -> bool:
	if is_event_active(event_id) == false:
		return false
	if is_stage_unlocked(event_id, stage_id) == false:
		return false
	var stage: Dictionary = GameData.get_live_event_stage(stage_id)
	if stage.is_empty():
		return false
	if String(stage.get("event_id", "")) != event_id:
		return false
	_selected_event_id = event_id
	_selected_stage_id_by_event_id[event_id] = stage_id
	_pending_battle_event_id = event_id
	_pending_battle_stage_id = stage_id
	event_state_changed.emit()
	return true


func pending_battle_definition() -> Dictionary:
	if _pending_battle_event_id.is_empty() or _pending_battle_stage_id.is_empty():
		return {}
	var stage: Dictionary = GameData.get_live_event_stage(_pending_battle_stage_id)
	if stage.is_empty():
		return {}
	return {
		"battle_id": String(stage.get("stage_id", "")),
		"display_name": String(stage.get("display_name", "")),
		"description": String(stage.get("description", "")),
		"duration_seconds": float(stage.get("duration_seconds", 60.0)),
		"modifiers": stage.get("modifiers", []).duplicate(true),
		"enemy_team": stage.get("enemy_team", []).duplicate(true),
		"source_type": "event_stage",
		"source_path": String(stage.get("source_path", "")),
	}


func report_battle_result(victory: bool) -> void:
	if _pending_battle_event_id.is_empty() or _pending_battle_stage_id.is_empty():
		return

	var event_id := _pending_battle_event_id
	var stage_id := _pending_battle_stage_id
	_last_battle_result = {
		"event_id": event_id,
		"stage_id": stage_id,
		"victory": victory,
		"timestamp": Time.get_unix_time_from_system(),
	}

	if victory:
		var was_cleared := is_stage_cleared(event_id, stage_id)
		var cleared_ids := _cleared_ids_for_event(event_id)
		cleared_ids[stage_id] = true
		_cleared_stage_ids_by_event_id[event_id] = cleared_ids

		var next_stage_id := GameData.next_live_event_stage_id(event_id, stage_id)
		if next_stage_id.is_empty() == false:
			var unlocked_ids := _unlocked_ids_for_event(event_id)
			unlocked_ids[next_stage_id] = true
			_unlocked_stage_ids_by_event_id[event_id] = unlocked_ids

		if was_cleared == false:
			_award_points_from_event("event_stage_clear", 1)
			event_stage_cleared.emit(event_id, stage_id)

	_pending_battle_event_id = ""
	_pending_battle_stage_id = ""
	event_state_changed.emit()


func claim_milestone(event_id: String, milestone_id: String) -> Dictionary:
	if is_event_active(event_id) == false:
		return {"ok": false, "reason": "inactive_event"}
	var milestone := _get_milestone(event_id, milestone_id)
	if milestone.is_empty():
		return {"ok": false, "reason": "missing_milestone"}
	if is_milestone_claimed(event_id, milestone_id):
		return {"ok": false, "reason": "already_claimed"}
	if event_points(event_id) < int(milestone.get("target_points", 0)):
		return {"ok": false, "reason": "not_enough_points"}

	var claimed_ids := _claimed_ids_for_event(event_id)
	claimed_ids[milestone_id] = true
	_claimed_milestones_by_event_id[event_id] = claimed_ids
	var rewards: Dictionary = milestone.get("rewards", {}).duplicate(true)
	RewardState.grant_resources(rewards)
	event_state_changed.emit()
	milestone_claimed.emit(event_id, milestone_id)
	return {
		"ok": true,
		"event_id": event_id,
		"milestone_id": milestone_id,
		"rewards": rewards,
	}


func is_milestone_claimed(event_id: String, milestone_id: String) -> bool:
	return bool(_claimed_ids_for_event(event_id).get(milestone_id, false))


func linked_banner_id_for_event(event_id: String) -> String:
	return String(GameData.get_live_event(event_id).get("linked_banner_id", ""))


func battle_reward_package(stage_id: String) -> Dictionary:
	var stage: Dictionary = GameData.get_live_event_stage(stage_id)
	return stage.get("battle_rewards", {}).duplicate(true)


func debug_grant_points_to_active_event(points: int = 150) -> void:
	if _selected_event_id.is_empty():
		return
	_points_by_event_id[_selected_event_id] = maxi(event_points(_selected_event_id) + maxi(points, 0), 0)
	event_state_changed.emit()


func serialize_state() -> Dictionary:
	return {
		"selected_event_id": _selected_event_id,
		"selected_stage_id_by_event_id": _selected_stage_id_by_event_id.duplicate(true),
		"unlocked_stage_ids_by_event_id": _unlocked_stage_ids_by_event_id.duplicate(true),
		"cleared_stage_ids_by_event_id": _cleared_stage_ids_by_event_id.duplicate(true),
		"last_battle_result": _last_battle_result.duplicate(true),
		"points_by_event_id": _points_by_event_id.duplicate(true),
		"claimed_milestones_by_event_id": _claimed_milestones_by_event_id.duplicate(true),
	}


func apply_state(data: Dictionary) -> void:
	_selected_event_id = String(data.get("selected_event_id", ""))
	_selected_stage_id_by_event_id.clear()
	_unlocked_stage_ids_by_event_id.clear()
	_cleared_stage_ids_by_event_id.clear()
	_points_by_event_id.clear()
	_claimed_milestones_by_event_id.clear()
	_last_battle_result = data.get("last_battle_result", {}).duplicate(true)
	_pending_battle_event_id = ""
	_pending_battle_stage_id = ""

	for event_id in GameData.live_event_ids():
		_selected_stage_id_by_event_id[event_id] = String(data.get("selected_stage_id_by_event_id", {}).get(event_id, _first_stage_id_for_event(event_id)))
		_points_by_event_id[event_id] = maxi(int(data.get("points_by_event_id", {}).get(event_id, 0)), 0)

		var unlocked_ids: Dictionary = {}
		for stage_id in data.get("unlocked_stage_ids_by_event_id", {}).get(event_id, {}).keys():
			unlocked_ids[String(stage_id)] = bool(data.get("unlocked_stage_ids_by_event_id", {}).get(event_id, {}).get(stage_id, false))
		_unlocked_stage_ids_by_event_id[event_id] = unlocked_ids

		var cleared_ids: Dictionary = {}
		for stage_id in data.get("cleared_stage_ids_by_event_id", {}).get(event_id, {}).keys():
			cleared_ids[String(stage_id)] = bool(data.get("cleared_stage_ids_by_event_id", {}).get(event_id, {}).get(stage_id, false))
		_cleared_stage_ids_by_event_id[event_id] = cleared_ids

		var claimed_ids: Dictionary = {}
		for milestone_id in data.get("claimed_milestones_by_event_id", {}).get(event_id, {}).keys():
			claimed_ids[String(milestone_id)] = bool(data.get("claimed_milestones_by_event_id", {}).get(event_id, {}).get(milestone_id, false))
		_claimed_milestones_by_event_id[event_id] = claimed_ids

	_sync_to_catalog()


func reset_persistent_state() -> void:
	_selected_event_id = ""
	_selected_stage_id_by_event_id.clear()
	_unlocked_stage_ids_by_event_id.clear()
	_cleared_stage_ids_by_event_id.clear()
	_pending_battle_event_id = ""
	_pending_battle_stage_id = ""
	_last_battle_result = {}
	_points_by_event_id.clear()
	_claimed_milestones_by_event_id.clear()
	_sync_to_catalog()


func _on_game_data_reloaded() -> void:
	_sync_to_catalog()


func _on_stage_cleared(_stage_id: String) -> void:
	_award_points_from_event("stage_clear", 1)


func _on_afk_rewards_claimed(payload: Dictionary) -> void:
	var total_value := int(payload.get("gold", 0)) + int(payload.get("hero_xp", 0))
	if total_value <= 0:
		return
	_award_points_from_event("afk_claim", 1)


func _on_summon_completed(payload: Dictionary) -> void:
	_award_points_from_event("summon_pull", maxi(int(payload.get("pull_count", 0)), 0))


func _on_quest_claimed(_quest_id: String) -> void:
	_award_points_from_event("quest_claim", 1)


func _award_points_from_event(event_type: String, units: int) -> void:
	if units <= 0:
		return
	var changed := false
	for event_id in active_event_ids():
		var awarded := _points_per_unit_for_event(event_id, event_type) * units
		if awarded <= 0:
			continue
		_points_by_event_id[event_id] = maxi(event_points(event_id) + awarded, 0)
		changed = true
	if changed:
		event_state_changed.emit()


func _points_per_unit_for_event(event_id: String, event_type: String) -> int:
	for source in point_source_entries(event_id):
		if String(source.get("event_type", "")) == event_type:
			return maxi(int(source.get("points", 0)), 0)
	return 0


func _get_milestone(event_id: String, milestone_id: String) -> Dictionary:
	for milestone in GameData.get_live_event(event_id).get("milestones", []):
		if milestone is Dictionary == false:
			continue
		if String(milestone.get("milestone_id", "")) == milestone_id:
			return milestone.duplicate(true)
	return {}


func _claimed_ids_for_event(event_id: String) -> Dictionary:
	return _claimed_milestones_by_event_id.get(event_id, {})


func _unlocked_ids_for_event(event_id: String) -> Dictionary:
	return _unlocked_stage_ids_by_event_id.get(event_id, {})


func _cleared_ids_for_event(event_id: String) -> Dictionary:
	return _cleared_stage_ids_by_event_id.get(event_id, {})


func _sync_to_catalog() -> void:
	var next_selected_stage_ids: Dictionary = {}
	var next_unlocked: Dictionary = {}
	var next_cleared: Dictionary = {}
	var next_points: Dictionary = {}
	var next_claimed: Dictionary = {}

	for event_id in GameData.live_event_ids():
		next_selected_stage_ids[event_id] = String(_selected_stage_id_by_event_id.get(event_id, _first_stage_id_for_event(event_id)))
		next_points[event_id] = maxi(int(_points_by_event_id.get(event_id, 0)), 0)

		var unlocked_ids: Dictionary = {}
		var first_stage_id := _first_stage_id_for_event(event_id)
		if first_stage_id.is_empty() == false:
			unlocked_ids[first_stage_id] = true
		for stage in GameData.get_live_event(event_id).get("stages", []):
			if stage is Dictionary == false:
				continue
			var stage_id := String(stage.get("stage_id", ""))
			if bool(_unlocked_ids_for_event(event_id).get(stage_id, false)):
				unlocked_ids[stage_id] = true
		next_unlocked[event_id] = unlocked_ids

		var cleared_ids: Dictionary = {}
		for stage in GameData.get_live_event(event_id).get("stages", []):
			if stage is Dictionary == false:
				continue
			var stage_id := String(stage.get("stage_id", ""))
			if bool(_cleared_ids_for_event(event_id).get(stage_id, false)):
				cleared_ids[stage_id] = true
		next_cleared[event_id] = cleared_ids

		var claimed_ids: Dictionary = {}
		for milestone in GameData.get_live_event(event_id).get("milestones", []):
			if milestone is Dictionary == false:
				continue
			var milestone_id := String(milestone.get("milestone_id", ""))
			if bool(_claimed_ids_for_event(event_id).get(milestone_id, false)):
				claimed_ids[milestone_id] = true
		next_claimed[event_id] = claimed_ids

	_selected_stage_id_by_event_id = next_selected_stage_ids
	_unlocked_stage_ids_by_event_id = next_unlocked
	_cleared_stage_ids_by_event_id = next_cleared
	_points_by_event_id = next_points
	_claimed_milestones_by_event_id = next_claimed

	if GameData.get_live_event(_selected_event_id).is_empty():
		_selected_event_id = _first_active_event_id()
		if _selected_event_id.is_empty():
			_selected_event_id = GameData.default_live_event_id()

	if String(_selected_stage_id_by_event_id.get(_selected_event_id, "")).is_empty():
		_selected_stage_id_by_event_id[_selected_event_id] = _first_stage_id_for_event(_selected_event_id)

	event_state_changed.emit()


func _first_active_event_id() -> String:
	var active_ids := active_event_ids()
	return "" if active_ids.is_empty() else active_ids[0]


func _first_stage_id_for_event(event_id: String) -> String:
	var event: Dictionary = GameData.get_live_event(event_id)
	var stages: Array = event.get("stages", [])
	if stages.is_empty():
		return ""
	return String(stages[0].get("stage_id", ""))


func _now_unix() -> int:
	return int(Time.get_unix_time_from_system())


func _format_duration(total_seconds: int) -> String:
	var remaining := maxi(total_seconds, 0)
	var days := remaining / (24 * 3600)
	var hours := (remaining % (24 * 3600)) / 3600
	if days > 0:
		return "%dd %dh" % [days, hours]
	var minutes := (remaining % 3600) / 60
	return "%dh %dm" % [hours, minutes]
