class_name ContentTaxonomy
extends RefCounted

const RARITIES := [
	"Common",
	"Rare",
	"Elite",
	"Legendary",
]

const ROLES := [
	"Tank",
	"Warrior",
	"Ranger",
	"Mage",
	"Support",
]

const FACTIONS := [
	"Solaris",
	"Umbral",
	"Verdant Circle",
	"Tideborn",
	"Ironcrest",
	"Sky Dominion",
	"Ember Court",
]


static func is_valid_rarity(value: String) -> bool:
	return RARITIES.has(value)


static func is_valid_role(value: String) -> bool:
	return ROLES.has(value)


static func is_valid_faction(value: String) -> bool:
	return FACTIONS.has(value)

