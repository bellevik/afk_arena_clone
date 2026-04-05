extends Node

signal quest_state_changed
signal quest_claimed(quest_id: String)

const DAY_SECONDS := 24 * 60 * 60
const WEEK_SECONDS := 7 * DAY_SECONDS

var _milestone_progress_by_id: Dictionary = {}
var _milestone_claimed_ids: Dictionary = {}
var _recurring_state_by_id: Dictionary = {}


func _ready() -> void:
	if GameData.data_reloaded.is_connected(_on_game_data_reloaded) == false:
		GameData.data_reloaded.connect(_on_game_data_reloaded)
	if CampaignState.stage_cleared.is_connected(_on_stage_cleared) == false:
		CampaignState.stage_cleared.connect(_on_stage_cleared)
	if RewardState.battle_rewards_granted.is_connected(_on_battle_rewards_granted) == false:
		RewardState.battle_rewards_granted.connect(_on_battle_rewards_granted)
	if RewardState.afk_rewards_claimed.is_connected(_on_afk_rewards_claimed) == false:
		RewardState.afk_rewards_claimed.connect(_on_afk_rewards_claimed)
	if ProfileState.hero_leveled.is_connected(_on_hero_leveled) == false:
		ProfileState.hero_leveled.connect(_on_hero_leveled)
	if SummonState.summon_completed.is_connected(_on_summon_completed) == false:
		SummonState.summon_completed.connect(_on_summon_completed)
	_sync_to_catalog()


func quest_entries() -> Array[Dictionary]:
	_refresh_recurring_cycles()
	var entries: Array[Dictionary] = []
	for quest_id in GameData.quest_ids():
		var quest: Dictionary = GameData.get_quest(quest_id)
		if quest.is_empty():
			continue
		var progress := progress_for_quest(quest_id)
		var target := int(quest.get("target_count", 1))
		var cadence := String(quest.get("cadence", "milestone"))
		var is_claimed := is_quest_claimed(quest_id)
		entries.append({
			"quest": quest,
			"progress": progress,
			"target": target,
			"cadence": cadence,
			"cadence_label": _cadence_label(cadence),
			"reset_label": recurring_reset_label(cadence),
			"is_complete": progress >= target,
			"is_claimed": is_claimed,
			"can_claim": progress >= target and is_claimed == false,
		})
	return entries


func progress_for_quest(quest_id: String) -> int:
	var quest: Dictionary = GameData.get_quest(quest_id)
	if _is_recurring_quest(quest):
		var recurring: Dictionary = _current_recurring_state(quest_id)
		return int(recurring.get("progress", 0))
	return int(_milestone_progress_by_id.get(quest_id, 0))


func is_quest_claimed(quest_id: String) -> bool:
	var quest: Dictionary = GameData.get_quest(quest_id)
	if _is_recurring_quest(quest):
		var recurring: Dictionary = _current_recurring_state(quest_id)
		return bool(recurring.get("claimed", false))
	return bool(_milestone_claimed_ids.get(quest_id, false))


func summary_lines() -> Array[String]:
	_refresh_recurring_cycles()
	var claimed := 0
	var complete_unclaimed := 0
	for entry in quest_entries():
		if bool(entry.get("is_claimed", false)):
			claimed += 1
		elif bool(entry.get("is_complete", false)):
			complete_unclaimed += 1
	return [
		"Quest entries: %d" % GameData.quest_count(),
		"Milestone: %d  |  Daily: %d  |  Weekly: %d" % [
			GameData.quest_ids_for_cadence("milestone").size(),
			GameData.quest_ids_for_cadence("daily").size(),
			GameData.quest_ids_for_cadence("weekly").size(),
		],
		"Claimable now: %d" % complete_unclaimed,
		"Claimed: %d" % claimed,
		"Daily reset: %s" % recurring_reset_label("daily"),
		"Weekly reset: %s" % recurring_reset_label("weekly"),
	]


func recurring_reset_label(cadence: String) -> String:
	match cadence:
		"daily":
			return _format_duration(_seconds_until_cycle_reset(DAY_SECONDS))
		"weekly":
			return _format_duration(_seconds_until_cycle_reset(WEEK_SECONDS))
		_:
			return "No reset"


