extends ScrollContainer

var _status_message := ""

@onready var summary_label: Label = %SummaryLabel
@onready var timer_label: Label = %TimerLabel
@onready var open_banner_button: Button = %OpenBannerButton
@onready var status_label: Label = %StatusLabel
@onready var event_list: VBoxContainer = %EventList
@onready var source_list: Label = %SourceList
@onready var stage_list: VBoxContainer = %StageList
@onready var selected_stage_label: Label = %SelectedStageLabel
@onready var selected_stage_description_label: Label = %SelectedStageDescriptionLabel
@onready var selected_stage_meta_label: Label = %SelectedStageMetaLabel
@onready var selected_stage_modifier_label: Label = %SelectedStageModifierLabel
@onready var selected_stage_enemy_label: Label = %SelectedStageEnemyLabel
@onready var launch_stage_button: Button = %LaunchStageButton
@onready var milestone_list: VBoxContainer = %MilestoneList


func _ready() -> void:
	open_banner_button.pressed.connect(_on_open_banner_pressed)
	launch_stage_button.pressed.connect(_on_launch_stage_pressed)
	if EventState.event_state_changed.is_connected(_refresh_screen) == false:
		EventState.event_state_changed.connect(_refresh_screen)
	if RewardState.rewards_changed.is_connected(_refresh_screen) == false:
		RewardState.rewards_changed.connect(_refresh_screen)
	_refresh_screen()


func configure(_metadata: Dictionary) -> void:
	pass


func _refresh_screen() -> void:
	_rebuild_event_selector()
	var event: Dictionary = EventState.selected_event()
	if event.is_empty():
		summary_label.text = "No live event is currently authored."
		timer_label.text = "The event route is ready for future live-ops content."
		status_label.text = ""
		source_list.text = ""
		open_banner_button.disabled = true
		open_banner_button.text = "No linked banner"
		_clear_stage_list()
		selected_stage_label.text = "No event stage selected"
		selected_stage_description_label.text = ""
		selected_stage_meta_label.text = ""
		selected_stage_modifier_label.text = ""
		selected_stage_enemy_label.text = ""
		launch_stage_button.disabled = true
		_clear_milestones()
		return

	var event_id := String(event.get("event_id", ""))
	summary_label.text = "%s\nPremium shards: %d  |  Gold: %d  |  Hero XP: %d" % [
		"\n".join(EventState.event_summary_lines(event_id)),
		RewardState.premium_shard_balance(),
		RewardState.gold_balance(),
		RewardState.hero_xp_balance(),
	]
	timer_label.text = "Milestones claimed: %d / %d" % [
		_claimed_milestone_count(event_id),
		EventState.milestone_entries(event_id).size(),
	]
	status_label.text = "Push campaign, summons, AFK, and quests to climb the live event track." if _status_message.is_empty() else _status_message

	var banner_id := EventState.linked_banner_id_for_event(event_id)
	var linked_banner: Dictionary = GameData.get_summon_banner(banner_id)
	open_banner_button.disabled = banner_id.is_empty()
	open_banner_button.text = "Open linked banner: %s" % String(linked_banner.get("display_name", banner_id if banner_id.is_empty() == false else "None"))

	var source_lines: Array[String] = []
	for source in EventState.point_source_entries(event_id):
		source_lines.append("%s  |  +%d points" % [
			String(source.get("label", "Source")),
			int(source.get("points", 0)),
		])
	source_list.text = "\n".join(source_lines)
	_rebuild_stage_list(event_id)
	_refresh_selected_stage(event_id)
	_rebuild_milestones(event_id)


func _rebuild_event_selector() -> void:
	for child in event_list.get_children():
		child.queue_free()

	for event_id in EventState.event_ids():
		var event: Dictionary = GameData.get_live_event(event_id)
		var button := Button.new()
		button.toggle_mode = true
		button.button_pressed = event_id == EventState.selected_event_id()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0.0, 110.0)
		button.text = "%s\n%s  |  %s  |  %d pts" % [
			String(event.get("display_name", "Event")),
			String(event.get("status_label", "Live")),
			EventState.event_time_label(event_id),
			EventState.event_points(event_id),
		]
		button.pressed.connect(_on_event_pressed.bind(event_id))
		event_list.add_child(button)
	ThemeManager.wire_button_feedback(event_list)


func _rebuild_stage_list(event_id: String) -> void:
	_clear_stage_list()
	for entry in EventState.event_stage_entries(event_id):
		var stage: Dictionary = entry.get("stage", {})
		var stage_id := String(stage.get("stage_id", ""))
		var button := Button.new()
		button.toggle_mode = true
		button.button_pressed = bool(entry.get("is_selected", false))
		button.disabled = bool(entry.get("is_unlocked", false)) == false
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0.0, 104.0)
		button.text = "%s\nRecommended power %d  |  %s" % [
			String(stage.get("display_name", stage_id)),
			int(stage.get("recommended_power", 0)),
			"%s  |  %d modifiers" % [_stage_state_label(entry), stage.get("modifiers", []).size()],
		]
		button.pressed.connect(_on_stage_pressed.bind(event_id, stage_id))
		stage_list.add_child(button)
	ThemeManager.wire_button_feedback(stage_list)


