class_name ShopState
extends RefCounted
## The shop between shows. Card offers are {kind, id, cost, edition, sold}, plus "card"
## (a {rank, suit, enh, ed, seal} description) for playing cards and "free" when a Favor
## pays for it. Packs are {id, cost, sold} (and "free"). The town's own Warrant lives on
## RunState; `extra_warrant` is a second one a Favor can add to this shop only.

var offers: Array[Dictionary] = []
var packs: Array[Dictionary] = []
var rerolls := 0
var reroll_cost := 5
var extra_warrant := ""
var extra_bought := false


func to_dict() -> Dictionary:
	return {
		"offers": offers.duplicate(true), "packs": packs.duplicate(true),
		"rerolls": rerolls, "reroll_cost": reroll_cost,
		"extra_warrant": extra_warrant, "extra_bought": extra_bought,
	}


static func from_dict(d: Dictionary) -> ShopState:
	var shop := ShopState.new()
	for o in d["offers"]:
		var offer := {
			"kind": str(o["kind"]), "id": str(o["id"]), "cost": int(o["cost"]),
			"edition": str(o["edition"]), "sold": bool(o["sold"]),
		}
		if o.has("card"):
			offer["card"] = (o["card"] as Dictionary).duplicate()
		if o.has("free"):
			offer["free"] = bool(o["free"])
		shop.offers.append(offer)
	for p in d.get("packs", []):
		var pack := {"id": str(p["id"]), "cost": int(p["cost"]), "sold": bool(p["sold"])}
		if p.has("free"):
			pack["free"] = bool(p["free"])
		shop.packs.append(pack)
	shop.rerolls = int(d["rerolls"])
	shop.reroll_cost = int(d["reroll_cost"])
	shop.extra_warrant = str(d.get("extra_warrant", ""))
	shop.extra_bought = bool(d.get("extra_bought", false))
	return shop
