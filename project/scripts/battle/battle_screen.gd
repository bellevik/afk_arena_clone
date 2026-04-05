extends ScrollContainer

const BattleBuilderScript := preload("res://project/scripts/battle/battle_builder.gd")
const BattleSimulatorScript := preload("res://project/scripts/battle/battle_simulator.gd")
const UNIT_CARD_SCENE := preload("res://project/scenes/battle/battle_unit_card.tscn")
const FIXED_STEP_SECONDS := 0.1
const SPEED_OPTIONS := [1.0, 2.0, 4.0]
const UNIT_CARD_SIZE := Vector2(152, 92)
const SLOT_LAYOUT := {
	"front_left": {"line": "Frontline", "label": "Front Left"},
	"front_right": {"line": "Frontline", "label": "Front Right"},
	"back_left": {"line": "Backline", "label": "Back Left"},
	"back_center": {"line": "Backline", "label": "Back Center"},
	"back_right": {"line": "Backline", "label": "Back Right"},
}
const SLOT_ORDER := ["front_left", "front_right", "back_left", "back_center", "back_right"]

var _simulator = null
var _battle_builder = null
var _encounter: Dictionary = {}
var _unit_cards: Dictionary = {}
var _slot_hosts: Dictionary = {}
var _metadata: Dictionary = {}
var _speed_index := 0
var _time_accumulator := 0.0
var _setup_note := ""
var _effect_banner_timer := 0.0
var _active_battle_source := "test"
var _active_stage_id := ""
var _active_event_id := ""
var _reported_campaign_result := false
var _reported_battle_rewards := false

@onready var encounter_title_label: Label = %EncounterTitleLabel
@onready var battle_state_label: Label = %BattleStateLabel
@onready var formation_summary_label: Label = %FormationSummaryLabel
@onready var restart_button: Button = %RestartButton
@onready var speed_button: Button = %SpeedButton
@onready var formation_button: Button = %FormationButton
@onready var effect_banner_panel: PanelContainer = %EffectBannerPanel
@onready var effect_banner_label: Label = %EffectBannerLabel
@onready var timer_label: Label = %TimerLabel
@onready var determinism_label: Label = %DeterminismLabel
@onready var modifier_summary_label: Label = %ModifierSummaryLabel
@onready var arena_rows: VBoxContainer = %ArenaRows
@onready var result_panel: PanelContainer = %ResultPanel
@onready var result_label: Label = %ResultLabel
@onready var result_detail_label: Label = %ResultDetailLabel
@onready var combat_log: RichTextLabel = %CombatLog


func _ready() -> void:
	_battle_builder = BattleBuilderScript.new()
	_build_arena_rows()
	restart_button.pressed.connect(_restart_battle)
	speed_button.pressed.connect(_cycle_speed)
	formation_button.pressed.connect(SceneRouter.go_to.bind("formation"))
	_update_speed_button()
	_prepare_and_start_battle()
	set_process(true)


func configure(metadata: Dictionary) -> void:
	_metadata = metadata.duplicate(true)


func _process(delta: float) -> void:
	if _effect_banner_timer > 0.0:
		_effect_banner_timer = maxf(0.0, _effect_banner_timer - delta)
		if _effect_banner_timer <= 0.0:
			effect_banner_panel.visible = false

	if _simulator == null or _simulator.is_finished():
		return

	_time_accumulator += delta * float(SPEED_OPTIONS[_speed_index])
	while _time_accumulator >= FIXED_STEP_SECONDS:
		_time_accumulator -= FIXED_STEP_SECONDS
		var events: Array[Dictionary] = _simulator.step(FIXED_STEP_SECONDS)
		_consume_events(events)
		_refresh_battle_view()
		if _simulator.is_finished():
			break


func debug_snapshot() -> Dictionary:
	if _simulator == null:
		return {}
	return {
		"encounter_id": String(_encounter.get("encounter_id", "")),
		"result_state": _simulator.result_state(),
		"winner_team": _simulator.winner_team(),
		"player_alive": _simulator.team_alive_count(BattleSimulatorScript.TEAM_PLAYER),
		"enemy_alive": _simulator.team_alive_count(BattleSimulatorScript.TEAM_ENEMY),
		"log_entries": _simulator.combat_log().size(),
	}


