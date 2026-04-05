extends Node

signal rewards_changed
signal afk_updated
signal battle_rewards_granted(payload: Dictionary)
signal afk_rewards_claimed(payload: Dictionary)

const LEGACY_SAVE_PATH := "user://reward_state.json"
const AFK_CAP_SECONDS := 12 * 60 * 60
const DEFAULT_STAGE_ID := "chapter_01_stage_01"

var _gold := 0
var _hero_xp := 0
var _premium_shards := 0
var _banner_tokens_by_id: Dictionary = {}
var _last_afk_timestamp := 0
var _highest_stage_snapshot := DEFAULT_STAGE_ID
var _pending_afk_rewards := {"gold": 0, "hero_xp": 0, "elapsed_seconds": 0}
var _last_battle_rewards := {}
var _last_afk_claim_rewards := {}


func _ready() -> void:
	if GameData.data_reloaded.is_connected(_on_game_data_reloaded) == false:
		GameData.data_reloaded.connect(_on_game_data_reloaded)
	if CampaignState.campaign_changed.is_connected(_on_campaign_changed) == false:
		CampaignState.campaign_changed.connect(_on_campaign_changed)
	_sync_banner_tokens()
	_refresh_campaign_snapshot()
	refresh_afk_rewards()


func gold_balance() -> int:
	return _gold


func hero_xp_balance() -> int:
	return _hero_xp


func premium_shard_balance() -> int:
	return _premium_shards


func banner_token_balance(token_id: String) -> int:
	return int(_banner_tokens_by_id.get(token_id, 0))


func resource_balance(resource_id: String) -> int:
	match resource_id:
		"gold":
			return gold_balance()
		"hero_xp":
			return hero_xp_balance()
		"premium_shards":
			return premium_shard_balance()
		_:
			return banner_token_balance(resource_id)


func highest_stage_snapshot_id() -> String:
	return _highest_stage_snapshot


func current_afk_rewards() -> Dictionary:
	return _pending_afk_rewards.duplicate(true)


func last_battle_rewards() -> Dictionary:
	return _last_battle_rewards.duplicate(true)


func last_afk_claim_rewards() -> Dictionary:
	return _last_afk_claim_rewards.duplicate(true)


func balance_summary_lines() -> Array[String]:
	var lines: Array[String] = [
		"Gold: %d" % _gold,
		"Hero XP: %d" % _hero_xp,
		"Premium shards: %d" % _premium_shards,
		"AFK stage snapshot: %s" % _highest_stage_snapshot_label(),
	]
	lines.append_array(_banner_token_summary_lines())
	return lines


func has_resources(costs: Dictionary) -> bool:
	for resource_id in costs.keys():
		if resource_balance(String(resource_id)) < int(costs.get(resource_id, 0)):
			return false
	return true


func spend_resources(costs: Dictionary) -> bool:
	if has_resources(costs) == false:
		return false

	for resource_id in costs.keys():
		_adjust_resource(String(resource_id), -int(costs.get(resource_id, 0)))
	rewards_changed.emit()
	return true


func grant_resources(resources: Dictionary) -> Dictionary:
	for resource_id in resources.keys():
		_adjust_resource(String(resource_id), int(resources.get(resource_id, 0)))
	rewards_changed.emit()
	return resources.duplicate(true)


func grant_battle_rewards(source_type: String, stage_id: String, victory: bool) -> Dictionary:
	if victory == false:
		_last_battle_rewards = {
			"source_type": source_type,
			"stage_id": stage_id,
			"victory": false,
		}
		rewards_changed.emit()
		battle_rewards_granted.emit(_last_battle_rewards.duplicate(true))
		return _last_battle_rewards.duplicate(true)

	var reward_package := _battle_reward_package(source_type, stage_id)
	for resource_id in reward_package.keys():
		if ["source_type", "stage_id", "source_label"].has(String(resource_id)):
			continue
		_adjust_resource(String(resource_id), int(reward_package.get(resource_id, 0)))
	_last_battle_rewards = reward_package.duplicate(true)
	_last_battle_rewards["victory"] = true
	rewards_changed.emit()
	battle_rewards_granted.emit(_last_battle_rewards.duplicate(true))
	return _last_battle_rewards.duplicate(true)


