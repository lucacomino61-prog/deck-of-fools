class_name WagonCards
extends RefCounted
## Card batch 13 (reviewed 2026-10-22): the troupe wagon. Scudi are earned at the end of
## every run (scudi_for) and spent between runs on props (small starting perks, carried one
## at a time, a second slot for PROP_SLOT_PRICE), earlier unlocks and cosmetics. A carried
## prop is a source of the run (RunState._sources) in normal runs and the campaign only.

const PROP_SLOT_PRICE := 200
## Buying something before its unlock rule says so.
const UNLOCK_PRICES := {"deck": 80, "zanni": 50, "challenge": 20}

## Scudi for a run: each show won, each Scenario performed in full, each Encore hit, and the
## run won (5, plus 1 per stake above 1).
const PER_SHOW := 1
const PER_SCENARIO := 1
const PER_ENCORE := 2
const RUN_WON := 5

## Cosmetics by slot: {id, price, colour}. Price 0 with "campaign" is a campaign reward only.
## A wagon wears one paint and any trims it owns; the show screen one cloth; the theatre
## boxes one curtain; card backs join the six in Settings.
const COSMETICS := {
	"paint": [
		{"id": "paint_rosso", "price": 20, "colour": Color(0.78, 0.16, 0.18)},
		{"id": "paint_verde", "price": 20, "colour": Color(0.2, 0.55, 0.3)},
		{"id": "paint_bianco", "price": 20, "colour": Color(0.92, 0.9, 0.84)},
		{"id": "paint_nero", "price": 20, "colour": Color(0.16, 0.15, 0.18)},
		{"id": "paint_azzurro", "price": 20, "colour": Color(0.22, 0.52, 0.78)},
		{"id": "paint_oro", "price": 0, "colour": Color(0.9, 0.72, 0.25), "campaign": true},
	],
	"trim": [
		{"id": "trim_lanterns", "price": 30, "colour": Color(1.0, 0.8, 0.35)},
		{"id": "trim_flags", "price": 30, "colour": Color(0.85, 0.25, 0.3)},
		{"id": "trim_awning", "price": 30, "colour": Color(0.95, 0.88, 0.7)},
		{"id": "trim_bells", "price": 30, "colour": Color(0.95, 0.78, 0.3)},
		{"id": "trim_sail", "price": 0, "colour": Color(0.94, 0.92, 0.85), "campaign": true},
	],
	"cloth": [
		{"id": "cloth_scarlatto", "price": 25, "colour": Color(0.62, 0.1, 0.16)},
		{"id": "cloth_smeraldo", "price": 25, "colour": Color(0.08, 0.42, 0.3)},
		{"id": "cloth_zaffiro", "price": 25, "colour": Color(0.12, 0.24, 0.58)},
		{"id": "cloth_ambra", "price": 25, "colour": Color(0.72, 0.45, 0.12)},
		{"id": "cloth_viola", "price": 25, "colour": Color(0.42, 0.16, 0.55)},
		{"id": "cloth_notte", "price": 25, "colour": Color(0.1, 0.1, 0.16)},
	],
	"back": [
		{"id": "back_maschere", "price": 40, "colour": Color(0.55, 0.12, 0.2)},
		{"id": "back_laguna", "price": 40, "colour": Color(0.1, 0.4, 0.55)},
		{"id": "back_scacchi", "price": 40, "colour": Color(0.15, 0.15, 0.18)},
		{"id": "back_limoni", "price": 40, "colour": Color(0.85, 0.7, 0.15)},
		{"id": "back_stelle", "price": 40, "colour": Color(0.12, 0.12, 0.35)},
		{"id": "back_rose", "price": 40, "colour": Color(0.75, 0.3, 0.4)},
		{"id": "back_corte", "price": 0, "colour": Color(0.3, 0.12, 0.35), "campaign": true},
	],
	"curtain": [
		{"id": "curtain_porpora", "price": 25, "colour": Color(0.5, 0.08, 0.3)},
		{"id": "curtain_blu", "price": 25, "colour": Color(0.12, 0.2, 0.5)},
		{"id": "curtain_verde", "price": 25, "colour": Color(0.1, 0.38, 0.22)},
		{"id": "curtain_oro", "price": 25, "colour": Color(0.75, 0.55, 0.15)},
	],
}

