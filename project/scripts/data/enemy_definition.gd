class_name EnemyDefinition
extends RefCounted

var enemy_id: String = ""
var display_name: String = ""
var role: String = ""
var faction: String = ""
var base_stats: UnitStats = UnitStats.new()
var growth_per_level: UnitStats = UnitStats.new()
var portrait_glyph: String = "?"
var accent_color: Color = Color("546e7a")
var notes: String = ""
var source_path: String = ""


static func from_dict(data: Dictionary, data_source_path: String = "") -> EnemyDefinition:
	var definition := EnemyDefinition.new()
	definition.enemy_id = String(data.get("id", ""))
	definition.display_name = String(data.get("name", ""))
	definition.role = String(data.get("role", ""))
	definition.faction = String(data.get("faction", ""))
	definition.base_stats = UnitStats.from_dict(data.get("base_stats", {}))
	definition.growth_per_level = UnitStats.from_dict(data.get("growth", {}))
	definition.notes = String(data.get("notes", ""))
	definition.source_path = data_source_path

	var portrait_data: Dictionary = data.get("portrait", {})
	definition.portrait_glyph = String(portrait_data.get("glyph", definition.display_name.left(1)))
	definition.accent_color = Color(String(portrait_data.get("accent", "#546e7a")))

	if definition.is_valid() == false:
		push_error("Invalid enemy definition at %s" % data_source_path)
		return null

	return definition


func is_valid() -> bool:
	return (
		enemy_id.is_empty() == false
		and display_name.is_empty() == false
		and ContentTaxonomy.is_valid_role(role)
		and ContentTaxonomy.is_valid_faction(faction)
	)

