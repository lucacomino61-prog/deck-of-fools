class_name PackMaker
extends RefCounted
## Booster packs: which packs a shop offers, what a pack shows when opened, and random
## playing cards for Card Packs and the shop. Pack definitions (kind "pack") carry data
## {contents, show, pick, weight}; contents is tarocchi, sign, omen, zanni or card.

## Each card in a pack has this chance to be one of the two rarest Omens instead.
const RARE_OMEN_CHANCE := 0.003
## With Il Baule dei Presagi, each Tarocchi pack card has this chance to be an Omen.
const OMEN_IN_TAROCCHI_CHANCE := 0.2
## Card Pack odds for a playing card's extras; editions use the shop odds × CARD_EDITION_MULT.
const CARD_ENHANCE_CHANCE := 0.4
const CARD_SEAL_CHANCE := 0.2
const CARD_EDITION_MULT := 3.0

const MASCHERA_DIVINA := "o_maschera_divina"
const ECLISSI := "o_eclissi"


static func roll_shop_packs(run: RunState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var defs := ContentDB.pool("pack")
	if defs.is_empty():
		return out
	var banned := {"zanni": run.stat("jesters_banned") > 0, "sign": run.stat("signs_banned") > 0}
	var lean := {}
	for contents in ["tarocchi", "sign", "card", "zanni", "omen"]:
		lean[contents] = run.stat("pack_%s_pct" % contents) / 100.0
	var weights := defs.map(func(d: ContentDef) -> float:
		var contents := str(d.data["contents"])
		return 0.0 if banned.get(contents, false) else float(d.data.get("weight", 0.0)) * float(lean.get(contents, 1.0)))
	for i in run.stat("pack_slots"):
		var k := run.rng("packs").pick_weighted(weights)
		if k >= 0:
			out.append({"id": defs[k].id, "cost": defs[k].cost, "sold": false})
	return out


## What an opened pack shows: [{kind, id, edition}] or [{kind: "card", card: {...}}].
static func open(run: RunState, def: ContentDef) -> Array[Dictionary]:
	var contents := str(def.data["contents"])
	var r := run.rng("pack_" + contents)
	var out: Array[Dictionary] = []
	var taken := {}
	for i in int(def.data["show"]):
		var entry := _one(run, contents, r, taken, i)
		if entry.is_empty():
			break
		out.append(entry)
		if entry.has("id"):
			taken[entry["id"]] = true
	return out


static func _one(run: RunState, contents: String, r: ZRng, taken: Dictionary, index: int) -> Dictionary:
	match contents:
		"tarocchi":
			if r.chance(RARE_OMEN_CHANCE) and not taken.has(MASCHERA_DIVINA):
				return {"kind": "omen", "id": MASCHERA_DIVINA}
			if run.stat("omens_in_tarocchi_packs") > 0 and r.chance(OMEN_IN_TAROCCHI_CHANCE):
				var omen := _pick(_plain_omens(), r, taken)
				if omen != "":
					return {"kind": "omen", "id": omen}
			return _entry("tarocchi", _pick(ContentDB.pool("tarocchi"), r, taken))
		"sign":
			if r.chance(RARE_OMEN_CHANCE) and not taken.has(ECLISSI):
				return {"kind": "omen", "id": ECLISSI}
			if index == 0 and run.stat("sign_pack_favourite") > 0:
				var hand := TarocchiCards.most_played(run)
				if hand != "":
					return {"kind": "sign", "id": SignCards.for_hand(hand)}
			return _entry("sign", _pick(_available_signs(run), r, taken))
		"omen":
			if r.chance(RARE_OMEN_CHANCE):
				var rare := MASCHERA_DIVINA if r.chance(0.5) else ECLISSI
				if not taken.has(rare):
					return {"kind": "omen", "id": rare}
			return _entry("omen", _pick(_plain_omens(), r, taken))
		"zanni":
			var pool := run._shop_pool("zanni").filter(func(d: ContentDef) -> bool: return not taken.has(d.id))
			if pool.is_empty():
				return {}
			var typed: Array[ContentDef] = []
			typed.assign(pool)
			var by_rarity := run._pick_rarity(typed, r)
			var def: ContentDef = by_rarity[r.below(by_rarity.size())]
			var edition := run.roll_shop_edition()
			return {"kind": "zanni", "id": def.id, "edition": edition.id if edition != null else ""}
		"card":
			return {"kind": "card", "card": random_card(run, r, false)}
	return {}


## A random playing card as {rank, suit, enh, ed, seal}. `upgraded` guarantees at least one
## of the three extras.
static func random_card(run: RunState, r: ZRng, upgraded: bool) -> Dictionary:
	var card := {"rank": 2 + r.below(13), "suit": r.below(4), "enh": "", "ed": "", "seal": ""}
	if run.stat("pack_hearts") > 0 and r.chance(0.5):
		card["suit"] = PlayingCard.Suit.HEARTS
	var enhancements := ContentDB.pool("enhancement")
	var seals := ContentDB.pool("seal")
	if not enhancements.is_empty() and r.chance(CARD_ENHANCE_CHANCE):
		card["enh"] = enhancements[r.below(enhancements.size())].id
	if not seals.is_empty() and r.chance(CARD_SEAL_CHANCE):
		card["seal"] = seals[r.below(seals.size())].id
	var rate := run.stat("edition_rate_pct") / 100.0 * CARD_EDITION_MULT
	var roll := r.next_float()
	for ed in ContentDB.pool("edition", func(d: ContentDef) -> bool: return bool(d.data.get("on_cards", false))):
		roll -= float(ed.data.get("shop_chance", 0.0)) * rate
		if roll < 0.0:
			card["ed"] = ed.id
			break
	if upgraded and card["enh"] == "" and card["seal"] == "" and card["ed"] == "" and not enhancements.is_empty():
		card["enh"] = enhancements[r.below(enhancements.size())].id
	return card


static func _entry(kind: String, def_id: String) -> Dictionary:
	return {} if def_id == "" else {"kind": kind, "id": def_id}


static func _pick(pool: Array, r: ZRng, taken: Dictionary) -> String:
	var free := pool.filter(func(d: ContentDef) -> bool: return not taken.has(d.id))
	if free.is_empty():
		return ""
	return free[r.below(free.size())].id


static func _plain_omens() -> Array[ContentDef]:
	return ContentDB.pool("omen", func(d: ContentDef) -> bool: return not bool(d.data.get("rare_omen", false)))


static func _available_signs(run: RunState) -> Array[ContentDef]:
	return ContentDB.pool("sign", func(d: ContentDef) -> bool:
		return not d.has_hook("available") or bool(d.fire("available", [run, null])))