## The wagon's own wood before any paint.
const WOOD := Color(0.55, 0.36, 0.2)


static func register() -> void:
	_add("p_salvadanaio", 40, _stat_add("start_ducats", 2))
	_add("p_lanterna", 40, {}, {"lantern": true})
	var first_show := func(run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		if stat == "hands" and run.town == 1 and run.show_index == Shows.MATINEE:
			return value + 1
		return value
	_add("p_copione", 50, {"modify_stat": first_show})
	_add("p_baule", 50, _stat_add("first_shop_jesters", 1))
	_add("p_claque", 60, _stat_add("mood_start", 1))
	_add("p_suggeritore", 60, _stat_add("scenario_swaps", 1))
	var toolbox := func(run: RunState, _item: ItemCard) -> void:
		var pool := ContentDB.pool("tarocchi", func(d: ContentDef) -> bool: return not run.locked.has(d.id))
		if not pool.is_empty():
			run.create_consumable(pool[run.rng("prop").below(pool.size())].id)
	_add("p_cassetta", 60, {"run_start": toolbox})
	_add("p_mulo", 70, _stat_add("first_reroll_discount", 1))
	_add("p_bandiera", 80, {}, {"scudi_per_patron": 1})
	var portrait := func(run: RunState, _item: ItemCard) -> void:
		var pool := run._shop_pool("zanni").filter(func(d: ContentDef) -> bool: return d.rarity == 0)
		if not pool.is_empty():
			run.add_zanni(pool[run.rng("prop").below(pool.size())].id)
	_add("p_ritratto", 120, {"run_start": portrait})


static func _add(id: String, scudi: int, hooks: Dictionary, data := {}) -> void:
	ContentDB.register(ContentDef.make(id, "prop", scudi, 0, hooks, data))


static func _stat_add(stat_name: String, amount: int) -> Dictionary:
	var f := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value + amount if stat == stat_name else value
	return {"modify_stat": f}


## The scudi a finished run earns, as [{src, v}] (campaign rewards are the profile's).
static func scudi_for(run: RunState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var shows := int(run.counters.get("shows_won", 0)) * PER_SHOW
	if shows > 0:
		out.append({"src": "shows", "v": shows})
	var scenarios := int(run.counters.get("scenarios_done", 0)) * PER_SCENARIO
	if scenarios > 0:
		out.append({"src": "scenarios", "v": scenarios})
	var encores := int(run.counters.get("encores", 0)) * PER_ENCORE
	if encores > 0:
		out.append({"src": "encores", "v": encores})
	if run.won:
		out.append({"src": "won", "v": RUN_WON + run.stake - 1})
	var flag := 0
	for prop in run.props:
		var d := ContentDB.get_def(prop)
		if d != null:
			flag += int(d.data.get("scudi_per_patron", 0))
	if flag > 0 and int(run.counters.get("patrons_beaten", 0)) > 0:
		out.append({"src": "p_bandiera", "v": flag * int(run.counters["patrons_beaten"])})
	return out


## Every cosmetic as {slot, id, price, colour, campaign}.
static func all_cosmetics() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for slot in COSMETICS:
		for c in COSMETICS[slot]:
			var entry: Dictionary = (c as Dictionary).duplicate()
			entry["slot"] = slot
			entry["campaign"] = bool(c.get("campaign", false))
			out.append(entry)
	return out


static func cosmetic(id: String) -> Dictionary:
	for c in all_cosmetics():
		if c["id"] == id:
			return c
	return {}
