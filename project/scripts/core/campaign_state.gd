extends Node

signal campaign_changed
signal battle_context_changed
signal stage_cleared(stage_id: String)

const DEFAULT_STAGE_ID := "chapter_01_stage_01"

var _unlocked_stage_ids: Dictionary = {}
var _cleared_stage_ids: Dictionary = {}
var _selected_stage_id: String = ""
var _pending_battle_stage_id: String = ""
var _last_battle_result: Dictionary = {}


func _ready() -> void:
	if GameData.data_reloaded.is_connected(_on_game_data_reloaded) == false:
		GameData.data_reloaded.connect(_on_game_data_reloaded)
	_sync_stage_progress()


func _on_game_data_reloaded() -> void:
	_sync_stage_progress()


func selected_stage_id() -> String:
	return _selected_stage_id


func pending_battle_stage_id() -> String:
	return _pending_battle_stage_id


func last_battle_result() -> Dictionary:
	return _last_battle_result.duplicate(true)


func select_stage(stage_id: String) -> void:
	if GameData.get_stage(stage_id).is_empty():
		return
	_selected_stage_id = stage_id
	campaign_changed.emit()


func clear_pending_battle() -> void:
	if _pending_battle_stage_id.is_empty():
		return
	_pending_battle_stage_id = ""
	battle_context_changed.emit()


func is_stage_unlocked(stage_id: String) -> bool:
	return bool(_unlocked_stage_ids.get(stage_id, false))


func is_stage_cleared(stage_id: String) -> bool:
	return bool(_cleared_stage_ids.get(stage_id, false))


func highest_cleared_stage_id() -> String:
	var cleared_ids := cleared_stage_ids()
	return "" if cleared_ids.is_empty() else cleared_ids[cleared_ids.size() - 1]


func unlocked_stage_ids() -> Array[String]:
	var ids: Array[String] = []
	for stage_id in GameData.stage_ids():
		if is_stage_unlocked(stage_id):
			ids.append(stage_id)
	return ids


func cleared_stage_ids() -> Array[String]:
	var ids: Array[String] = []
	for stage_id in GameData.stage_ids():
		if is_stage_cleared(stage_id):
			ids.append(stage_id)
	return ids


func stage_progress_summary() -> Array[String]:
	return [
		"Stages unlocked: %d / %d" % [unlocked_stage_ids().size(), GameData.stage_count()],
		"Stages cleared: %d" % cleared_stage_ids().size(),
		"Selected stage: %s" % _selected_stage_label(),
	]


func stage_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for stage_id in GameData.stage_ids():
		var stage: Dictionary = GameData.get_stage(stage_id)
		if stage.is_empty():
			continue
		entries.append({
			"stage": stage,
			"is_unlocked": is_stage_unlocked(stage_id),
			"is_cleared": is_stage_cleared(stage_id),
			"is_selected": stage_id == _selected_stage_id,
		})
	return entries


func can_launch_selected_stage() -> bool:
	return _selected_stage_id.is_empty() == false and is_stage_unlocked(_selected_stage_id)


func begin_stage_battle(stage_id: String) -> bool:
	if is_stage_unlocked(stage_id) == false:
		return false
	if GameData.get_stage(stage_id).is_empty():
		return false
	_selected_stage_id = stage_id
	_pending_battle_stage_id = stage_id
	battle_context_changed.emit()
	campaign_changed.emit()
	return true


func pending_battle_definition() -> Dictionary:
	if _pending_battle_stage_id.is_empty():
		return {}

	var stage: Dictionary = GameData.get_stage(_pending_battle_stage_id)
	if stage.is_empty():
		return {}

	return {
		"battle_id": String(stage.get("stage_id", "")),
		"display_name": String(stage.get("display_name", "")),
		"description": String(stage.get("description", "")),
		"duration_seconds": float(stage.get("duration_seconds", 60.0)),
		"enemy_team": stage.get("enemy_team", []).duplicate(true),
		"source_type": "campaign_stage",
		"source_path": String(stage.get("source_path", "")),
	}


func report_battle_result(victory: bool) -> void:
	if _pending_battle_stage_id.is_empty():
		return

	var stage_id := _pending_battle_stage_id
	_last_battle_result = {
		"stage_id": stage_id,
		"victory": victory,
		"timestamp": Time.get_unix_time_from_system(),
	}

	if victory:
		var was_cleared := bool(_cleared_stage_ids.get(stage_id, false))
		_cleared_stage_ids[stage_id] = true
		var next_stage_id := GameData.next_stage_id(stage_id)
		if next_stage_id.is_empty() == false:
			_unlocked_stage_ids[next_stage_id] = true
		if was_cleared == false:
			stage_cleared.emit(stage_id)

	_pending_battle_stage_id = ""
	campaign_changed.emit()
	battle_context_changed.emit()


func unlock_all_stages_for_debug() -> void:
	for stage_id in GameData.stage_ids():
		_unlocked_stage_ids[stage_id] = true
	campaign_changed.emit()
	battle_context_changed.emit()


func serialize_state() -> Dictionary:
	return {
		"unlocked_stage_ids": unlocked_stage_ids(),
		"cleared_stage_ids": cleared_stage_ids(),
		"selected_stage_id": _selected_stage_id,
		"last_battle_result": _last_battle_result.duplicate(true),
	}


func apply_state(data: Dictionary) -> void:
	_unlocked_stage_ids.clear()
	_cleared_stage_ids.clear()

	for stage_id in data.get("unlocked_stage_ids", []):
		if GameData.get_stage(String(stage_id)).is_empty():
			continue
		_unlocked_stage_ids[String(stage_id)] = true

	for stage_id in data.get("cleared_stage_ids", []):
		if GameData.get_stage(String(stage_id)).is_empty():
			continue
		_cleared_stage_ids[String(stage_id)] = true

	_selected_stage_id = String(data.get("selected_stage_id", DEFAULT_STAGE_ID))
	_last_battle_result = data.get("last_battle_result", {}).duplicate(true)
	_pending_battle_stage_id = ""
	_sync_stage_progress()


func reset_persistent_state() -> void:
	_unlocked_stage_ids.clear()
	_cleared_stage_ids.clear()
	_selected_stage_id = ""
	_pending_battle_stage_id = ""
	_last_battle_result = {}
	_sync_stage_progress()


func _sync_stage_progress() -> void:
	var next_unlocked: Dictionary = {}
	var next_cleared: Dictionary = {}

	for stage_id in GameData.stage_ids():
		if stage_id == DEFAULT_STAGE_ID or bool(_unlocked_stage_ids.get(stage_id, false)):
			next_unlocked[stage_id] = true
		if bool(_cleared_stage_ids.get(stage_id, false)):
			next_cleared[stage_id] = true

	_unlocked_stage_ids = next_unlocked
	_cleared_stage_ids = next_cleared

	if GameData.get_stage(_selected_stage_id).is_empty():
		_selected_stage_id = DEFAULT_STAGE_ID if GameData.get_stage(DEFAULT_STAGE_ID).is_empty() == false else _first_available_stage_id()
	if GameData.get_stage(_pending_battle_stage_id).is_empty():
		_pending_battle_stage_id = ""

	campaign_changed.emit()
	battle_context_changed.emit()


func _selected_stage_label() -> String:
	var stage: Dictionary = GameData.get_stage(_selected_stage_id)
	if stage.is_empty():
		return "None"
	return String(stage.get("display_name", _selected_stage_id))


func _first_available_stage_id() -> String:
	var stage_ids := GameData.stage_ids()
	return "" if stage_ids.is_empty() else stage_ids[0]
