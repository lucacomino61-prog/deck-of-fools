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


func sell_value() -> int:
	return maxi(1, cost / 2) + int(state.get("extra_sell", 0))


func to_dict() -> Dictionary:
	return {
		"id": def_id, "ed": edition, "cost": cost, "state": state.duplicate(true),
		"debuffed": debuffed, "face_down": face_down,
	}


static func from_dict(d: Dictionary) -> ItemCard:
	var item := make(str(d["id"]), int(d["cost"]), str(d.get("ed", "")))
	item.state = (d.get("state", {}) as Dictionary).duplicate(true)
	item.debuffed = bool(d.get("debuffed", false))
	item.face_down = bool(d.get("face_down", false))
	return item
