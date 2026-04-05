extends SceneTree

const SCENE_PATHS := [
	"res://project/scenes/boot/boot.tscn",
	"res://project/scenes/menus/app_shell.tscn",
	"res://project/scenes/menus/main_menu_screen.tscn",
	"res://project/scenes/common/debug_panel.tscn",
	"res://project/scenes/heroes/hero_roster_screen.tscn",
	"res://project/scenes/summon/summon_screen.tscn",
	"res://project/scenes/quests/quest_board_screen.tscn",
	"res://project/scenes/battle/formation_screen.tscn",
	"res://project/scenes/battle/battle_screen.tscn",
	"res://project/scenes/campaign/campaign_screen.tscn",
	"res://project/scenes/rewards/rewards_screen.tscn",
]


func _initialize() -> void:
	var failures: Array[String] = []

	await process_frame
	await process_frame

	var root := get_root()
	var game_data = root.get_node_or_null("GameData")
	if game_data == null:
		failures.append("Phase 15 smoke test requires the GameData autoload.")

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

	if game_data != null:
		for enemy_id in game_data.enemy_ids():
			var enemy: Dictionary = game_data.get_enemy(String(enemy_id))
			if String(enemy.get("ultimate_id", "")).is_empty():
				failures.append("Enemy %s should expose an ultimate id." % String(enemy_id))
				break
			if game_data.get_skill(String(enemy.get("ultimate_id", ""))).is_empty():
				failures.append("Enemy %s should resolve its ultimate through GameData skills." % String(enemy_id))
				break

		var encounter: Dictionary = game_data.get_battle_encounter("field_trial_bravo")
		if encounter.is_empty():
			failures.append("Phase 15 should keep the later-game field_trial_bravo encounter.")
		else:
			var enemy_units: Array[Dictionary] = []
			for entry in encounter.get("enemy_team", []):
				if entry is Dictionary == false:
					continue
				var enemy_id := String(entry.get("enemy_id", ""))
				var enemy: Dictionary = game_data.get_enemy(enemy_id)
				var stats: Dictionary = game_data.enemy_stats_for_level(enemy, int(entry.get("level", 1)))
				enemy_units.append({
					"team": "enemy",
					"source_type": "enemy",
					"slot_id": String(entry.get("slot_id", "")),
					"source_id": enemy_id,
					"display_name": String(enemy.get("display_name", enemy_id)),
					"role": String(enemy.get("role", "")),
					"faction": String(enemy.get("faction", "")),
					"portrait_glyph": String(enemy.get("portrait_glyph", "?")),
					"accent_color": enemy.get("accent_color", Color("607d8b")),
					"level": int(entry.get("level", 1)),
					"ultimate_id": String(enemy.get("ultimate_id", "")),
					"ultimate_name": String(enemy.get("ultimate_name", "")),
					"ultimate_description": String(enemy.get("ultimate_description", "")),
					"skill": game_data.get_skill(String(enemy.get("ultimate_id", ""))).duplicate(true),
					"stats": stats.duplicate(true),
					"power": int(stats.get("hp", 0)) + int(stats.get("attack", 0)) * 8 + int(stats.get("defense", 0)) * 6 + int(stats.get("speed", 0)) * 4,
				})

			var mirrored_player_units: Array[Dictionary] = []
			for unit in enemy_units:
				var mirrored := unit.duplicate(true)
				mirrored["team"] = "player"
				mirrored_player_units.append(mirrored)

			var simulator = preload("res://project/scripts/battle/battle_simulator.gd").new()
			simulator.setup(mirrored_player_units, enemy_units, {"duration_seconds": 80.0})

			var saw_enemy_cast := false
			for _i in 900:
				var events: Array[Dictionary] = simulator.step(0.1)
				for event in events:
					if String(event.get("type", "")) != "skill_cast":
						continue
					var caster_id := String(event.get("caster_id", ""))
					if caster_id.begins_with("enemy_"):
						saw_enemy_cast = true
						break
				if saw_enemy_cast or simulator.is_finished():
					break

			if saw_enemy_cast == false:
				failures.append("Enemy-authored ultimates should cast during a mirrored simulator run.")

	if failures.is_empty():
		print("Phase 15 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)

	quit(1)