func claim_quest(quest_id: String) -> Dictionary:
	_refresh_recurring_cycles()
	var quest: Dictionary = GameData.get_quest(quest_id)
	if quest.is_empty():
		return {"ok": false, "reason": "missing_quest"}
	if is_quest_claimed(quest_id):
		return {"ok": false, "reason": "already_claimed"}
	if progress_for_quest(quest_id) < int(quest.get("target_count", 1)):
		return {"ok": false, "reason": "not_complete"}

	if _is_recurring_quest(quest):
		var recurring := _current_recurring_state(quest_id)
		recurring["claimed"] = true
		_recurring_state_by_id[quest_id] = recurring
	else:
		_milestone_claimed_ids[quest_id] = true

	var rewards: Dictionary = quest.get("rewards", {}).duplicate(true)
	RewardState.grant_resources(rewards)
	quest_state_changed.emit()
	quest_claimed.emit(quest_id)
	return {
		"ok": true,
		"quest_id": quest_id,
		"rewards": rewards,
	}


func serialize_state() -> Dictionary:
	_refresh_recurring_cycles(false)
	return {
		"milestone_progress_by_id": _milestone_progress_by_id.duplicate(true),
		"milestone_claimed_ids": claimed_quest_ids_for_cadence("milestone"),
		"recurring_state_by_id": _recurring_state_by_id.duplicate(true),
	}


func apply_state(data: Dictionary) -> void:
	_milestone_progress_by_id.clear()
	_milestone_claimed_ids.clear()
	_recurring_state_by_id.clear()

	for quest_id in GameData.quest_ids():
		var quest: Dictionary = GameData.get_quest(quest_id)
		if _is_recurring_quest(quest):
			var stored: Dictionary = data.get("recurring_state_by_id", {}).get(quest_id, {})
			_recurring_state_by_id[quest_id] = {
				"cycle_key": String(stored.get("cycle_key", _current_cycle_key(String(quest.get("cadence", "daily"))))),
				"progress": maxi(int(stored.get("progress", 0)), 0),
				"claimed": bool(stored.get("claimed", false)),
			}
			continue

		var target := int(quest.get("target_count", 1))
		_milestone_progress_by_id[quest_id] = clampi(int(data.get("milestone_progress_by_id", {}).get(quest_id, 0)), 0, target)

	for quest_id in data.get("milestone_claimed_ids", []):
		if GameData.get_quest(String(quest_id)).is_empty():
			continue
		if String(GameData.get_quest(String(quest_id)).get("cadence", "milestone")) != "milestone":
			continue
		_milestone_claimed_ids[String(quest_id)] = true

	_sync_to_catalog()


func reset_persistent_state() -> void:
	_milestone_progress_by_id.clear()
	_milestone_claimed_ids.clear()
	_recurring_state_by_id.clear()
	_sync_to_catalog()


func claimed_quest_ids() -> Array[String]:
	_refresh_recurring_cycles(false)
	var ids: Array[String] = []
	for quest_id in GameData.quest_ids():
		if is_quest_claimed(quest_id):
			ids.append(quest_id)
	return ids


func claimed_quest_ids_for_cadence(cadence: String) -> Array[String]:
	_refresh_recurring_cycles(false)
	var ids: Array[String] = []
	for quest_id in GameData.quest_ids_for_cadence(cadence):
		if is_quest_claimed(quest_id):
			ids.append(quest_id)
	return ids


func _on_game_data_reloaded() -> void:
	_sync_to_catalog()


func _on_stage_cleared(_stage_id: String) -> void:
	_increment_event("stage_clear", 1)


func _on_battle_rewards_granted(payload: Dictionary) -> void:
	if bool(payload.get("victory", false)) == false:
		return
	_increment_event("battle_win", 1)


func _on_afk_rewards_claimed(payload: Dictionary) -> void:
	var total_value := int(payload.get("gold", 0)) + int(payload.get("hero_xp", 0))
	if total_value <= 0:
		return
	_increment_event("afk_claim", 1)


func _on_hero_leveled(_hero_id: String, _new_level: int) -> void:
	_increment_event("hero_level_up", 1)


func _on_summon_completed(payload: Dictionary) -> void:
	_increment_event("summon_pull", int(payload.get("pull_count", 0)))


func _increment_event(event_type: String, amount: int) -> void:
	if amount <= 0:
		return
	_refresh_recurring_cycles(false)
	var changed := false
	for quest_id in GameData.quest_ids():
		var quest: Dictionary = GameData.get_quest(quest_id)
		if String(quest.get("event_type", "")) != event_type:
			continue
		if is_quest_claimed(quest_id):
			continue

		var target := int(quest.get("target_count", 1))
		if _is_recurring_quest(quest):
			var recurring := _current_recurring_state(quest_id)
			var next_value := clampi(int(recurring.get("progress", 0)) + amount, 0, target)
			if next_value == int(recurring.get("progress", 0)):
				continue
			recurring["progress"] = next_value
			_recurring_state_by_id[quest_id] = recurring
			changed = true
			continue

		var next_milestone_value := clampi(int(_milestone_progress_by_id.get(quest_id, 0)) + amount, 0, target)
		if next_milestone_value == int(_milestone_progress_by_id.get(quest_id, 0)):
			continue
		_milestone_progress_by_id[quest_id] = next_milestone_value
		changed = true

	if changed:
		quest_state_changed.emit()


