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

@onready var encounter_title_label: Label = %EncounterTitleLabel
@onready var battle_state_label: Label = %BattleStateLabel
@onready var formation_summary_label: Label = %FormationSummaryLabel
@onready var restart_button: Button = %RestartButton
@onready var speed_button: Button = %SpeedButton
@onready var formation_button: Button = %FormationButton
@onready var timer_label: Label = %TimerLabel
@onready var determinism_label: Label = %DeterminismLabel
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
	if _simulator == null or _simulator.is_finished():
		return

	_time_accumulator += delta * float(SPEED_OPTIONS[_speed_index])
	while _time_accumulator >= FIXED_STEP_SECONDS:
		_time_accumulator -= FIXED_STEP_SECONDS
		_simulator.step(FIXED_STEP_SECONDS)
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
	if FormationState.assigned_count() == 0:
		FormationState.auto_fill()
		_setup_note = "No formation was assigned, so the battle screen auto-filled the current team for testing."

	_encounter = _battle_builder.default_battle_encounter()
	if _encounter.is_empty():
		_show_load_error("No battle encounter data is available.")
		return

	var player_units: Array[Dictionary] = _battle_builder.build_player_team_from_formation()
	var enemy_units: Array[Dictionary] = _battle_builder.build_enemy_team_from_encounter(_encounter)
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
	determinism_label.text = "Deterministic Phase 4 battle. No crit RNG, dodge RNG, or seed variance yet."

	result_panel.visible = _simulator.is_finished()
	if _simulator.is_finished():
		result_label.text = _simulator.result_label()
		result_detail_label.text = "Result: %s  |  Winner: %s  |  Elapsed: %.1fs" % [
			_simulator.result_state(),
			_simulator.winner_team(),
			snappedf(_simulator.elapsed_seconds(), 0.1),
		]

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
