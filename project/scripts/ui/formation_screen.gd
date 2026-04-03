extends Control

var _selected_slot_id: String = "front_left"
var _slot_buttons: Dictionary = {}

@onready var summary_label: Label = %SummaryLabel
@onready var status_label: Label = %StatusLabel
@onready var clear_button: Button = %ClearButton
@onready var auto_fill_button: Button = %AutoFillButton
@onready var selected_slot_label: Label = %SelectedSlotLabel
@onready var selection_hint_label: Label = %SelectionHintLabel
@onready var remove_button: Button = %RemoveButton
@onready var hero_list: VBoxContainer = %HeroList
@onready var empty_picker_label: Label = %EmptyPickerLabel
@onready var front_left_button: Button = %FrontLeftButton
@onready var front_right_button: Button = %FrontRightButton
@onready var back_left_button: Button = %BackLeftButton
@onready var back_center_button: Button = %BackCenterButton
@onready var back_right_button: Button = %BackRightButton


func _ready() -> void:
	_slot_buttons = {
		"front_left": front_left_button,
		"front_right": front_right_button,
		"back_left": back_left_button,
		"back_center": back_center_button,
		"back_right": back_right_button,
	}

	for slot_id in _slot_buttons.keys():
		var button := _slot_buttons[slot_id] as Button
		button.toggle_mode = true
		button.pressed.connect(_on_slot_pressed.bind(String(slot_id)))

	clear_button.pressed.connect(FormationState.clear_formation)
	auto_fill_button.pressed.connect(FormationState.auto_fill)
	remove_button.pressed.connect(_on_remove_pressed)

	if FormationState.formation_changed.is_connected(_refresh_screen) == false:
		FormationState.formation_changed.connect(_refresh_screen)
	if ProfileState.roster_changed.is_connected(_refresh_screen) == false:
		ProfileState.roster_changed.connect(_refresh_screen)

	_refresh_screen()


func configure(_metadata: Dictionary) -> void:
	pass


func _refresh_screen() -> void:
	if FormationState.slot_definition(_selected_slot_id).is_empty():
		_selected_slot_id = "front_left"

	_refresh_summary()
	_refresh_slots()
	_refresh_picker()


func _refresh_summary() -> void:
	summary_label.text = "\n".join(FormationState.summary_lines())
	status_label.text = "Rules: 2 frontline slots, 3 backline slots. Heroes can only occupy one slot at a time. The active formation persists for this session."


func _refresh_slots() -> void:
	for slot_id in FormationState.slot_ids():
		var definition: Dictionary = FormationState.slot_definition(slot_id)
		var button := _slot_buttons.get(slot_id) as Button
		if button == null:
			continue

		var hero: Dictionary = FormationState.get_assigned_hero(slot_id)
		var label: String = "%s\n%s" % [String(definition.get("label", slot_id)), String(definition.get("line", ""))]
		if hero.is_empty():
			label += "\nTap to assign"
		else:
			var hero_id: String = String(hero.get("hero_id", ""))
			var level: int = ProfileState.hero_level(hero_id)
			var power: int = FormationState.hero_power_for_entry(hero, level)
			label += "\n%s Lv.%d\n%s\nPower %d" % [
				String(hero.get("display_name", "Unknown")),
				level,
				GameData.hero_metadata_summary(hero),
				power,
			]

		button.text = label
		button.button_pressed = slot_id == _selected_slot_id


func _refresh_picker() -> void:
	for child in hero_list.get_children():
		child.queue_free()

	var selected_slot_definition: Dictionary = FormationState.slot_definition(_selected_slot_id)
	var selected_slot_hero: Dictionary = FormationState.get_assigned_hero(_selected_slot_id)
	selected_slot_label.text = "Selected slot: %s" % String(selected_slot_definition.get("label", _selected_slot_id))
	remove_button.disabled = selected_slot_hero.is_empty()

	if selected_slot_hero.is_empty():
		selection_hint_label.text = "Choose a hero below to fill this slot."
	else:
		selection_hint_label.text = "Current hero: %s. Pick another hero to swap, or remove the assignment." % String(selected_slot_hero.get("display_name", "Unknown"))

	var entries: Array[Dictionary] = FormationState.selection_entries()
	empty_picker_label.visible = entries.is_empty()

	for entry in entries:
		var hero: Dictionary = entry.get("hero", {})
		if hero.is_empty():
			continue

		var hero_id: String = String(hero.get("hero_id", ""))
		var level: int = int(entry.get("level", 1))
		var assigned_slot: String = String(entry.get("assigned_slot", ""))
		var assigned_elsewhere: bool = assigned_slot.is_empty() == false and assigned_slot != _selected_slot_id
		var power: int = FormationState.hero_power_for_entry(hero, level)

		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 118.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = "%s  Lv.%d\n%s\nPower %d" % [
			String(hero.get("display_name", "Unknown")),
			level,
			GameData.hero_metadata_summary(hero),
			power,
		]
		if assigned_elsewhere:
			var slot_name: String = String(FormationState.slot_definition(assigned_slot).get("label", assigned_slot))
			button.text += "\nAssigned to %s" % String(slot_name)
			button.disabled = true
		elif assigned_slot == _selected_slot_id:
			button.text += "\nCurrently assigned here"

		button.pressed.connect(_on_assign_pressed.bind(hero_id))
		hero_list.add_child(button)


func _on_slot_pressed(slot_id: String) -> void:
	_selected_slot_id = slot_id
	_refresh_slots()
	_refresh_picker()


func _on_assign_pressed(hero_id: String) -> void:
	var result: Dictionary = FormationState.assign(_selected_slot_id, hero_id)
	if bool(result.get("ok", false)) == false:
		selection_hint_label.text = String(result.get("error", "Could not assign hero."))
		return

	_refresh_screen()


func _on_remove_pressed() -> void:
	FormationState.remove(_selected_slot_id)
	_refresh_screen()