func _sync_to_catalog() -> void:
	var next_milestone_progress: Dictionary = {}
	for quest_id in GameData.quest_ids_for_cadence("milestone"):
		var quest: Dictionary = GameData.get_quest(quest_id)
		var target := int(quest.get("target_count", 1))
		next_milestone_progress[quest_id] = clampi(int(_milestone_progress_by_id.get(quest_id, 0)), 0, target)
	_milestone_progress_by_id = next_milestone_progress

	var next_milestone_claimed: Dictionary = {}
	for quest_id in GameData.quest_ids_for_cadence("milestone"):
		if bool(_milestone_claimed_ids.get(quest_id, false)):
			next_milestone_claimed[quest_id] = true
	_milestone_claimed_ids = next_milestone_claimed

	var next_recurring_state: Dictionary = {}
	for quest_id in GameData.quest_ids():
		var quest: Dictionary = GameData.get_quest(quest_id)
		if _is_recurring_quest(quest) == false:
			continue
		var cadence := String(quest.get("cadence", "daily"))
		var cycle_key := _current_cycle_key(cadence)
		var existing: Dictionary = _recurring_state_by_id.get(quest_id, {})
		if String(existing.get("cycle_key", "")) != cycle_key:
			next_recurring_state[quest_id] = _default_recurring_state(cycle_key)
			continue
		next_recurring_state[quest_id] = {
			"cycle_key": cycle_key,
			"progress": clampi(int(existing.get("progress", 0)), 0, int(quest.get("target_count", 1))),
			"claimed": bool(existing.get("claimed", false)),
		}
	_recurring_state_by_id = next_recurring_state
	quest_state_changed.emit()


func _refresh_recurring_cycles(emit_signal: bool = true) -> void:
	var changed := false
	for quest_id in GameData.quest_ids():
		var quest: Dictionary = GameData.get_quest(quest_id)
		if _is_recurring_quest(quest) == false:
			continue
		var cadence := String(quest.get("cadence", "daily"))
		var cycle_key := _current_cycle_key(cadence)
		var existing: Dictionary = _recurring_state_by_id.get(quest_id, {})
		if String(existing.get("cycle_key", "")) == cycle_key:
			continue
		_recurring_state_by_id[quest_id] = _default_recurring_state(cycle_key)
		changed = true
	if changed and emit_signal:
		quest_state_changed.emit()


func _current_recurring_state(quest_id: String) -> Dictionary:
	var quest: Dictionary = GameData.get_quest(quest_id)
	var cadence := String(quest.get("cadence", "daily"))
	var cycle_key := _current_cycle_key(cadence)
	var existing: Dictionary = _recurring_state_by_id.get(quest_id, {})
	if String(existing.get("cycle_key", "")) != cycle_key:
		existing = _default_recurring_state(cycle_key)
		_recurring_state_by_id[quest_id] = existing
	return existing


func _default_recurring_state(cycle_key: String) -> Dictionary:
	return {
		"cycle_key": cycle_key,
		"progress": 0,
		"claimed": false,
	}


func _is_recurring_quest(quest: Dictionary) -> bool:
	var cadence := String(quest.get("cadence", "milestone"))
	return cadence == "daily" or cadence == "weekly"


func _cadence_label(cadence: String) -> String:
	match cadence:
		"daily":
			return "Daily"
		"weekly":
			return "Weekly"
		_:
			return "Milestone"


func _current_cycle_key(cadence: String) -> String:
	var unix_now := _now_unix()
	match cadence:
		"daily":
			return "d_%d" % int(floor(float(unix_now) / float(DAY_SECONDS)))
		"weekly":
			return "w_%d" % int(floor(float(unix_now) / float(WEEK_SECONDS)))
		_:
			return "m_static"


func _seconds_until_cycle_reset(period_seconds: int) -> int:
	var unix_now := _now_unix()
	var elapsed_in_period := posmod(unix_now, period_seconds)
	var remaining := period_seconds - elapsed_in_period
	if remaining <= 0:
		return period_seconds
	return remaining


func _format_duration(total_seconds: int) -> String:
	var seconds := maxi(total_seconds, 0)
	var days := seconds / DAY_SECONDS
	seconds %= DAY_SECONDS
	var hours := seconds / 3600
	seconds %= 3600
	var minutes := seconds / 60
	if days > 0:
		return "%dd %02dh %02dm" % [days, hours, minutes]
	return "%02dh %02dm" % [hours, minutes]


func _now_unix() -> int:
	return int(Time.get_unix_time_from_system())
