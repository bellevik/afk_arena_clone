extends SceneTree

const BattleBuilderScript := preload("res://project/scripts/battle/battle_builder.gd")
const BattleSimulatorScript := preload("res://project/scripts/battle/battle_simulator.gd")
const SCENE_PATHS := [
	"res://project/scenes/boot/boot.tscn",
	"res://project/scenes/menus/app_shell.tscn",
	"res://project/scenes/menus/main_menu_screen.tscn",
	"res://project/scenes/common/debug_panel.tscn",
	"res://project/scenes/events/event_screen.tscn",
	"res://project/scenes/summon/summon_screen.tscn",
	"res://project/scenes/battle/battle_screen.tscn",
	"res://project/scenes/rewards/rewards_screen.tscn",
]

const FIXED_STEP_SECONDS := 0.1
const MAX_SIMULATION_STEPS := 1800
const EVENT_ID := "emberwake_festival"
const FIRST_STAGE_ID := "emberwake_stage_01"
const SECOND_STAGE_ID := "emberwake_stage_02"


func _initialize() -> void:
	var failures: Array[String] = []

	await process_frame
	await process_frame

	var root := get_root()
	var game_data = root.get_node_or_null("GameData")
	var profile_state = root.get_node_or_null("ProfileState")
	var formation_state = root.get_node_or_null("FormationState")
	var reward_state = root.get_node_or_null("RewardState")
	var event_state = root.get_node_or_null("EventState")
	var save_state = root.get_node_or_null("SaveState")
	var scene_router = root.get_node_or_null("SceneRouter")

	for scene_path in SCENE_PATHS:
		var scene_resource := ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if scene_resource == null:
			failures.append("Failed to load scene: %s" % scene_path)
			continue
		var packed_scene := scene_resource as PackedScene
		if packed_scene == null:
			failures.append("Resource is not a PackedScene: %s" % scene_path)
			continue
		var instance := packed_scene.instantiate()
		if instance == null:
			failures.append("Failed to instantiate scene: %s" % scene_path)
			continue
		instance.free()

	if game_data == null or profile_state == null or formation_state == null or reward_state == null or event_state == null or save_state == null or scene_router == null:
		failures.append("Phase 21 smoke test requires the core autoloads plus EventState and SaveState.")

	if failures.is_empty() == false:
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	var had_original_save: bool = save_state.save_exists()
	var original_save_text: String = _read_text(save_state.save_path())

	save_state.reset_save(false)
	profile_state.cap_all_heroes_for_debug()
	formation_state.clear_formation()
	formation_state.assign("front_left", "aurelian_guard")
	formation_state.assign("front_right", "ironclad_brann")
	formation_state.assign("back_left", "cinderstrike_nyra")
	formation_state.assign("back_center", "duskwisp_iona")
	formation_state.assign("back_right", "tidecaller_serin")

	if game_data.live_event_count() < 1:
		failures.append("Phase 21 should keep at least one live event authored.")
	if game_data.live_event_stage_count() < 3:
		failures.append("Phase 21 should author at least three event stages.")

	event_state.select_event(EVENT_ID)
	event_state.select_stage(EVENT_ID, FIRST_STAGE_ID)
	if event_state.is_stage_unlocked(EVENT_ID, FIRST_STAGE_ID) == false:
		failures.append("The first event stage should be unlocked by default.")
	if event_state.is_stage_unlocked(EVENT_ID, SECOND_STAGE_ID):
		failures.append("The second event stage should start locked before clearing the first stage.")

	var app_shell_scene := ResourceLoader.load("res://project/scenes/menus/app_shell.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if app_shell_scene == null:
		failures.append("Could not load app shell scene for Phase 21 smoke test.")
	else:
		var app_shell := app_shell_scene.instantiate()
		root.add_child(app_shell)
		await process_frame
		await process_frame

		scene_router.go_to("events")
		await process_frame
		await process_frame

		var screen_host = app_shell.get_node("RootMargin/Layout/ContentPanel/ContentMargin/ScreenHost")
		if screen_host.get_child_count() <= 0:
			failures.append("Events screen should load inside the app shell.")
		else:
			var current_screen: Node = screen_host.get_child(screen_host.get_child_count() - 1)
			if current_screen.get_node_or_null("Content/Stack/StagePanel/StageMargin/StageStack/LaunchStageButton") == null:
				failures.append("Events screen should expose the event-stage launch action.")

		app_shell.queue_free()

	if event_state.begin_stage_battle(EVENT_ID, FIRST_STAGE_ID) == false:
		failures.append("EventState should launch the first event stage.")

	var pending_stage: Dictionary = event_state.pending_battle_definition()
	if pending_stage.is_empty():
		failures.append("Event stage should expose a pending battle definition after launch.")

	var battle_builder = BattleBuilderScript.new()
	var player_units: Array[Dictionary] = battle_builder.build_player_team_from_formation()
	var enemy_units: Array[Dictionary] = battle_builder.build_enemy_team_from_encounter(pending_stage)
	var simulator = BattleSimulatorScript.new()
	simulator.setup(player_units, enemy_units, {"duration_seconds": float(pending_stage.get("duration_seconds", 60.0))})

	for _step in MAX_SIMULATION_STEPS:
		if simulator.is_finished():
			break
		simulator.step(FIXED_STEP_SECONDS)

	if simulator.is_finished() == false:
		failures.append("Event-stage smoke battle did not finish in the allowed number of steps.")

	var won_stage: bool = simulator.winner_team() == BattleSimulatorScript.TEAM_PLAYER
	if won_stage == false:
		failures.append("The configured debug team should clear the first event stage.")
	else:
		var battle_rewards: Dictionary = reward_state.grant_battle_rewards("event_stage", FIRST_STAGE_ID, true)
		event_state.report_battle_result(true)
		if int(battle_rewards.get("premium_shards", 0)) != 40:
			failures.append("The first event stage should grant 40 premium shards.")

	if event_state.is_stage_cleared(EVENT_ID, FIRST_STAGE_ID) == false:
		failures.append("Clearing the first event stage should persist as cleared.")
	if event_state.is_stage_unlocked(EVENT_ID, SECOND_STAGE_ID) == false:
		failures.append("Clearing the first event stage should unlock the second stage.")
	if event_state.event_points(EVENT_ID) != 60:
		failures.append("Clearing the first event stage should award 60 event points.")

	save_state.save_game()
	var saved_text: String = _read_text(save_state.save_path())
	if saved_text.find("\"version\":6") == -1:
		failures.append("Phase 21 should persist save version 6.")
	if saved_text.find("\"emberwake_stage_01\"") == -1 or saved_text.find("\"events\"") == -1:
		failures.append("Phase 21 save payload should persist event-stage progression.")

	event_state.debug_grant_points_to_active_event(200)
	if save_state.load_game() == false:
		failures.append("Phase 21 save should reload cleanly.")
	if event_state.event_points(EVENT_ID) != 60:
		failures.append("Event points should restore after save reload.")
	if event_state.is_stage_cleared(EVENT_ID, FIRST_STAGE_ID) == false:
		failures.append("Event-stage clear state should restore after save reload.")

	if had_original_save:
		_write_text(save_state.save_path(), original_save_text)
		save_state.load_game()
	else:
		save_state.reset_save()

	if failures.is_empty():
		print("Phase 21 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)

	quit(1)


func _read_text(path: String) -> String:
	if FileAccess.file_exists(path) == false:
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(text)
