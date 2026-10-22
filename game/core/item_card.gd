class_name ItemCard
extends RefCounted
## A zanni or consumable the player owns. `state` holds per-copy counters that effects
## grow during a run (e.g. "+1 Mult per purchase"); it is saved with the run.

var def_id := ""
var edition := ""
var cost := 0
var state: Dictionary = {}
var debuffed := false
## Turned face down by a Patron: still works, the screen hides which Jester it is.
var face_down := false
## A duo (Lazzo, kind "lazzo") holds the two Jesters merged into it, each with its own state.
var parts: Array[ItemCard] = []


static func make(item_def_id: String, item_cost: int, item_edition := "") -> ItemCard:
	var item := ItemCard.new()
	item.def_id = item_def_id
	item.cost = item_cost
	item.edition = item_edition
	return item


func def() -> ContentDef:
	return ContentDB.get_def(def_id)


func fire(hook: String, args: Array) -> Variant:
	var d := def()
	return d.fire(hook, args) if d != null else null


## A duo sells for its two Jesters together.
func sell_value() -> int:
	var base := maxi(1, cost / 2)
	if not parts.is_empty():
		base = 0
		for part in parts:
			base += part.sell_value()
	return base + int(state.get("extra_sell", 0))


func to_dict() -> Dictionary:
	var d := {
		"id": def_id, "ed": edition, "cost": cost, "state": state.duplicate(true),
		"debuffed": debuffed, "face_down": face_down,
	}
	if not parts.is_empty():
		d["parts"] = parts.map(func(p: ItemCard) -> Dictionary: return p.to_dict())
	return d


static func from_dict(d: Dictionary) -> ItemCard:
	var item := make(str(d["id"]), int(d["cost"]), str(d.get("ed", "")))
	item.state = (d.get("state", {}) as Dictionary).duplicate(true)
	item.debuffed = bool(d.get("debuffed", false))
	item.face_down = bool(d.get("face_down", false))
	for p in d.get("parts", []):
		item.parts.append(from_dict(p))
	return item