func _prepare_and_start_battle() -> void:
	_setup_note = ""
	_effect_banner_timer = 0.0
	effect_banner_panel.visible = false
	_reported_campaign_result = false
	_reported_battle_rewards = false
	if FormationState.assigned_count() == 0:
		FormationState.auto_fill()
		_setup_note = "No formation was assigned, so the battle screen auto-filled the current team for testing."

	var stage_battle: Dictionary = EventState.pending_battle_definition()
	if stage_battle.is_empty() and _active_battle_source == "event_stage" and _active_stage_id.is_empty() == false:
		var event_stage: Dictionary = GameData.get_live_event_stage(_active_stage_id)
		if event_stage.is_empty() == false:
			stage_battle = {
				"battle_id": String(event_stage.get("stage_id", "")),
				"display_name": String(event_stage.get("display_name", "")),
				"description": String(event_stage.get("description", "")),
				"duration_seconds": float(event_stage.get("duration_seconds", 60.0)),
				"modifiers": event_stage.get("modifiers", []).duplicate(true),
				"enemy_team": event_stage.get("enemy_team", []).duplicate(true),
				"source_type": "event_stage",
				"source_path": String(event_stage.get("source_path", "")),
			}

	if stage_battle.is_empty():
		stage_battle = CampaignState.pending_battle_definition()
	if stage_battle.is_empty() and _active_battle_source == "campaign_stage" and _active_stage_id.is_empty() == false:
		var stage: Dictionary = GameData.get_stage(_active_stage_id)
		if stage.is_empty() == false:
			stage_battle = {
				"battle_id": String(stage.get("stage_id", "")),
				"display_name": String(stage.get("display_name", "")),
				"description": String(stage.get("description", "")),
				"duration_seconds": float(stage.get("duration_seconds", 60.0)),
				"enemy_team": stage.get("enemy_team", []).duplicate(true),
				"source_type": "campaign_stage",
				"source_path": String(stage.get("source_path", "")),
			}

	if stage_battle.is_empty() == false:
		_encounter = stage_battle
		_active_battle_source = String(stage_battle.get("source_type", "campaign_stage"))
		_active_stage_id = String(stage_battle.get("battle_id", ""))
		_active_event_id = String(GameData.get_live_event_stage(_active_stage_id).get("event_id", ""))
	else:
		_encounter = _battle_builder.default_battle_encounter()
		_active_battle_source = "test"
		_active_stage_id = ""
		_active_event_id = ""

	if _encounter.is_empty():
		_show_load_error("No battle encounter data is available.")
		return

	var battle_context := {
		"modifiers": _encounter.get("modifiers", []).duplicate(true),
	}
	var player_units: Array[Dictionary] = _battle_builder.build_player_team_from_formation(battle_context)
	var enemy_units: Array[Dictionary] = _battle_builder.build_enemy_team_from_encounter(_encounter, battle_context)
	if player_units.is_empty():
		_show_load_error("The active formation has no heroes assigned.")
		return
	if enemy_units.is_empty():
		_show_load_error("The selected encounter has no enemies assigned.")
		return

	_simulator = BattleSimulatorScript.new()
	_simulator.setup(player_units, enemy_units, {
		"duration_seconds": float(_encounter.get("duration_seconds", 60.0)),
	})
	_time_accumulator = 0.0

	_build_unit_cards(_simulator.units())
	_refresh_battle_view()


func _show_load_error(message: String) -> void:
	encounter_title_label.text = "Battle Unavailable"
	battle_state_label.text = message
	formation_summary_label.text = "Open Formation to assign heroes, then return here."
	timer_label.text = "Timer: --"
	determinism_label.text = "Deterministic combat is unavailable until a valid encounter loads."
	result_panel.visible = true
	result_label.text = "Setup Error"
	result_detail_label.text = message
	combat_log.clear()
	combat_log.append_text(message)
	set_process(false)


func _restart_battle() -> void:
	set_process(true)
	_prepare_and_start_battle()


func _cycle_speed() -> void:
	_speed_index = (_speed_index + 1) % SPEED_OPTIONS.size()
	_update_speed_button()


func _update_speed_button() -> void:
	speed_button.text = "Speed %sx" % str(SPEED_OPTIONS[_speed_index]).trim_suffix(".0")


func _build_unit_cards(units: Array[Dictionary]) -> void:
	for host_key in _slot_hosts.keys():
		var host: VBoxContainer = _slot_hosts[host_key]
		for child in host.get_children():
			child.queue_free()
	_unit_cards.clear()

	for snapshot in units:
		var card := UNIT_CARD_SCENE.instantiate()
		card.custom_minimum_size = UNIT_CARD_SIZE
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var host_key := _slot_host_key(String(snapshot.get("team", "")), String(snapshot.get("slot_id", "")))
		var host: VBoxContainer = _slot_hosts.get(host_key)
		if host != null:
			host.add_child(card)
			card.sync(snapshot)
			_unit_cards[String(snapshot.get("unit_id", ""))] = card


