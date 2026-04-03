class_name UnitStats
extends RefCounted

var hp: int = 0
var attack: int = 0
var defense: int = 0
var speed: int = 0


static func from_dict(data: Dictionary) -> UnitStats:
	var stats := UnitStats.new()
	stats.hp = int(data.get("hp", 0))
	stats.attack = int(data.get("attack", 0))
	stats.defense = int(data.get("defense", 0))
	stats.speed = int(data.get("speed", 0))
	return stats


func scaled(multiplier: int) -> UnitStats:
	var result := UnitStats.new()
	result.hp = hp * multiplier
	result.attack = attack * multiplier
	result.defense = defense * multiplier
	result.speed = speed * multiplier
	return result


func add(other: UnitStats) -> UnitStats:
	var result := UnitStats.new()
	result.hp = hp + other.hp
	result.attack = attack + other.attack
	result.defense = defense + other.defense
	result.speed = speed + other.speed
	return result


func summary_lines() -> Array[String]:
	return [
		"HP: %d" % hp,
		"ATK: %d" % attack,
		"DEF: %d" % defense,
		"SPD: %d" % speed,
	]

