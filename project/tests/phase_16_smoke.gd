extends SceneTree

const SETTINGS_SCENE_PATH := "res://project/scenes/settings/settings_screen.tscn"
const SETTINGS_ROUTE_SCENE := "res://project/scenes/settings/settings_screen.tscn"


func _initialize() -> void:
	var failures: Array[String] = []

	await process_frame
	await process_frame

	var root := get_root()
	var save_state = root.get_node_or_null("SaveState")
	var settings_state = root.get_node_or_null("SettingsState")
	var scene_router = root.get_node_or_null("SceneRouter")
	if save_state == null:
		failures.append("SaveState autoload is missing.")
	if settings_state == null:
		failures.append("SettingsState autoload is missing.")
	if scene_router == null:
		failures.append("SceneRouter autoload is missing.")

	if failures.is_empty() == false:
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	var had_original_save: bool = save_state.save_exists()
	var original_save_text: String = _read_text(save_state.save_path())

	var settings_scene := ResourceLoader.load(SETTINGS_SCENE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if settings_scene == null:
		failures.append("Failed to load Phase 16 settings screen scene.")
	else:
		var settings_instance := settings_scene.instantiate()
		if settings_instance == null:
			failures.append("Failed to instantiate Phase 16 settings screen.")
		else:
			settings_instance.free()

	var settings_route: Dictionary = scene_router.get_screen_definition("settings")
	if String(settings_route.get("scene", "")) != SETTINGS_ROUTE_SCENE:
		failures.append("Settings route should resolve to the real settings screen.")

	save_state.reset_save(false)

	settings_state.set_transitions_enabled(false)
	settings_state.set_button_feedback_enabled(false)
	settings_state.set_master_volume(0.55)
	settings_state.set_music_volume(0.35)
	settings_state.set_sfx_volume(0.25)
	save_state.save_game()

	var saved_text: String = _read_text(save_state.save_path())
	if saved_text.find("\"settings\"") == -1:
		failures.append("Unified save payload should contain a settings block.")
	if saved_text.find("\"version\":2") == -1:
		failures.append("Unified save payload should use save version 2.")

	settings_state.set_transitions_enabled(true)
	settings_state.set_button_feedback_enabled(true)
	settings_state.set_master_volume(1.0)
	settings_state.set_music_volume(0.8)
	settings_state.set_sfx_volume(0.85)

	if save_state.load_game() == false:
		failures.append("SaveState should reload a valid Phase 16 save file.")

	if settings_state.transitions_enabled():
		failures.append("Transitions toggle should restore as disabled.")
	if settings_state.button_feedback_enabled():
		failures.append("Button feedback toggle should restore as disabled.")
	if is_equal_approx(settings_state.master_volume(), 0.55) == false:
		failures.append("Master volume should restore from save.")
	if is_equal_approx(settings_state.music_volume(), 0.35) == false:
		failures.append("Music volume should restore from save.")
	if is_equal_approx(settings_state.sfx_volume(), 0.25) == false:
		failures.append("SFX volume should restore from save.")

	if had_original_save:
		_write_text(save_state.save_path(), original_save_text)
		save_state.load_game()
	else:
		save_state.reset_save()

	if failures.is_empty():
		print("Phase 16 smoke test passed.")
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
