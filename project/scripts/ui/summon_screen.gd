extends ScrollContainer

var _status_message := ""

@onready var summary_label: Label = %SummaryLabel
@onready var pity_label: Label = %PityLabel
@onready var featured_label: Label = %FeaturedLabel
@onready var banner_list: VBoxContainer = %BannerList
@onready var exchange_single_button: Button = %ExchangeSingleButton
@onready var exchange_ten_button: Button = %ExchangeTenButton
@onready var single_pull_button: Button = %SinglePullButton
@onready var ten_pull_button: Button = %TenPullButton
@onready var result_label: Label = %ResultLabel
@onready var result_list: VBoxContainer = %ResultList


func _ready() -> void:
	exchange_single_button.pressed.connect(_on_exchange_single_pressed)
	exchange_ten_button.pressed.connect(_on_exchange_ten_pressed)
	single_pull_button.pressed.connect(_on_single_pull_pressed)
	ten_pull_button.pressed.connect(_on_ten_pull_pressed)
	if SummonState.summon_state_changed.is_connected(_refresh_screen) == false:
		SummonState.summon_state_changed.connect(_refresh_screen)
	if RewardState.rewards_changed.is_connected(_refresh_screen) == false:
		RewardState.rewards_changed.connect(_refresh_screen)
	if ProfileState.roster_changed.is_connected(_refresh_screen) == false:
		ProfileState.roster_changed.connect(_refresh_screen)
	_refresh_screen()


func configure(_metadata: Dictionary) -> void:
	pass


func _refresh_screen() -> void:
	_rebuild_banner_list()
	_refresh_banner_detail()
	_refresh_results()


func _rebuild_banner_list() -> void:
	for child in banner_list.get_children():
		child.queue_free()

	for banner in GameData.get_all_summon_banners():
		var banner_id := String(banner.get("banner_id", ""))
		var currency_name := String(banner.get("currency_name", "Tokens"))
		var button := Button.new()
		button.toggle_mode = true
		button.button_pressed = banner_id == SummonState.selected_banner_id()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0.0, 118.0)
		button.text = "%s\n%d %s  |  10x %d %s  |  Pity %d" % [
			String(banner.get("display_name", "Banner")),
			int(banner.get("cost_currency", 0)),
			currency_name,
			int(banner.get("cost_currency_ten_pull", 0)),
			currency_name,
			int(banner.get("pity_threshold", 10)),
		]
		button.pressed.connect(_on_banner_pressed.bind(banner_id))
		banner_list.add_child(button)
	ThemeManager.wire_button_feedback(banner_list)


func _refresh_banner_detail() -> void:
	var banner: Dictionary = SummonState.selected_banner()
	if banner.is_empty():
		summary_label.text = "No summon banner is currently available."
		pity_label.text = ""
		featured_label.text = ""
		exchange_single_button.disabled = true
		exchange_ten_button.disabled = true
		single_pull_button.disabled = true
		ten_pull_button.disabled = true
		return

	var currency_id := String(banner.get("currency_id", ""))
	var currency_name := String(banner.get("currency_name", "Tokens"))
	summary_label.text = "%s\n%s\nGold: %d  |  Hero XP: %d  |  Premium shards: %d\n%s: %d  |  Total pulls: %d" % [
		String(banner.get("display_name", "Banner")),
		String(banner.get("description", "")),
		RewardState.gold_balance(),
		RewardState.hero_xp_balance(),
		RewardState.premium_shard_balance(),
		currency_name,
		RewardState.banner_token_balance(currency_id),
		SummonState.total_pulls(),
	]
	pity_label.text = "Current pity: %d / %d until guaranteed Legendary\nRates: Legendary %d%%  |  Elite %d%%  |  Rare %d%%" % [
		SummonState.pity_count_for_banner(String(banner.get("banner_id", ""))),
		int(banner.get("pity_threshold", 10)),
		int(banner.get("rarity_weights", {}).get("Legendary", 0)),
		int(banner.get("rarity_weights", {}).get("Elite", 0)),
		int(banner.get("rarity_weights", {}).get("Rare", 0)),
	]
	featured_label.text = "Featured heroes:\n%s" % _featured_lines(banner)
	exchange_single_button.disabled = SummonState.can_exchange_selected_banner(1) == false
	exchange_ten_button.disabled = SummonState.can_exchange_selected_banner(10) == false
	single_pull_button.disabled = SummonState.can_pull_banner(String(banner.get("banner_id", "")), 1) == false
	ten_pull_button.disabled = SummonState.can_pull_banner(String(banner.get("banner_id", "")), 10) == false
	exchange_single_button.text = "Forge x1  (%d shards)" % int(banner.get("exchange_shards_single", 0))
	exchange_ten_button.text = "Forge x10  (%d shards)" % int(banner.get("exchange_shards_ten_pull", 0))
	single_pull_button.text = "Recruit x1  (%d %s)" % [int(banner.get("cost_currency", 0)), currency_name]
	ten_pull_button.text = "Recruit x10  (%d %s)" % [int(banner.get("cost_currency_ten_pull", 0)), currency_name]