func refresh_afk_rewards(emit_signal: bool = true) -> void:
	if _last_afk_timestamp <= 0:
		_last_afk_timestamp = _now_unix()

	var elapsed := clampi(_now_unix() - _last_afk_timestamp, 0, AFK_CAP_SECONDS)
	var hourly_rewards := _afk_hourly_rewards_for_snapshot()
	_pending_afk_rewards = {
		"gold": int(floor(float(hourly_rewards.get("gold", 0)) * float(elapsed) / 3600.0)),
		"hero_xp": int(floor(float(hourly_rewards.get("hero_xp", 0)) * float(elapsed) / 3600.0)),
		"elapsed_seconds": elapsed,
	}
	if emit_signal:
		afk_updated.emit()


func claim_afk_rewards() -> Dictionary:
	refresh_afk_rewards()
	_gold += int(_pending_afk_rewards.get("gold", 0))
	_hero_xp += int(_pending_afk_rewards.get("hero_xp", 0))
	_last_afk_claim_rewards = _pending_afk_rewards.duplicate(true)
	_last_afk_timestamp = _now_unix()
	_pending_afk_rewards = {"gold": 0, "hero_xp": 0, "elapsed_seconds": 0}
	rewards_changed.emit()
	afk_updated.emit()
	afk_rewards_claimed.emit(_last_afk_claim_rewards.duplicate(true))
	return _last_afk_claim_rewards.duplicate(true)


func reset_progress_for_testing() -> void:
	_gold = 0
	_hero_xp = 0
	_premium_shards = 0
	_sync_banner_tokens()
	_last_afk_timestamp = _now_unix()
	_highest_stage_snapshot = DEFAULT_STAGE_ID
	_pending_afk_rewards = {"gold": 0, "hero_xp": 0, "elapsed_seconds": 0}
	_last_battle_rewards = {}
	_last_afk_claim_rewards = {}
	rewards_changed.emit()
	afk_updated.emit()


func simulate_afk_elapsed(seconds: int) -> void:
	_last_afk_timestamp = maxi(0, _last_afk_timestamp - maxi(seconds, 0))
	refresh_afk_rewards()


func _on_game_data_reloaded() -> void:
	_refresh_campaign_snapshot()
	_sync_banner_tokens()


func _on_campaign_changed() -> void:
	_refresh_campaign_snapshot()


func _refresh_campaign_snapshot() -> void:
	var current_stage_id := CampaignState.highest_cleared_stage_id()
	if current_stage_id.is_empty():
		current_stage_id = DEFAULT_STAGE_ID

	if _stage_order_index(current_stage_id) >= _stage_order_index(_highest_stage_snapshot):
		_highest_stage_snapshot = current_stage_id
	refresh_afk_rewards(false)
	rewards_changed.emit()
	afk_updated.emit()


func serialize_state() -> Dictionary:
	return {
		"gold": _gold,
		"hero_xp": _hero_xp,
		"premium_shards": _premium_shards,
		"banner_tokens_by_id": _banner_tokens_by_id.duplicate(true),
		"last_afk_timestamp": _last_afk_timestamp,
		"highest_stage_snapshot": _highest_stage_snapshot,
		"last_battle_rewards": _last_battle_rewards.duplicate(true),
		"last_afk_claim_rewards": _last_afk_claim_rewards.duplicate(true),
	}


func apply_state(data: Dictionary) -> void:
	_gold = maxi(int(data.get("gold", 0)), 0)
	_hero_xp = maxi(int(data.get("hero_xp", 0)), 0)
	_premium_shards = maxi(int(data.get("premium_shards", 0)), 0)
	_banner_tokens_by_id.clear()
	for token_id in GameData.summon_currency_ids():
		_banner_tokens_by_id[token_id] = maxi(int(data.get("banner_tokens_by_id", {}).get(token_id, 0)), 0)
	_last_afk_timestamp = int(data.get("last_afk_timestamp", _now_unix()))
	_highest_stage_snapshot = String(data.get("highest_stage_snapshot", DEFAULT_STAGE_ID))
	if GameData.get_stage(_highest_stage_snapshot).is_empty():
		_highest_stage_snapshot = DEFAULT_STAGE_ID
	_last_battle_rewards = data.get("last_battle_rewards", {}).duplicate(true)
	_last_afk_claim_rewards = data.get("last_afk_claim_rewards", {}).duplicate(true)
	refresh_afk_rewards(false)
	rewards_changed.emit()
	afk_updated.emit()


