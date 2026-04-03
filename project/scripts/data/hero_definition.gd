class_name HeroDefinition
extends RefCounted

var hero_id: String = ""
var display_name: String = ""
var rarity: String = ""
var role: String = ""
var faction: String = ""
var base_stats: UnitStats = UnitStats.new()
var growth_per_level: UnitStats = UnitStats.new()
var ultimate_id: String = ""
var ultimate_name: String = ""
var ultimate_description: String = ""
var portrait_glyph: String = "?"
var accent_color: Color = Color("607d8b")
var lore: String = ""
var source_path: String = ""


static func from_dict(data: Dictionary, data_source_path: String = "") -> HeroDefinition:
	var definition := HeroDefinition.new()
	definition.hero_id = String(data.get("id", ""))
	definition.display_name = String(data.get("name", ""))
	definition.rarity = String(data.get("rarity", ""))
	definition.role = String(data.get("role", ""))
	definition.faction = String(data.get("faction", ""))
	definition.base_stats = UnitStats.from_dict(data.get("base_stats", {}))
	definition.growth_per_level = UnitStats.from_dict(data.get("growth", {}))
	definition.ultimate_id = String(data.get("ultimate_id", ""))
	definition.ultimate_name = String(data.get("ultimate_name", ""))
	definition.ultimate_description = String(data.get("ultimate_description", ""))
	definition.lore = String(data.get("lore", ""))
	definition.source_path = data_source_path

	var portrait_data: Dictionary = data.get("portrait", {})
	definition.portrait_glyph = String(portrait_data.get("glyph", definition.display_name.left(1)))
	definition.accent_color = Color(String(portrait_data.get("accent", "#607d8b")))

	if definition.is_valid() == false:
		push_error("Invalid hero definition at %s" % data_source_path)
		return null

	return definition


func is_valid() -> bool:
	return (
		hero_id.is_empty() == false
		and display_name.is_empty() == false
		and ContentTaxonomy.is_valid_rarity(rarity)
		and ContentTaxonomy.is_valid_role(role)
		and ContentTaxonomy.is_valid_faction(faction)
		and ultimate_id.is_empty() == false
		and ultimate_name.is_empty() == false
	)


func stats_for_level(level: int) -> UnitStats:
	var level_offset := maxi(level - 1, 0)
	return base_stats.add(growth_per_level.scaled(level_offset))


func metadata_summary() -> String:
	return "%s  |  %s  |  %s" % [rarity, role, faction]

