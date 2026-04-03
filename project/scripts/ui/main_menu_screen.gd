extends ScrollContainer

const QUICK_LINKS := [
	{"id": "heroes", "label": "Open Heroes"},
	{"id": "formation", "label": "Open Formation"},
	{"id": "campaign", "label": "Open Campaign"},
	{"id": "battle", "label": "Open Battle"},
	{"id": "rewards", "label": "Open Rewards"},
	{"id": "settings", "label": "Open Settings"},
]

@onready var phase_summary_label: Label = %PhaseSummaryLabel
@onready var state_label: Label = %StateLabel
@onready var action_grid: GridContainer = %ActionGrid


func _ready() -> void:
	_build_quick_links()
	_refresh_copy()


func configure(_metadata: Dictionary) -> void:
	pass


func _build_quick_links() -> void:
	if action_grid.get_child_count() > 0:
		return

	for item in QUICK_LINKS:
		var button := Button.new()
		button.text = String(item["label"])
		button.custom_minimum_size = Vector2(0.0, 110.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(SceneRouter.go_to.bind(String(item["id"])))
		action_grid.add_child(button)


func _refresh_copy() -> void:
	var loaded_heroes := GameData.hero_count() if is_instance_valid(GameData) else 0
	var owned_heroes := ProfileState.owned_hero_count() if is_instance_valid(ProfileState) else 0
	var assigned_count := FormationState.assigned_count() if is_instance_valid(FormationState) else 0
	var team_power := FormationState.team_power() if is_instance_valid(FormationState) else 0
	var battle_encounters := GameData.battle_encounter_count() if is_instance_valid(GameData) else 0

	phase_summary_label.text = "Phase 4 adds the first runnable combat slice: a deterministic real-time auto-battle screen, debug speed controls, a restartable test encounter, and combat log output using the active formation."
	state_label.text = "Current route: %s\nBoot count: %d\nLoaded heroes: %d\nOwned heroes: %d\nFormation: %d/5\nTeam power: %d\nBattle encounters: %d\nNext implementation target: Phase 5 skills and energy." % [
		AppState.current_screen.replace("_", " ").capitalize(),
		AppState.boot_count,
		loaded_heroes,
		owned_heroes,
		assigned_count,
		team_power,
		battle_encounters,
	]
