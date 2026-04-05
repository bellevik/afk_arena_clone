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
	"res://project/scenes/settings/settings_screen.tscn",
]


func _initialize() -> void:
	var failures: Array[String] = []

	await process_frame
	await process_frame

	var root := get_root()
	var game_data = root.get_node_or_null("GameData")
	var reward_state = root.get_node_or_null("RewardState")
	var quest_state = root.get_node_or_null("QuestState")
	var campaign_state = root.get_node_or_null("CampaignState")
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

	if game_data == null or reward_state == null or quest_state == null or campaign_state == null or scene_router == null:
		failures.append("Phase 18 smoke test requires GameData, RewardState, QuestState, CampaignState, and SceneRouter autoloads.")

	if failures.is_empty() == false:
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	if int(game_data.quest_count()) < 10:
		failures.append("Phase 18 should expose milestone, daily, and weekly quest definitions.")
	if game_data.quest_ids_for_cadence("daily").size() < 3:
		failures.append("Phase 18 should expose at least 3 daily quests.")
	if game_data.quest_ids_for_cadence("weekly").size() < 2:
		failures.append("Phase 18 should expose at least 2 weekly quests.")

	quest_state.reset_persistent_state()
	var before_gold := int(reward_state.gold_balance())

	for _i in 3:
		reward_state.grant_battle_rewards("test", "", true)

	if int(quest_state.progress_for_quest("quest_daily_patrol")) != 3:
		failures.append("Daily battle-win quest should advance from battle rewards.")
	var daily_claim: Dictionary = quest_state.claim_quest("quest_daily_patrol")
	if bool(daily_claim.get("ok", false)) == false:
		failures.append("Completed daily quest should be claimable.")
	elif int(reward_state.gold_balance()) <= before_gold:
		failures.append("Claiming a daily quest should grant resources.")

	var stale_state: Dictionary = quest_state.serialize_state()
	stale_state["recurring_state_by_id"]["quest_daily_patrol"] = {
		"cycle_key": "d_old",
		"progress": 3,
		"claimed": true,
	}
	quest_state.apply_state(stale_state)
	if int(quest_state.progress_for_quest("quest_daily_patrol")) != 0:
		failures.append("Daily quest progress should reset when the saved cycle key is stale.")
	if quest_state.is_quest_claimed("quest_daily_patrol"):
		failures.append("Daily quest claimed state should reset when the cycle changes.")

	for _i in 8:
		campaign_state.stage_cleared.emit("chapter_01_stage_01")
	if int(quest_state.progress_for_quest("quest_weekly_frontier")) != 8:
		failures.append("Weekly stage-clear quest should advance from stage_cleared events.")

	var summary_text := "\n".join(quest_state.summary_lines())
	if summary_text.find("Daily reset:") == -1 or summary_text.find("Weekly reset:") == -1:
		failures.append("Quest summary should expose recurring reset timers.")

	var app_shell_scene := ResourceLoader.load("res://project/scenes/menus/app_shell.tscn", "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if app_shell_scene == null:
		failures.append("Could not load app shell scene for Phase 18 smoke test.")
	else:
		var app_shell := app_shell_scene.instantiate()
		root.add_child(app_shell)
		await process_frame
		await process_frame

		scene_router.go_to("quests")
		await process_frame
		await process_frame

		var screen_host = app_shell.get_node("RootMargin/Layout/ContentPanel/ContentMargin/ScreenHost")
		if screen_host.get_child_count() <= 0:
			failures.append("Quest screen should load inside the app shell.")
		else:
			var current_screen: Node = screen_host.get_child(screen_host.get_child_count() - 1)
			if current_screen.get_node_or_null("Content/Stack/QuestPanel/QuestMargin/QuestStack/QuestList") == null:
				failures.append("Quest screen should still build the quest list.")

		app_shell.queue_free()

	if failures.is_empty():
		print("Phase 18 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)

	quit(1)