func _refresh_battle_view() -> void:
	if _simulator == null:
		return

	var player_units: Array[Dictionary] = []
	var enemy_units: Array[Dictionary] = []
	var snapshots: Array[Dictionary] = _simulator.units()
	for snapshot in snapshots:
		if String(snapshot.get("team", "")) == BattleSimulatorScript.TEAM_PLAYER:
			player_units.append(snapshot)
		else:
			enemy_units.append(snapshot)

	for snapshot in snapshots:
		var card = _unit_cards.get(String(snapshot.get("unit_id", "")))
		if card != null:
			card.sync(snapshot)

	encounter_title_label.text = "%s" % String(_encounter.get("display_name", "Battle Test"))
	battle_state_label.text = "%s\n%s" % [
		String(_encounter.get("description", "")),
		_setup_note if _setup_note.is_empty() == false else "Simulation state updates in real time and resolves without manual input.",
	]
	formation_summary_label.text = "%s\n%s" % [
		_battle_builder.build_player_summary_line(player_units),
		_battle_builder.build_enemy_summary_line(enemy_units),
	]
	timer_label.text = "Timer: %.1fs  |  Player alive: %d  |  Enemy alive: %d" % [
		snappedf(_simulator.remaining_seconds(), 0.1),
		_simulator.team_alive_count(BattleSimulatorScript.TEAM_PLAYER),
		_simulator.team_alive_count(BattleSimulatorScript.TEAM_ENEMY),
	]
	determinism_label.text = "Deterministic battle. Energy, shields, heals, hero ultimates, and enemy ultimates are active. No crit RNG, dodge RNG, or seed variance yet."
	var modifier_lines := GameData.event_modifier_summary_lines(_encounter.get("modifiers", []))
	if modifier_lines.is_empty():
		modifier_summary_label.text = "Stage modifiers: none"
	else:
		modifier_summary_label.text = "Stage modifiers:\n%s" % "\n".join(modifier_lines)

	result_panel.visible = _simulator.is_finished()
	if _simulator.is_finished():
		_report_battle_source_result_if_needed()
		var reward_snapshot := _report_battle_rewards_if_needed()
		result_label.text = _simulator.result_label()
		result_detail_label.text = "Result: %s  |  Winner: %s  |  Elapsed: %.1fs" % [
			_simulator.result_state(),
			_simulator.winner_team(),
			snappedf(_simulator.elapsed_seconds(), 0.1),
		]
		if _simulator.skill_cast_count() > 0:
			result_detail_label.text += "\nUltimates cast: %d  |  Healing: %d  |  Shields: %d" % [
				_simulator.skill_cast_count(),
				_simulator.healing_done(),
				_simulator.shielding_done(),
			]
		result_detail_label.text += "\nRewards: %s" % _reward_summary(reward_snapshot)

	combat_log.clear()
	combat_log.append_text("\n".join(_simulator.combat_log()))
	combat_log.scroll_to_line(maxi(_simulator.combat_log().size() - 1, 0))


func _build_arena_rows() -> void:
	for child in arena_rows.get_children():
		child.queue_free()
	_slot_hosts.clear()

	for slot_id in SLOT_ORDER:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 12)
		arena_rows.add_child(row)

		var player_host := VBoxContainer.new()
		player_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(player_host)
		_slot_hosts[_slot_host_key(BattleSimulatorScript.TEAM_PLAYER, slot_id)] = player_host

		var center_panel := PanelContainer.new()
		center_panel.custom_minimum_size = Vector2(160.0, 0.0)
		row.add_child(center_panel)

		var center_margin := MarginContainer.new()
		center_margin.add_theme_constant_override("margin_left", 14)
		center_margin.add_theme_constant_override("margin_top", 10)
		center_margin.add_theme_constant_override("margin_right", 14)
		center_margin.add_theme_constant_override("margin_bottom", 10)
		center_panel.add_child(center_margin)

		var center_stack := VBoxContainer.new()
		center_stack.add_theme_constant_override("separation", 4)
		center_margin.add_child(center_stack)

		var lane_label := Label.new()
		lane_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lane_label.text = String(SLOT_LAYOUT.get(slot_id, {}).get("line", "Lane"))
		center_stack.add_child(lane_label)

		var slot_label := Label.new()
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot_label.text = String(SLOT_LAYOUT.get(slot_id, {}).get("label", slot_id))
		center_stack.add_child(slot_label)

		var enemy_host := VBoxContainer.new()
		enemy_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(enemy_host)
		_slot_hosts[_slot_host_key(BattleSimulatorScript.TEAM_ENEMY, slot_id)] = enemy_host


func _slot_host_key(team: String, slot_id: String) -> String:
	return "%s:%s" % [team, slot_id]


func _consume_events(events: Array[Dictionary]) -> void:
	for event in events:
		if String(event.get("type", "")) != "skill_cast":
			continue
		effect_banner_panel.visible = true
		effect_banner_label.text = "%s used %s" % [
			String(event.get("caster_name", "Unit")),
			String(event.get("skill_name", "Ultimate")),
		]
		_effect_banner_timer = 1.2


func _report_battle_source_result_if_needed() -> void:
	if _reported_campaign_result:
		return
	if _active_stage_id.is_empty():
		return
	var victory: bool = _simulator.winner_team() == BattleSimulatorScript.TEAM_PLAYER
	match _active_battle_source:
		"campaign_stage":
			CampaignState.report_battle_result(victory)
		"event_stage":
			EventState.report_battle_result(victory)
	_reported_campaign_result = true


func _report_battle_rewards_if_needed() -> Dictionary:
	if _reported_battle_rewards:
		return RewardState.last_battle_rewards()
	if _simulator == null:
		return {}

	var rewards := RewardState.grant_battle_rewards(
		_active_battle_source,
		_active_stage_id,
		_simulator.winner_team() == BattleSimulatorScript.TEAM_PLAYER
	)
	_reported_battle_rewards = true
	return rewards


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
