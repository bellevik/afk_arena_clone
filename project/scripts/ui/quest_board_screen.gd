extends ScrollContainer

var _status_message := ""

@onready var summary_label: Label = %SummaryLabel
@onready var status_label: Label = %StatusLabel
@onready var quest_list: VBoxContainer = %QuestList


func _ready() -> void:
	if QuestState.quest_state_changed.is_connected(_refresh_screen) == false:
		QuestState.quest_state_changed.connect(_refresh_screen)
	if RewardState.rewards_changed.is_connected(_refresh_screen) == false:
		RewardState.rewards_changed.connect(_refresh_screen)
	_refresh_screen()


func configure(_metadata: Dictionary) -> void:
	pass


func _refresh_screen() -> void:
	summary_label.text = "%s\nGold: %d  |  Hero XP: %d" % [
		"\n".join(QuestState.summary_lines()),
		RewardState.gold_balance(),
		RewardState.hero_xp_balance(),
	]
	status_label.text = "Claim quest rewards as objectives complete." if _status_message.is_empty() else _status_message
	_rebuild_quest_list()


func _rebuild_quest_list() -> void:
	for child in quest_list.get_children():
		child.queue_free()

	var last_cadence := ""
	for entry in QuestState.quest_entries():
		var quest: Dictionary = entry.get("quest", {})
		var cadence := String(entry.get("cadence", "milestone"))
		if cadence != last_cadence:
			var section_label := Label.new()
			section_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			section_label.text = "%s Quests%s" % [
				String(entry.get("cadence_label", "Milestone")),
				"" if String(entry.get("reset_label", "")).is_empty() or cadence == "milestone" else "  |  Reset in %s" % String(entry.get("reset_label", "")),
			]
			quest_list.add_child(section_label)
			last_cadence = cadence

		var panel := PanelContainer.new()
		quest_list.add_child(panel)

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
		title.text = "%s  |  %s  (%d / %d)" % [
			String(quest.get("display_name", "Quest")),
			String(entry.get("cadence_label", "Milestone")),
			int(entry.get("progress", 0)),
			int(entry.get("target", 1)),
		]
		copy.add_child(title)

		var description := Label.new()
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var reset_suffix := ""
		if cadence != "milestone":
			reset_suffix = "\nReset in: %s" % String(entry.get("reset_label", ""))
		description.text = "%s%s\nReward: %s" % [
			String(quest.get("description", "")),
			reset_suffix,
			_reward_summary(String(quest.get("quest_id", ""))),
		]
		copy.add_child(description)

		var claim_button := Button.new()
		claim_button.custom_minimum_size = Vector2(170.0, 88.0)
		claim_button.text = _claim_button_text(entry)
		claim_button.disabled = bool(entry.get("can_claim", false)) == false
		claim_button.pressed.connect(_on_claim_pressed.bind(String(quest.get("quest_id", ""))))
		row.add_child(claim_button)
	ThemeManager.wire_button_feedback(quest_list)


func _claim_button_text(entry: Dictionary) -> String:
	if bool(entry.get("is_claimed", false)):
		return "Claimed"
	if bool(entry.get("can_claim", false)):
		return "Claim"
	return "In Progress"


func _on_claim_pressed(quest_id: String) -> void:
	var result := QuestState.claim_quest(quest_id)
	if bool(result.get("ok", false)):
		_status_message = "Claimed quest reward: %s" % _reward_summary(quest_id)
	else:
		_status_message = "Quest reward unavailable."
	_refresh_screen()


func _reward_summary(quest_id: String) -> String:
	var quest: Dictionary = GameData.get_quest(quest_id)
	var rewards: Dictionary = quest.get("rewards", {})
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
				parts.append("%d %s" % [amount, String(reward_id)])
	return " | ".join(parts)