func _refresh_results() -> void:
	for child in result_list.get_children():
		child.queue_free()

	var results := SummonState.last_results()
	if results.is_empty():
		result_label.text = "No recruits yet. Pull a banner to populate this history."
		return

	result_label.text = "Latest recruits%s" % ("" if _status_message.is_empty() else "\n%s" % _status_message)
	for entry in results:
		var button := Button.new()
		button.disabled = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0.0, 102.0)
		button.text = "%s  |  %s%s\n%s%s" % [
			String(entry.get("display_name", "Hero")),
			String(entry.get("rarity", "Rare")),
			"  |  Featured" if bool(entry.get("is_featured", false)) else "",
			_progress_summary(entry),
			_conversion_suffix(entry),
		]
		result_list.add_child(button)


func _featured_lines(banner: Dictionary) -> String:
	var lines: Array[String] = []
	for hero_id in banner.get("featured_hero_ids", []):
		var hero: Dictionary = GameData.get_hero(String(hero_id))
		if hero.is_empty():
			continue
		lines.append("%s  |  %s  |  %s  |  Stars %d  |  Copies %d" % [
			String(hero.get("display_name", hero_id)),
			String(hero.get("rarity", "Rare")),
			String(GameData.ascension_tier_data(ProfileState.hero_ascension_tier(String(hero_id))).get("label", "Base")),
			ProfileState.hero_star_rank(String(hero_id)),
			ProfileState.hero_merge_copies(String(hero_id)),
		])
	return "\n".join(lines)


func _conversion_suffix(entry: Dictionary) -> String:
	if bool(entry.get("was_converted", false)) == false:
		return ""
	return "  |  Converted to %d gold and %d hero XP" % [
		int(entry.get("bonus_gold", 0)),
		int(entry.get("bonus_hero_xp", 0)),
	]


func _progress_summary(entry: Dictionary) -> String:
	if bool(entry.get("granted_copy", false)):
		return "%s  |  Stars %d  |  Merge copies %d" % [
			String(GameData.ascension_tier_data(int(entry.get("ascension_tier", 0))).get("label", "Base")),
			int(entry.get("star_rank", 0)),
			int(entry.get("merge_copies", 0)),
		]
	return "%s  |  Stars %d" % [
		String(GameData.ascension_tier_data(int(entry.get("ascension_tier", 0))).get("label", "Base")),
		int(entry.get("star_rank", 0)),
	]


func _on_banner_pressed(banner_id: String) -> void:
	_status_message = ""
	SummonState.select_banner(banner_id)


func _on_single_pull_pressed() -> void:
	_execute_pull(1)


func _on_ten_pull_pressed() -> void:
	_execute_pull(10)


func _on_exchange_single_pressed() -> void:
	_execute_exchange(1)


func _on_exchange_ten_pressed() -> void:
	_execute_exchange(10)


func _execute_pull(pull_count: int) -> void:
	var result := SummonState.perform_pull(pull_count)
	if bool(result.get("ok", false)):
		var banner := SummonState.selected_banner()
		var currency_id := String(banner.get("currency_id", ""))
		_status_message = "Spent %d %s for %d recruit%s." % [
			int(result.get("cost", {}).get(currency_id, 0)),
			String(banner.get("currency_name", "tokens")),
			int(result.get("pull_count", 1)),
			"" if int(result.get("pull_count", 1)) == 1 else "s",
		]
	else:
		_status_message = "Not enough banner currency for this summon."
	_refresh_screen()


func _execute_exchange(pull_count: int) -> void:
	var result := SummonState.exchange_selected_banner_currency(pull_count)
	if bool(result.get("ok", false)):
		var banner := SummonState.selected_banner()
		var currency_id := String(banner.get("currency_id", ""))
		_status_message = "Spent %d premium shards for %d %s." % [
			int(result.get("spent", {}).get("premium_shards", 0)),
			int(result.get("granted", {}).get(currency_id, 0)),
			String(banner.get("currency_name", "tokens")),
		]
	else:
		_status_message = "Not enough premium shards for this exchange."
	_refresh_screen()
