extends SceneTree

const BattleBuilderScript := preload("res://project/scripts/battle/battle_builder.gd")
const BattleSimulatorScript := preload("res://project/scripts/battle/battle_simulator.gd")
const SCENE_PATHS := [
	"res://project/scenes/boot/boot.tscn",
	"res://project/scenes/menus/app_shell.tscn",
	"res://project/scenes/events/event_screen.tscn",
	"res://project/scenes/battle/battle_screen.tscn",
]

const FIXED_STEP_SECONDS := 0.1
const MAX_SIMULATION_STEPS := 1800
const EVENT_ID := "emberwake_festival"
const STAGE_ID := "emberwake_stage_01"


func _initialize() -> void:
	var failures: Array[String] = []

	await process_frame
	await process_frame

	var root := get_root()
	var game_data = root.get_node_or_null("GameData")
	var profile_state = root.get_node_or_null("ProfileState")
	var formation_state = root.get_node_or_null("FormationState")
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

	if game_data == null or profile_state == null or formation_state == null or event_state == null or save_state == null or scene_router == null:
		failures.append("Phase 22 smoke test requires GameData, ProfileState, FormationState, EventState, SaveState, and SceneRouter autoloads.")

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

	var stage: Dictionary = game_data.get_live_event_stage(STAGE_ID)
	if stage.is_empty():
		failures.append("Phase 22 should keep the first event stage authored.")
	else:
		var modifier_lines: Array[String] = game_data.live_event_stage_modifier_summary_lines(STAGE_ID)
		if modifier_lines.size() < 3:
			failures.append("Phase 22 should author multiple readable modifiers on the first event stage.")

	event_state.select_event(EVENT_ID)
	event_state.select_stage(EVENT_ID, STAGE_ID)
	if event_state.begin_stage_battle(EVENT_ID, STAGE_ID) == false:
		failures.append("EventState should still launch the first event stage in Phase 22.")

	var pending_stage: Dictionary = event_state.pending_battle_definition()
	if pending_stage.get("modifiers", []).size() < 3:
		failures.append("Pending event-stage battle definitions should now include modifier payloads.")

	var battle_builder = BattleBuilderScript.new()
	var battle_context := {"modifiers": pending_stage.get("modifiers", []).duplicate(true)}
	var player_units: Array[Dictionary] = battle_builder.build_player_team_from_formation(battle_context)
	var enemy_units: Array[Dictionary] = battle_builder.build_enemy_team_from_encounter(pending_stage, battle_context)

	var player_frontline := _find_unit(player_units, "player", "aurelian_guard")
	var enemy_frontline := _find_unit(enemy_units, "enemy", "ember_husk")
	var base_player_stats: Dictionary = profile_state.hero_stats("aurelian_guard")
	var base_enemy_stats: Dictionary = game_data.enemy_stats_for_level(game_data.get_enemy("ember_husk"), 11)

	if int(player_frontline.get("stats", {}).get("attack", 0)) != int(round(int(base_player_stats.get("attack", 0)) * 1.12)):
		failures.append("Stage modifiers should raise allied attack during event-stage battle setup.")
	if int(player_frontline.get("initial_energy", 0)) != 180:
		failures.append("Stage modifiers should grant allied starting energy during event-stage battle setup.")
	if int(enemy_frontline.get("stats", {}).get("hp", 0)) != int(round(int(base_enemy_stats.get("hp", 0)) * 1.08)):
		failures.append("Stage modifiers should raise enemy HP during event-stage battle setup.")

	var simulator = BattleSimulatorScript.new()
	simulator.setup(player_units, enemy_units, {"duration_seconds": float(pending_stage.get("duration_seconds", 60.0))})
	var simulated_frontline := _find_unit(simulator.units(), "player", "aurelian_guard")
	if int(simulated_frontline.get("energy", 0)) != 180:
		failures.append("BattleSimulator should honor modifier-driven starting energy.")

	for _step in MAX_SIMULATION_STEPS:
		if simulator.is_finished():
			break
		simulator.step(FIXED_STEP_SECONDS)

	if simulator.is_finished() == false:
		failures.append("Phase 22 event-stage battle should still finish under modifier load.")

	var app_shell_scene := ResourceLoader.load("res://project/scenes/menus/app_shell.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if app_shell_scene == null:
		failures.append("Could not load app shell scene for Phase 22 smoke test.")
	else:
		var app_shell := app_shell_scene.instantiate()
		root.add_child(app_shell)
		await process_frame
		await process_frame

		scene_router.go_to("events")
		await process_frame
		await process_frame

		var screen_host = app_shell.get_node("RootMargin/Layout/ContentPanel/ContentMargin/ScreenHost")
		var current_screen: Node = screen_host.get_child(screen_host.get_child_count() - 1)
		var modifier_label = current_screen.get_node_or_null("Content/Stack/StagePanel/StageMargin/StageStack/SelectedStageModifierLabel")
		if modifier_label == null or String(modifier_label.text).find("Rallying Flame") == -1:
			failures.append("Events screen should surface selected stage modifiers.")

		scene_router.go_to("battle")
		await process_frame
		await process_frame

		current_screen = screen_host.get_child(screen_host.get_child_count() - 1)
		modifier_label = current_screen.get_node_or_null("Content/Stack/ControlsPanel/ControlsMargin/ControlsStack/ModifierSummaryLabel")
		if modifier_label == null or String(modifier_label.text).find("Opening Beat") == -1:
			failures.append("Battle screen should surface active stage modifiers.")

		app_shell.queue_free()

	save_state.save_game()
	var saved_text: String = _read_text(save_state.save_path())
	if saved_text.find("\"version\":6") == -1:
		failures.append("Phase 22 should continue using save version 6.")

	if had_original_save:
		_write_text(save_state.save_path(), original_save_text)
		save_state.load_game()
	else:
		save_state.reset_save()

	if failures.is_empty():
		print("Phase 22 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)

	quit(1)


func _find_unit(units: Array[Dictionary], team: String, source_id: String) -> Dictionary:
	for unit in units:
		if String(unit.get("team", "")) != team:
			continue
		if String(unit.get("source_id", "")) != source_id:
			continue
		return unit
	return {}


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
