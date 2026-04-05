extends Node

signal summon_state_changed
signal summon_completed(payload: Dictionary)

var _selected_banner_id: String = ""
var _pity_counters: Dictionary = {}
var _last_results: Array[Dictionary] = []
var _total_pulls := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if GameData.data_reloaded.is_connected(_on_game_data_reloaded) == false:
		GameData.data_reloaded.connect(_on_game_data_reloaded)
	_rng.randomize()
	_sync_banner_state()


func banner_ids() -> Array[String]:
	return GameData.summon_banner_ids()


func selected_banner_id() -> String:
	return _selected_banner_id


func selected_banner() -> Dictionary:
	return GameData.get_summon_banner(_selected_banner_id)


func last_results() -> Array[Dictionary]:
	return _last_results.duplicate(true)


func total_pulls() -> int:
	return _total_pulls


func pity_count_for_banner(banner_id: String) -> int:
	return int(_pity_counters.get(banner_id, 0))


func can_pull_banner(banner_id: String, pull_count: int) -> bool:
	var banner: Dictionary = GameData.get_summon_banner(banner_id)
	if banner.is_empty():
		return false
	return RewardState.has_resources(_cost_for_pull_count(banner, pull_count))


func can_exchange_selected_banner(pull_count: int) -> bool:
	var banner: Dictionary = selected_banner()
	if banner.is_empty():
		return false
	return RewardState.has_resources(_exchange_cost_for_pull_count(banner, pull_count))


func select_banner(banner_id: String) -> void:
	if GameData.get_summon_banner(banner_id).is_empty():
		return
	_selected_banner_id = banner_id
	summon_state_changed.emit()


func perform_pull(pull_count: int = 1) -> Dictionary:
	var banner: Dictionary = selected_banner()
	if banner.is_empty():
		return {"ok": false, "reason": "missing_banner"}

	var resolved_pull_count := 10 if pull_count >= 10 else 1
	var cost := _cost_for_pull_count(banner, resolved_pull_count)
	if RewardState.spend_resources(cost) == false:
		return {
			"ok": false,
			"reason": "insufficient_currency",
			"cost": cost.duplicate(true),
		}

	var results: Array[Dictionary] = []
	for _i in resolved_pull_count:
		results.append(_roll_banner_result(banner))

	_last_results = results.duplicate(true)
	_total_pulls += resolved_pull_count
	summon_state_changed.emit()
	var payload := {
		"ok": true,
		"banner_id": String(banner.get("banner_id", "")),
		"pull_count": resolved_pull_count,
		"cost": cost.duplicate(true),
		"results": results.duplicate(true),
	}
	summon_completed.emit(payload.duplicate(true))
	return payload


func exchange_selected_banner_currency(pull_count: int) -> Dictionary:
	var banner: Dictionary = selected_banner()
	if banner.is_empty():
		return {"ok": false, "reason": "missing_banner"}

	var resolved_pull_count := 10 if pull_count >= 10 else 1
	var shard_cost := _exchange_cost_for_pull_count(banner, resolved_pull_count)
	if RewardState.spend_resources(shard_cost) == false:
		return {
			"ok": false,
			"reason": "insufficient_premium_shards",
			"cost": shard_cost.duplicate(true),
		}

	var granted := _cost_for_pull_count(banner, resolved_pull_count)
	RewardState.grant_resources(granted)
	summon_state_changed.emit()
	return {
		"ok": true,
		"banner_id": String(banner.get("banner_id", "")),
		"pull_count": resolved_pull_count,
		"spent": shard_cost.duplicate(true),
		"granted": granted.duplicate(true),
	}


func serialize_state() -> Dictionary:
	return {
		"selected_banner_id": _selected_banner_id,
		"pity_counters": _pity_counters.duplicate(true),
		"last_results": _last_results.duplicate(true),
		"total_pulls": _total_pulls,
	}


func apply_state(data: Dictionary) -> void:
	_selected_banner_id = String(data.get("selected_banner_id", ""))
	_pity_counters.clear()
	for banner_id in GameData.summon_banner_ids():
		_pity_counters[banner_id] = maxi(int(data.get("pity_counters", {}).get(banner_id, 0)), 0)
	_last_results.clear()
	for entry in data.get("last_results", []):
		if entry is Dictionary:
			_last_results.append(entry.duplicate(true))
	_total_pulls = maxi(int(data.get("total_pulls", 0)), 0)
	_sync_banner_state()


