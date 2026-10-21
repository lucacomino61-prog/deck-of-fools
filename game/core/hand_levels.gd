class_name HandLevels
extends RefCounted
## Each poker hand's level in this run (raised by Signs) and how often it was played.

var levels: Dictionary = {}
var played: Dictionary = {}


func _init() -> void:
	for t in HandTable.ORDER:
		levels[t] = 1
		played[t] = 0


func level(hand_type: String) -> int:
	return int(levels[hand_type])


func points(hand_type: String) -> float:
	var row: Array = HandTable.BASE[hand_type]
	return float(row[0] + (level(hand_type) - 1) * row[2])


func mult(hand_type: String) -> float:
	var row: Array = HandTable.BASE[hand_type]
	return float(maxi(1, row[1] + (level(hand_type) - 1) * row[3]))


func level_up(hand_type: String, amount := 1) -> void:
	levels[hand_type] = maxi(1, level(hand_type) + amount)


func mark_played(hand_type: String) -> void:
	played[hand_type] = int(played[hand_type]) + 1


func times_played(hand_type: String) -> int:
	return int(played[hand_type])


## Secret hands stay hidden until the player has made one.
func is_visible(hand_type: String) -> bool:
	return not HandTable.SECRET.has(hand_type) or times_played(hand_type) > 0


func to_dict() -> Dictionary:
	return {"levels": levels.duplicate(), "played": played.duplicate()}


static func from_dict(d: Dictionary) -> HandLevels:
	var hl := HandLevels.new()
	for t in HandTable.ORDER:
		hl.levels[t] = int(d["levels"].get(t, 1))
		hl.played[t] = int(d["played"].get(t, 0))
	return hl