func reset_persistent_state() -> void:
	_gold = 0
	_hero_xp = 0
	_premium_shards = 0
	_sync_banner_tokens()
	_last_afk_timestamp = _now_unix()
	_highest_stage_snapshot = DEFAULT_STAGE_ID
	_pending_afk_rewards = {"gold": 0, "hero_xp": 0, "elapsed_seconds": 0}
	_last_battle_rewards = {}
	_last_afk_claim_rewards = {}
	rewards_changed.emit()
	afk_updated.emit()


func load_legacy_state() -> Dictionary:
	_last_afk_timestamp = _now_unix()
	if FileAccess.file_exists(LEGACY_SAVE_PATH) == false:
		return {}

	var file := FileAccess.open(LEGACY_SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}

	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}

	var data = parser.data
	if data is Dictionary == false:
		return {}
	return data.duplicate(true)


func _battle_reward_package(source_type: String, stage_id: String) -> Dictionary:
	var reward_source: Dictionary = {}
	var rewards: Dictionary = {}
	var source_label := stage_id

	match source_type:
		"event_stage":
			reward_source = GameData.get_live_event_stage(stage_id) if stage_id.is_empty() == false else {}
			rewards = reward_source.get("battle_rewards", {})
			source_label = String(reward_source.get("display_name", stage_id))
		_:
			reward_source = GameData.get_stage(stage_id) if stage_id.is_empty() == false else {}
			rewards = reward_source.get("battle_rewards", {})
			source_label = String(reward_source.get("display_name", stage_id))

	if rewards.is_empty():
		var fallback_stage: Dictionary = GameData.get_stage(_highest_stage_snapshot)
		rewards = fallback_stage.get("battle_rewards", {"gold": 120, "hero_xp": 80})
		if source_label.is_empty():
			source_label = String(fallback_stage.get("display_name", stage_id))

	var payload: Dictionary = {
		"source_type": source_type,
		"stage_id": stage_id,
		"source_label": source_label,
	}
	for resource_id in rewards.keys():
		payload[String(resource_id)] = int(rewards.get(resource_id, 0))
	return payload


func _afk_hourly_rewards_for_snapshot() -> Dictionary:
	var stage: Dictionary = GameData.get_stage(_highest_stage_snapshot)
	var rewards: Dictionary = stage.get("afk_hourly", {})
	if rewards.is_empty():
		return {"gold": 90, "hero_xp": 55}
	return {
		"gold": int(rewards.get("gold", 0)),
		"hero_xp": int(rewards.get("hero_xp", 0)),
	}


func _highest_stage_snapshot_label() -> String:
	var stage: Dictionary = GameData.get_stage(_highest_stage_snapshot)
	if stage.is_empty():
		return _highest_stage_snapshot
	return String(stage.get("display_name", _highest_stage_snapshot))


func _stage_order_index(stage_id: String) -> int:
	var index := GameData.stage_ids().find(stage_id)
	return 0 if index == -1 else index


func _now_unix() -> int:
	return int(Time.get_unix_time_from_system())


func _adjust_resource(resource_id: String, delta: int) -> void:
	match resource_id:
		"gold":
			_gold = maxi(_gold + delta, 0)
		"hero_xp":
			_hero_xp = maxi(_hero_xp + delta, 0)
		"premium_shards":
			_premium_shards = maxi(_premium_shards + delta, 0)
		_:
			_banner_tokens_by_id[resource_id] = maxi(int(_banner_tokens_by_id.get(resource_id, 0)) + delta, 0)


func _sync_banner_tokens() -> void:
	var next_tokens: Dictionary = {}
	for token_id in GameData.summon_currency_ids():
		next_tokens[token_id] = maxi(int(_banner_tokens_by_id.get(token_id, 0)), 0)
	_banner_tokens_by_id = next_tokens


func _banner_token_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	for banner in GameData.get_all_summon_banners():
		var token_id := String(banner.get("currency_id", ""))
		if token_id.is_empty():
			continue
		lines.append("%s: %d" % [
			String(banner.get("currency_name", token_id)),
			banner_token_balance(token_id),
		])
	return lines