func reset_persistent_state() -> void:
	_selected_banner_id = ""
	_pity_counters.clear()
	_last_results.clear()
	_total_pulls = 0
	_sync_banner_state()


func debug_seed_rng(seed: int) -> void:
	_rng.seed = seed


func _on_game_data_reloaded() -> void:
	_sync_banner_state()


func _sync_banner_state() -> void:
	var next_pity: Dictionary = {}
	for banner_id in GameData.summon_banner_ids():
		next_pity[banner_id] = maxi(int(_pity_counters.get(banner_id, 0)), 0)
	_pity_counters = next_pity

	if GameData.get_summon_banner(_selected_banner_id).is_empty():
		_selected_banner_id = GameData.default_summon_banner_id()

	summon_state_changed.emit()


func _cost_for_pull_count(banner: Dictionary, pull_count: int) -> Dictionary:
	var currency_id := String(banner.get("currency_id", ""))
	if pull_count >= 10:
		return {currency_id: int(banner.get("cost_currency_ten_pull", 0))}
	return {currency_id: int(banner.get("cost_currency", 0))}


func _exchange_cost_for_pull_count(banner: Dictionary, pull_count: int) -> Dictionary:
	if pull_count >= 10:
		return {"premium_shards": int(banner.get("exchange_shards_ten_pull", 0))}
	return {"premium_shards": int(banner.get("exchange_shards_single", 0))}


func _roll_banner_result(banner: Dictionary) -> Dictionary:
	var banner_id := String(banner.get("banner_id", ""))
	var pity_before := pity_count_for_banner(banner_id)
	var pity_threshold := maxi(int(banner.get("pity_threshold", 10)), 1)
	var guarantee_legendary := pity_before + 1 >= pity_threshold
	var rarity := _roll_rarity(banner, guarantee_legendary)
	var hero_id := _roll_hero_id_for_rarity(banner, rarity)
	var hero: Dictionary = GameData.get_hero(hero_id)
	var featured_ids: Array[String] = banner.get("featured_hero_ids", [])
	var is_featured := featured_ids.has(hero_id)
	var reward_result := ProfileState.award_summoned_hero(hero_id)

	var result := {
		"hero_id": hero_id,
		"display_name": String(hero.get("display_name", hero_id)),
		"rarity": rarity,
		"is_featured": is_featured,
		"star_rank": int(reward_result.get("star_rank", ProfileState.hero_star_rank(hero_id))),
		"was_converted": bool(reward_result.get("converted", false)),
		"bonus_gold": int(reward_result.get("bonus_gold", 0)),
		"bonus_hero_xp": int(reward_result.get("bonus_hero_xp", 0)),
	}

	if rarity == "Legendary":
		_pity_counters[banner_id] = 0
	else:
		_pity_counters[banner_id] = pity_before + 1

	return result


func _roll_rarity(banner: Dictionary, guarantee_legendary: bool) -> String:
	if guarantee_legendary:
		return "Legendary"

	var weights: Dictionary = banner.get("rarity_weights", {})
	var total_weight := maxi(
		int(weights.get("Legendary", 0)) + int(weights.get("Elite", 0)) + int(weights.get("Rare", 0)),
		1
	)
	var roll := _rng.randi_range(1, total_weight)
	var threshold := int(weights.get("Legendary", 0))
	if roll <= threshold:
		return "Legendary"
	threshold += int(weights.get("Elite", 0))
	if roll <= threshold:
		return "Elite"
	return "Rare"


func _roll_hero_id_for_rarity(banner: Dictionary, rarity: String) -> String:
	var pool: Array[String] = []
	for hero_id in GameData.hero_ids():
		var hero: Dictionary = GameData.get_hero(hero_id)
		if String(hero.get("rarity", "")) == rarity:
			pool.append(hero_id)

	if pool.is_empty():
		var hero_ids := GameData.hero_ids()
		return "" if hero_ids.is_empty() else hero_ids[0]

	var weighted_pool: Array[String] = []
	var featured_ids: Array[String] = banner.get("featured_hero_ids", [])
	var bonus_weight := maxi(int(banner.get("featured_bonus_weight", 1)), 1)
	for hero_id in pool:
		weighted_pool.append(hero_id)
		if featured_ids.has(hero_id):
			for _i in bonus_weight:
				weighted_pool.append(hero_id)

	return weighted_pool[_rng.randi_range(0, weighted_pool.size() - 1)]
