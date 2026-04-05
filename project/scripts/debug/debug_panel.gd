extends Control

const SCREEN_LINKS := [
	{"id": "main_menu", "label": "Main Menu"},
	{"id": "heroes", "label": "Heroes"},
	{"id": "summon", "label": "Summon"},
	{"id": "quests", "label": "Quests"},
	{"id": "events", "label": "Events"},
	{"id": "formation", "label": "Formation"},
	{"id": "campaign", "label": "Campaign"},
	{"id": "battle", "label": "Battle"},
	{"id": "rewards", "label": "Rewards"},
	{"id": "settings", "label": "Settings"},
]

@onready var backdrop: ColorRect = %Backdrop
@onready var state_label: Label = %StateLabel
@onready var save_status_label: Label = %SaveStatusLabel
@onready var close_button: Button = %CloseButton
@onready var reset_button: Button = %ResetButton
@onready var cycle_button: Button = %CycleButton
@onready var save_button: Button = %SaveButton
@onready var reload_button: Button = %ReloadButton
@onready var reset_save_button: Button = %ResetSaveButton
@onready var grant_resources_button: Button = %GrantResourcesButton
@onready var unlock_stages_button: Button = %UnlockStagesButton
@onready var cap_heroes_button: Button = %CapHeroesButton
@onready var grant_event_button: Button = %GrantEventButton
@onready var screen_buttons: GridContainer = %ScreenButtons


func _ready() -> void:
	close_button.pressed.connect(_close)
	reset_button.pressed.connect(DebugTools.reset_navigation)
	cycle_button.pressed.connect(DebugTools.cycle_screen)
	save_button.pressed.connect(DebugTools.save_game)
	reload_button.pressed.connect(DebugTools.reload_game)
	reset_save_button.pressed.connect(DebugTools.reset_save)
	grant_resources_button.pressed.connect(DebugTools.grant_debug_resources)
	unlock_stages_button.pressed.connect(DebugTools.unlock_all_stages)
	cap_heroes_button.pressed.connect(DebugTools.instant_level_up_all_heroes)
	grant_event_button.pressed.connect(DebugTools.grant_event_progress)
	backdrop.gui_input.connect(_on_backdrop_gui_input)
	SaveState.save_state_changed.connect(_refresh_state)
	ProfileState.roster_changed.connect(_refresh_state)
	FormationState.formation_changed.connect(_refresh_state)
	CampaignState.campaign_changed.connect(_refresh_state)
	RewardState.rewards_changed.connect(_refresh_state)
	SummonState.summon_state_changed.connect(_refresh_state)
	QuestState.quest_state_changed.connect(_refresh_state)
	EventState.event_state_changed.connect(_refresh_state)
	InventoryState.inventory_changed.connect(_refresh_state)
	_build_screen_buttons()
	visible = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		_refresh_state()


func _build_screen_buttons() -> void:
	if screen_buttons.get_child_count() > 0:
		return

	for item in SCREEN_LINKS:
		var button := Button.new()
		button.text = String(item["label"])
		button.custom_minimum_size = Vector2(0.0, 88.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_open_screen.bind(String(item["id"])))
		screen_buttons.add_child(button)


func _refresh_state() -> void:
	state_label.text = "\n".join(AppState.summary_lines())
	save_status_label.text = "Save: %s" % SaveState.last_status()


func _open_screen(screen_id: String) -> void:
	DebugTools.open_screen(screen_id)


func _close() -> void:
	DebugTools.set_menu_open(false)


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close()