func _refresh_selected_stage(event_id: String) -> void:
	var stage: Dictionary = EventState.selected_stage()
	if stage.is_empty() or String(stage.get("event_id", "")) != event_id:
		selected_stage_label.text = "No event stage selected"
		selected_stage_description_label.text = ""
		selected_stage_meta_label.text = ""
		selected_stage_modifier_label.text = ""
		selected_stage_enemy_label.text = ""
		launch_stage_button.disabled = true
		return

	selected_stage_label.text = String(stage.get("display_name", "Event Stage"))
	selected_stage_description_label.text = String(stage.get("description", ""))
	selected_stage_meta_label.text = "Recommended power: %d\nDuration: %.0fs\nStatus: %s" % [
		int(stage.get("recommended_power", 0)),
		float(stage.get("duration_seconds", 60.0)),
		"Cleared" if EventState.is_stage_cleared(event_id, String(stage.get("stage_id", ""))) else "Uncleared",
	]
	var modifier_lines := GameData.event_modifier_summary_lines(stage.get("modifiers", []))
	selected_stage_modifier_label.text = "Stage modifiers:\n%s" % (
		"\n".join(modifier_lines) if modifier_lines.is_empty() == false else "None"
	)
	selected_stage_enemy_label.text = "Enemy lineup:\n%s" % _enemy_line_summary(stage)
	launch_stage_button.disabled = EventState.can_launch_selected_stage() == false
	launch_stage_button.text = "Launch %s" % String(stage.get("display_name", "Event Stage"))


func _rebuild_milestones(event_id: String) -> void:
	_clear_milestones()
	for entry in EventState.milestone_entries(event_id):
		var milestone: Dictionary = entry.get("milestone", {})
		var panel := PanelContainer.new()
		milestone_list.add_child(panel)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_top", 20)
		margin.add_theme_constant_override("margin_right", 20)
		margin.add_theme_constant_override("margin_bottom", 20)
		panel.add_child(margin)

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 16)
		margin.add_child(row)

		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.add_theme_constant_override("separation", 8)
		row.add_child(copy)

		var title := Label.new()
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.text = "%s  |  %d / %d points" % [
			String(milestone.get("display_name", "Milestone")),
			int(entry.get("progress", 0)),
			int(entry.get("target_points", 0)),
		]
		copy.add_child(title)

		var rewards := Label.new()
		rewards.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rewards.text = "Reward: %s" % _reward_summary(milestone.get("rewards", {}))
		copy.add_child(rewards)

		var claim_button := Button.new()
		claim_button.custom_minimum_size = Vector2(180.0, 88.0)
		claim_button.text = _claim_button_text(entry)
		claim_button.disabled = bool(entry.get("can_claim", false)) == false
		claim_button.pressed.connect(_on_claim_pressed.bind(event_id, String(milestone.get("milestone_id", ""))))
		row.add_child(claim_button)

	ThemeManager.wire_button_feedback(milestone_list)


func _clear_milestones() -> void:
	for child in milestone_list.get_children():
		child.queue_free()


func _clear_stage_list() -> void:
	for child in stage_list.get_children():
		child.queue_free()


func _claimed_milestone_count(event_id: String) -> int:
	var claimed := 0
	for entry in EventState.milestone_entries(event_id):
		if bool(entry.get("is_claimed", false)):
			claimed += 1
	return claimed


func _claim_button_text(entry: Dictionary) -> String:
	if bool(entry.get("is_claimed", false)):
		return "Claimed"
	if bool(entry.get("can_claim", false)):
		return "Claim"
	return "Locked"


func _reward_summary(rewards: Dictionary) -> String:
	var parts: Array[String] = []
	for reward_id in rewards.keys():
		var amount := int(rewards.get(reward_id, 0))
		if amount <= 0:
			continue
		match String(reward_id):
			"gold":
				parts.append("%d gold" % amount)
			"hero_xp":
				parts.append("%d hero XP" % amount)
			"premium_shards":
				parts.append("%d premium shards" % amount)
			_:
				parts.append("%d %s" % [amount, _resource_label(String(reward_id))])
	return " | ".join(parts)


func _resource_label(resource_id: String) -> String:
	for banner in GameData.get_all_summon_banners():
		if String(banner.get("currency_id", "")) == resource_id:
			return String(banner.get("currency_name", resource_id))
	return resource_id


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


func _on_event_pressed(event_id: String) -> void:
	_status_message = ""
	EventState.select_event(event_id)


func _on_stage_pressed(event_id: String, stage_id: String) -> void:
	EventState.select_stage(event_id, stage_id)


func _on_claim_pressed(event_id: String, milestone_id: String) -> void:
	var result := EventState.claim_milestone(event_id, milestone_id)
	if bool(result.get("ok", false)):
		_status_message = "Claimed event reward: %s" % _reward_summary(result.get("rewards", {}))
	else:
		_status_message = "Event reward unavailable."
	_refresh_screen()


func _on_open_banner_pressed() -> void:
	var banner_id := EventState.linked_banner_id_for_event(EventState.selected_event_id())
	if banner_id.is_empty():
		return
	SummonState.select_banner(banner_id)
	SceneRouter.go_to("summon")


func _on_launch_stage_pressed() -> void:
	if EventState.begin_stage_battle(EventState.selected_event_id(), EventState.selected_stage_id()) == false:
		return
	SceneRouter.go_to("battle")
