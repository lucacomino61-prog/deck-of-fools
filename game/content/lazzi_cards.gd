class_name LazziCards
extends RefCounted
## Card batch 12 (approved 2026-10-22): the 15 Lazzi, classic commedia duos. Owning both
## Jesters of a duo, you can merge them in the shop (RunState._merge) into one card that
## takes one slot and keeps both effects, about 1.5× stronger: while a duo fires, the run's
## duo_scale grows every Points, Mult, ×Mult and ducat amount its Jesters add (rounded),
## and makes their chances one step better. Counts (retriggers, levels, slots) stay as they
## are. Data: parts, the two Jesters in order.

const SCALE := 1.5
## Hooks that return nothing, by how many arguments follow (subject, item).
const PLAIN_HOOKS := ["independent", "before_score", "after_base", "scored", "before_total", "after_score",
	"run_start", "show_start", "show_end", "cash_out", "skip", "reroll", "shop_enter", "sold"]
const ONE_ARG_HOOKS := ["card_scored", "card_held", "discard", "buy", "sell", "use", "card_destroyed", "hand_played"]


static func register() -> void:
	var hooks := _fan_hooks()
	_add("lz_sposi", "z_arlecchino", "z_colombina", hooks)
	_add("lz_vecchi", "z_pantalone", "z_dottore", hooks)
	_add("lz_isabella_flavio", "z_isabella", "z_flavio", hooks)
	_add("lz_bravacci", "z_capitano", "z_scaramuccia", hooks)
	_add("lz_due_zanni", "z_brighella", "z_truffaldino", hooks)
	_add("lz_napoli", "z_pulcinella", "z_coviello", hooks)
	_add("lz_pierrot", "z_pedrolino", "z_pagliaccio", hooks)
	_add("lz_sorpresa", "z_lelio", "z_silvia", hooks)
	_add("lz_vedova", "z_rosaura", "z_florindo", hooks)
	_add("lz_tartaglia", "z_tartaglia", "z_principe", hooks)
	_add("lz_locandiera", "z_mirandolina", "z_mercante", hooks)
	_add("lz_gelosi", "z_andreini", "z_scala", hooks)
	_add("lz_rivalita", "z_goldoni", "z_gozzi", hooks)
	_add("lz_burattini", "z_burattinaio", "z_burattino", hooks)
	_add("lz_primo_arlecchino", "z_martinelli", "z_arlecchino", hooks)


static func _add(id: String, a: String, b: String, hooks: Dictionary) -> void:
	var rarity := 0
	for part in [a, b]:
		var d := ContentDB.get_def(part)
		if d != null:
			rarity = maxi(rarity, d.rarity)
	ContentDB.register(ContentDef.make(id, "lazzo", 0, rarity, hooks, {"parts": [a, b]}))


## The duo two Jesters make, in either order; "" if they have none.
static func duo_of(a: String, b: String) -> String:
	for d in ContentDB.pool("lazzo"):
		var parts: Array = d.data["parts"]
		if (parts[0] == a and parts[1] == b) or (parts[0] == b and parts[1] == a):
			return d.id
	return ""


## Every duo one of your Jesters could make with another one you own: [{duo, index, other}].
static func merges_for(run: RunState, index: int) -> Array:
	var out := []
	if not run.has_part("lazzi"):
		return out
	if index < 0 or index >= run.zanni.size() or not run.zanni[index].parts.is_empty():
		return out
	for j in run.zanni.size():
		if j != index and run.zanni[j].parts.is_empty():
			var duo := duo_of(run.zanni[index].def_id, run.zanni[j].def_id)
			if duo != "":
				out.append({"duo": duo, "index": index, "other": j})
	return out


## The same hooks serve every duo: each fires the hook on both Jesters inside it.
static func _fan_hooks() -> Dictionary:
	var h := {}
	for hook: String in PLAIN_HOOKS:
		h[hook] = func(subject: Object, item: ItemCard) -> void:
			_fan(subject, item, hook, [])
	for hook: String in ONE_ARG_HOOKS:
		h[hook] = func(subject: Object, item: ItemCard, x: Variant) -> void:
			_fan(subject, item, hook, [x])
	h["cards_drawn"] = func(subject: Object, item: ItemCard, cards: Array, first: bool) -> void:
		_fan(subject, item, "cards_drawn", [cards, first])
	for hook: String in ["retrigger_scored", "retrigger_held"]:
		h[hook] = func(subject: Object, item: ItemCard, card: PlayingCard) -> int:
			var total := 0
			for v: Variant in _fan(subject, item, hook, [card], false):
				if v != null:
					total += int(v)
			return total
	h["payout"] = func(run: RunState, item: ItemCard) -> int:
		var total := 0
		for v: Variant in _fan(run, item, "payout", [], false):
			if v != null:
				total += int(v)
		return roundi(total * scale_of(run, item))
	h["modify_stat"] = func(run: RunState, item: ItemCard, name: String, value: int) -> int:
		for part in item.parts:
			var d := part.def()
			if d != null and d.has_hook("modify_stat"):
				value = int(d.fire("modify_stat", [run, part, name, value]))
		return value
	h["allows"] = func(ctx: ScoreContext, item: ItemCard) -> bool:
		for v: Variant in _fan(ctx, item, "allows", [], false):
			if v is bool and not v:
				return false
		return true
	h["rescue"] = func(run: RunState, item: ItemCard) -> bool:
		for part in item.parts:
			var saves: Variant = part.fire("rescue", [run, part])
			if saves is bool and saves:
				return true
		return false
	return h


## How much a duo grows its Jesters: 1.5, or 1.75 when both are Maestri (batch 13).
static func scale_of(run: RunState, duo: ItemCard) -> float:
	if not duo.parts.is_empty() and duo.parts.all(func(p: ItemCard) -> bool: return run.maestri.has(p.def_id)):
		return Fame.DUO_SCALE
	return SCALE


## Fires `hook` on each Jester inside the duo, with its numbers grown (`grow`) and its
## scoring events labelled as the duo's. Ducats a run hook hands out directly grow too.
## Returns each Jester's answer.
static func _fan(subject: Object, duo: ItemCard, hook: String, extra: Array, grow := true) -> Array:
	var run: RunState = subject if subject is RunState else (subject as ScoreContext).run
	var scale := scale_of(run, duo)
	var outer_scale := run.duo_scale
	var outer_label := run._copy_label
	var outer_in_duo := run._in_duo
	var ducats_before := run.ducats
	if grow:
		run.duo_scale = scale
	run._in_duo = true
	if outer_label == "":
		run._copy_label = "zanni:%s#%d" % [duo.def_id, run.position_of(duo)]
	var answers := []
	for part in duo.parts:
		answers.append(run.fire_item(part, hook, subject, extra))
	run.duo_scale = outer_scale
	run._copy_label = outer_label
	run._in_duo = outer_in_duo
	if grow and subject is RunState and run.ducats != ducats_before:
		run.ducats += roundi((run.ducats - ducats_before) * (scale - 1.0))
	return answers
