extends ScrollContainer

const FutureFeatureRegistry := preload("res://project/scripts/systems/future_feature_registry.gd")

const QUICK_LINKS := [
	{"id": "heroes", "label": "Open Heroes"},
	{"id": "summon", "label": "Open Summon"},
	{"id": "quests", "label": "Open Quests"},
	{"id": "events", "label": "Open Events"},
	{"id": "formation", "label": "Open Formation"},
	{"id": "campaign", "label": "Open Campaign"},
	{"id": "battle", "label": "Open Battle"},
	{"id": "rewards", "label": "Open Rewards"},
	{"id": "settings", "label": "Open Settings"},
]

@onready var phase_summary_label: Label = %PhaseSummaryLabel
@onready var state_label: Label = %StateLabel
@onready var content_footprint_label: Label = %ContentFootprintLabel
@onready var future_hooks_label: Label = %FutureHooksLabel
@onready var action_grid: GridContainer = %ActionGrid
@onready var notes_label: Label = %NotesLabel


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
	var loaded_skills := GameData.skill_count() if is_instance_valid(GameData) else 0
	var loaded_stages := GameData.stage_count() if is_instance_valid(GameData) else 0
	var future_hooks := GameData.future_feature_count() if is_instance_valid(GameData) else 0
	var cleared_stages := CampaignState.cleared_stage_ids().size() if is_instance_valid(CampaignState) else 0

	var gold_balance := RewardState.gold_balance() if is_instance_valid(RewardState) else 0
	var hero_xp_balance := RewardState.hero_xp_balance() if is_instance_valid(RewardState) else 0
	var premium_shards := RewardState.premium_shard_balance() if is_instance_valid(RewardState) else 0
	var item_defs := GameData.item_count() if is_instance_valid(GameData) else 0
	var equipped_items := InventoryState.total_equipped_count() if is_instance_valid(InventoryState) else 0
	var claimed_quests := QuestState.claimed_quest_ids().size() if is_instance_valid(QuestState) else 0
	var total_quests := GameData.quest_count() if is_instance_valid(GameData) else 0
	var live_events := GameData.live_event_count() if is_instance_valid(GameData) else 0
	var live_event_stages := GameData.live_event_stage_count() if is_instance_valid(GameData) else 0
	var save_status := SaveState.last_status() if is_instance_valid(SaveState) else "Unavailable"
	var active_events := EventState.active_event_count() if is_instance_valid(EventState) else 0
	var event_points := EventState.selected_event_points() if is_instance_valid(EventState) else 0

	var average_level := 0
	if owned_heroes > 0 and is_instance_valid(ProfileState):
		for hero_id in ProfileState.owned_hero_ids():
			average_level += ProfileState.hero_level(hero_id)
		average_level = int(round(float(average_level) / float(owned_heroes)))

	var settings_summary := "Transitions %s | Feedback %s | Master %d%%" % [
		"On" if SettingsState.transitions_enabled() else "Off",
		"On" if SettingsState.button_feedback_enabled() else "Off",
		int(round(SettingsState.master_volume() * 100.0)),
	]

	phase_summary_label.text = "Phase 22 layers temporary combat modifiers onto event stages. Live events now carry per-stage mutators like allied attack boosts, enemy stat surges, and starting-energy bonuses that are authored in data and applied through the shared battle pipeline."
	state_label.text = "Current route: %s\nBoot count: %d\nLoaded heroes: %d\nOwned heroes: %d\nAverage hero level: %d\nFormation: %d/5\nTeam power: %d\nStages: %d\nCleared stages: %d\nBattle encounters: %d\nUltimate skills: %d\nItem defs: %d\nFuture hooks: %d\nSummon banners: %d\nLive events: %d\nEvent stages: %d\nActive events: %d\nEvent points: %d\nTotal pulls: %d\nQuests claimed: %d / %d\nEquipped items: %d\nGold: %d\nHero XP: %d\nPremium shards: %d\nSave status: %s" % [
		AppState.current_screen.replace("_", " ").capitalize(),
		AppState.boot_count,
		loaded_heroes,
		owned_heroes,
		average_level,
		assigned_count,
		team_power,
		loaded_stages,
		cleared_stages,
		battle_encounters,
		loaded_skills,
		item_defs,
		future_hooks,
		GameData.summon_banner_count(),
		live_events,
		live_event_stages,
		active_events,
		event_points,
		SummonState.total_pulls(),
		claimed_quests,
		total_quests,
		equipped_items,
		gold_balance,
		hero_xp_balance,
		premium_shards,
		save_status,
	]
	content_footprint_label.text = "\n".join(FutureFeatureRegistry.content_footprint_lines())
	future_hooks_label.text = "\n".join(FutureFeatureRegistry.hook_summary_lines(GameData.get_all_future_features()))
	state_label.text += "\nSettings: %s\nPrototype status: Phase 22 event combat modifiers complete." % settings_summary
	notes_label.text = "The event route now covers a full prototype live-ops loop: milestone rewards, event-exclusive stages, stage-specific combat modifiers, linked-banner routing, and save-backed progression, all driven by authored data on top of the shared battle systems."
