class_name FutureFeatureRegistry
extends RefCounted


static func content_footprint_lines() -> Array[String]:
	return [
		"Authored content footprint",
		"Heroes: %d  |  Enemies: %d  |  Stages: %d" % [
			GameData.hero_count(),
			GameData.enemy_count(),
			GameData.stage_count(),
		],
		"Skills: %d  |  Items: %d  |  Test encounters: %d  |  Banners: %d  |  Quests: %d  |  Events: %d  |  Event stages: %d" % [
			GameData.skill_count(),
			GameData.item_count(),
			GameData.battle_encounter_count(),
			GameData.summon_banner_count(),
			GameData.quest_count(),
			GameData.live_event_count(),
			GameData.live_event_stage_count(),
		],
	]


static func hook_summary_lines(features: Array) -> Array[String]:
	var lines: Array[String] = ["Future systems wired for expansion"]
	for feature in features:
		lines.append(
			"%s  |  %s  |  %s" % [
				String(feature.get("display_name", "Feature")),
				String(feature.get("status_label", "Planned")),
				String(feature.get("planned_route", "future_route")),
			]
		)
	return lines


static func hook_detail_lines(features: Array) -> Array[String]:
	var lines: Array[String] = []
	for feature in features:
		var dependencies: Array[String] = []
		for dependency in feature.get("depends_on", []):
			dependencies.append(String(dependency))
		lines.append(
			"%s: %s" % [
				String(feature.get("display_name", "Feature")),
				String(feature.get("notes", "")),
			]
		)
		lines.append(
			"Surface: %s  |  Save: %s  |  Depends on: %s" % [
				String(feature.get("primary_surface", "Future UI")),
				String(feature.get("save_domain", "future")),
				", ".join(dependencies),
			]
		)
	return lines
