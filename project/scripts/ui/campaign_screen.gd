extends ScrollContainer

var _stage_buttons: Dictionary = {}

@onready var summary_label: Label = %SummaryLabel
@onready var result_label: Label = %ResultLabel
@onready var selected_stage_label: Label = %SelectedStageLabel
@onready var selected_stage_description_label: Label = %SelectedStageDescriptionLabel
@onready var selected_stage_meta_label: Label = %SelectedStageMetaLabel
@onready var selected_stage_enemy_label: Label = %SelectedStageEnemyLabel
@onready var launch_button: Button = %LaunchButton
@onready var stage_list: VBoxContainer = %StageList


func _ready() -> void:
	launch_button.pressed.connect(_on_launch_pressed)
	if CampaignState.campaign_changed.is_connected(_refresh_screen) == false:
		CampaignState.campaign_changed.connect(_refresh_screen)
	_refresh_screen()


func configure(_metadata: Dictionary) -> void:
	pass


func _refresh_screen() -> void:
	summary_label.text = "\n".join(CampaignState.stage_progress_summary())
	_refresh_last_result()
	_rebuild_stage_list()
	_refresh_selected_stage()


func _refresh_last_result() -> void:
	var result: Dictionary = CampaignState.last_battle_result()
	if result.is_empty():
		result_label.text = "No campaign battle has been completed this session yet."
		return

	var stage: Dictionary = GameData.get_stage(String(result.get("stage_id", "")))
	var stage_name := String(stage.get("display_name", result.get("stage_id", "")))
	var outcome := "Victory" if bool(result.get("victory", false)) else "Defeat"
	result_label.text = "Last campaign result: %s on %s" % [outcome, stage_name]


func _rebuild_stage_list() -> void:
	for child in stage_list.get_children():
		child.queue_free()
	_stage_buttons.clear()

	for entry in CampaignState.stage_entries():
		var stage: Dictionary = entry.get("stage", {})
		if stage.is_empty():
			continue

		var stage_id := String(stage.get("stage_id", ""))
		var button := Button.new()
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0.0, 112.0)
		button.button_pressed = bool(entry.get("is_selected", false))
		button.disabled = bool(entry.get("is_unlocked", false)) == false
		button.text = "%s\nRecommended power %d  |  %s" % [
			String(stage.get("display_name", stage_id)),
			int(stage.get("recommended_power", 0)),
			_stage_state_label(entry),
		]
		button.pressed.connect(_on_stage_pressed.bind(stage_id))
		stage_list.add_child(button)
		_stage_buttons[stage_id] = button


func _refresh_selected_stage() -> void:
	var stage: Dictionary = GameData.get_stage(CampaignState.selected_stage_id())
	if stage.is_empty():
		selected_stage_label.text = "No stage selected"
		selected_stage_description_label.text = ""
		selected_stage_meta_label.text = ""
		selected_stage_enemy_label.text = ""
		launch_button.disabled = true
		return

	selected_stage_label.text = String(stage.get("display_name", "Stage"))
	selected_stage_description_label.text = String(stage.get("description", ""))
	selected_stage_meta_label.text = "Recommended power: %d\nDuration: %.0fs\nStatus: %s" % [
		int(stage.get("recommended_power", 0)),
		float(stage.get("duration_seconds", 60.0)),
		"Cleared" if CampaignState.is_stage_cleared(String(stage.get("stage_id", ""))) else "Uncleared",
	]
	selected_stage_enemy_label.text = "Enemy lineup:\n%s" % _enemy_line_summary(stage)
	launch_button.disabled = CampaignState.can_launch_selected_stage() == false
	launch_button.text = "Launch %s" % String(stage.get("display_name", "Stage"))


func _enemy_line_summary(stage: Dictionary) -> String:
	var lines: Array[String] = []
	for entry in stage.get("enemy_team", []):
		if entry is Dictionary == false:
			continue
		var enemy: Dictionary = GameData.get_enemy(String(entry.get("enemy_id", "")))
		lines.append("%s  Lv.%d  [%s]" % [
			String(enemy.get("display_name", entry.get("enemy_id", "Enemy"))),
			int(entry.get("level", 1)),
			String(entry.get("slot_id", "")),
		])
	return "\n".join(lines)


func _stage_state_label(entry: Dictionary) -> String:
	if bool(entry.get("is_cleared", false)):
		return "Cleared"
	if bool(entry.get("is_unlocked", false)):
		return "Unlocked"
	return "Locked"


func _on_stage_pressed(stage_id: String) -> void:
	CampaignState.select_stage(stage_id)
	_refresh_selected_stage()


func _on_launch_pressed() -> void:
	if CampaignState.begin_stage_battle(CampaignState.selected_stage_id()) == false:
		return
	SceneRouter.go_to("battle")
