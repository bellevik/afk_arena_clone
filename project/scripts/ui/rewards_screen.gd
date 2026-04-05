extends ScrollContainer

const DEBUG_AFK_SECONDS := 2 * 60 * 60

@onready var balance_label: Label = %BalanceLabel
@onready var afk_label: Label = %AfkLabel
@onready var claim_button: Button = %ClaimButton
@onready var refresh_button: Button = %RefreshButton
@onready var simulate_button: Button = %SimulateButton
@onready var battle_reward_label: Label = %BattleRewardLabel
@onready var afk_claim_label: Label = %AfkClaimLabel


func _ready() -> void:
	claim_button.pressed.connect(_on_claim_pressed)
	refresh_button.pressed.connect(_refresh_screen)
	simulate_button.pressed.connect(_on_simulate_pressed)
	if RewardState.rewards_changed.is_connected(_refresh_screen) == false:
		RewardState.rewards_changed.connect(_refresh_screen)
	if RewardState.afk_updated.is_connected(_refresh_screen) == false:
		RewardState.afk_updated.connect(_refresh_screen)
	_refresh_screen()


func configure(_metadata: Dictionary) -> void:
	pass


func debug_snapshot() -> Dictionary:
	var afk_rewards := RewardState.current_afk_rewards()
	return {
		"gold": RewardState.gold_balance(),
		"hero_xp": RewardState.hero_xp_balance(),
		"pending_afk_gold": int(afk_rewards.get("gold", 0)),
		"pending_afk_hero_xp": int(afk_rewards.get("hero_xp", 0)),
		"highest_stage_snapshot": RewardState.highest_stage_snapshot_id(),
	}


func _refresh_screen() -> void:
	RewardState.refresh_afk_rewards(false)
	var afk_rewards := RewardState.current_afk_rewards()
	var snapshot_stage: Dictionary = GameData.get_stage(RewardState.highest_stage_snapshot_id())
	var snapshot_label := String(snapshot_stage.get("display_name", RewardState.highest_stage_snapshot_id()))
	var afk_hourly: Dictionary = snapshot_stage.get("afk_hourly", {"gold": 0, "hero_xp": 0})

	balance_label.text = "%s\nHighest cleared stage: %s\nCleared campaign stages: %d" % [
		"\n".join(RewardState.balance_summary_lines()),
		snapshot_label,
		CampaignState.cleared_stage_ids().size(),
	]
	afk_label.text = "Stored time: %s\nPending claim: %d gold  |  %d hero XP\nHourly rate: %d gold  |  %d hero XP" % [
		_format_elapsed(int(afk_rewards.get("elapsed_seconds", 0))),
		int(afk_rewards.get("gold", 0)),
		int(afk_rewards.get("hero_xp", 0)),
		int(afk_hourly.get("gold", 0)),
		int(afk_hourly.get("hero_xp", 0)),
	]
	claim_button.disabled = int(afk_rewards.get("gold", 0)) <= 0 and int(afk_rewards.get("hero_xp", 0)) <= 0

	var last_battle_rewards := RewardState.last_battle_rewards()
	if last_battle_rewards.is_empty():
		battle_reward_label.text = "No battle rewards recorded this session yet."
	else:
		var source_label := String(last_battle_rewards.get("source_label", last_battle_rewards.get("stage_id", "Battle")))
		battle_reward_label.text = "Last battle: %s\nOutcome: %s\nGranted: %s" % [
			source_label,
			"Victory" if bool(last_battle_rewards.get("victory", false)) else "Defeat",
			_reward_summary(last_battle_rewards),
		]

	var last_afk_claim := RewardState.last_afk_claim_rewards()
	if last_afk_claim.is_empty():
		afk_claim_label.text = "No AFK rewards have been claimed yet."
	else:
		afk_claim_label.text = "Last AFK claim: %s\nCollected: %d gold  |  %d hero XP" % [
			_format_elapsed(int(last_afk_claim.get("elapsed_seconds", 0))),
			int(last_afk_claim.get("gold", 0)),
			int(last_afk_claim.get("hero_xp", 0)),
		]


func _on_claim_pressed() -> void:
	RewardState.claim_afk_rewards()


func _on_simulate_pressed() -> void:
	RewardState.simulate_afk_elapsed(DEBUG_AFK_SECONDS)


func _format_elapsed(total_seconds: int) -> String:
	var hours := total_seconds / 3600
	var minutes := (total_seconds % 3600) / 60
	return "%dh %dm" % [hours, minutes]


func _reward_summary(rewards: Dictionary) -> String:
	var parts: Array[String] = []
	for resource_id in rewards.keys():
		var key := String(resource_id)
		if ["source_type", "stage_id", "source_label", "victory"].has(key):
			continue
		var amount := int(rewards.get(key, 0))
		if amount <= 0:
			continue
		match key:
			"gold":
				parts.append("%d gold" % amount)
			"hero_xp":
				parts.append("%d hero XP" % amount)
			"premium_shards":
				parts.append("%d premium shards" % amount)
			_:
				parts.append("%d %s" % [amount, _resource_label(key)])
	return " | ".join(parts)


func _resource_label(resource_id: String) -> String:
	for banner in GameData.get_all_summon_banners():
		if String(banner.get("currency_id", "")) == resource_id:
			return String(banner.get("currency_name", resource_id))
	return resource_id
