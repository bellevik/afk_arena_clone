extends Node

signal save_state_changed

const SAVE_VERSION := 6
const SAVE_PATH := "user://save_game.json"

var _is_loading := false
var _save_queued := false
var _last_status := "No save loaded yet."


func _ready() -> void:
	_connect_subsystem_signals()
	load_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func last_status() -> String:
	return _last_status


func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_path() -> String:
	return SAVE_PATH


func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_last_status = "Save failed: could not open save file."
		save_state_changed.emit()
		return false

	var payload := {
		"version": SAVE_VERSION,
		"profile": ProfileState.serialize_state(),
		"formation": FormationState.serialize_state(),
		"campaign": CampaignState.serialize_state(),
		"rewards": RewardState.serialize_state(),
		"summon": SummonState.serialize_state(),
		"quests": QuestState.serialize_state(),
		"events": EventState.serialize_state(),
		"settings": SettingsState.serialize_state(),
		"inventory": InventoryState.serialize_state(),
	}
	file.store_string(JSON.stringify(payload))
	_last_status = "Saved version %d to %s" % [SAVE_VERSION, SAVE_PATH]
	save_state_changed.emit()
	return true


func load_game() -> bool:
	_is_loading = true
	var loaded := false

	if FileAccess.file_exists(SAVE_PATH):
		loaded = _load_primary_save()
	elif _migrate_legacy_reward_save():
		loaded = true
		save_game()
	else:
		_last_status = "No save file found. Using default authored state."

	if loaded == false and FileAccess.file_exists(SAVE_PATH):
		reset_save(false)
		_last_status = "Save was missing or corrupt. Reset to default authored state."

	_is_loading = false
	save_state_changed.emit()
	return loaded


func reset_save(delete_file: bool = true) -> void:
	_is_loading = true
	ProfileState.reset_persistent_state()
	InventoryState.reset_persistent_state()
	CampaignState.reset_persistent_state()
	RewardState.reset_persistent_state()
	SummonState.reset_persistent_state()
	QuestState.reset_persistent_state()
	EventState.reset_persistent_state()
	SettingsState.reset_persistent_state()
	FormationState.reset_persistent_state()

	if delete_file and FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if delete_file and FileAccess.file_exists(RewardState.LEGACY_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RewardState.LEGACY_SAVE_PATH))

	_is_loading = false
	_last_status = "Reset all persistent state to defaults."
	save_state_changed.emit()
	if delete_file == false:
		save_game()


func _connect_subsystem_signals() -> void:
	if ProfileState.roster_changed.is_connected(_queue_save) == false:
		ProfileState.roster_changed.connect(_queue_save)
	if FormationState.formation_changed.is_connected(_queue_save) == false:
		FormationState.formation_changed.connect(_queue_save)
	if CampaignState.campaign_changed.is_connected(_queue_save) == false:
		CampaignState.campaign_changed.connect(_queue_save)
	if RewardState.rewards_changed.is_connected(_queue_save) == false:
		RewardState.rewards_changed.connect(_queue_save)
	if RewardState.afk_updated.is_connected(_queue_save) == false:
		RewardState.afk_updated.connect(_queue_save)
	if SummonState.summon_state_changed.is_connected(_queue_save) == false:
		SummonState.summon_state_changed.connect(_queue_save)
	if QuestState.quest_state_changed.is_connected(_queue_save) == false:
		QuestState.quest_state_changed.connect(_queue_save)
	if EventState.event_state_changed.is_connected(_queue_save) == false:
		EventState.event_state_changed.connect(_queue_save)
	if SettingsState.settings_changed.is_connected(_queue_save) == false:
		SettingsState.settings_changed.connect(_queue_save)
	if InventoryState.inventory_changed.is_connected(_queue_save) == false:
		InventoryState.inventory_changed.connect(_queue_save)


func _queue_save() -> void:
	if _is_loading:
		return
	if _save_queued:
		return
	_save_queued = true
	call_deferred("_flush_queued_save")


func _flush_queued_save() -> void:
	_save_queued = false
	if _is_loading:
		return
	save_game()


func _load_primary_save() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false

	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return false

	var data = parser.data
	if data is Dictionary == false:
		return false

	if int(data.get("version", 0)) > SAVE_VERSION:
		return false

	ProfileState.apply_state(data.get("profile", {}))
	InventoryState.apply_state(data.get("inventory", {}))
	RewardState.apply_state(data.get("rewards", {}))
	SummonState.apply_state(data.get("summon", {}))
	QuestState.apply_state(data.get("quests", {}))
	EventState.apply_state(data.get("events", {}))
	SettingsState.apply_state(data.get("settings", {}))
	CampaignState.apply_state(data.get("campaign", {}))
	FormationState.apply_state(data.get("formation", {}))
	_last_status = "Loaded save version %d." % int(data.get("version", 0))
	return true


func _migrate_legacy_reward_save() -> bool:
	var legacy_rewards: Dictionary = RewardState.load_legacy_state()
	if legacy_rewards.is_empty():
		return false

	RewardState.apply_state(legacy_rewards)
	_last_status = "Migrated legacy reward save into the unified save format."
	return true
