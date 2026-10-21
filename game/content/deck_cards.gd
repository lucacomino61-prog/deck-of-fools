class_name DeckCards
extends RefCounted
## Card batch 11 (approved 2026-10-21): the 15 city decks. A deck can build its own cards
## ("build"), give starting cards ("run_start") and change rules for the whole run.
## Unlock conditions live in Unlocks.


static func register() -> void:
	_add("d_bergamo", _stat_add({"discards": 1}))
	_add("d_venezia", _stat_add({"hands": 1}))
	_add("d_genova", _stat_add({"start_ducats": 10}))
	_add("d_siena", _stat_set({"interest_per": 0, "hand_reward": 2, "discard_reward": 1}))
	_add("d_napoli", _stat_add({"zanni_slots": 1, "hands": -1}))

	var palermo := _stat_add({})
	palermo["run_start"] = _start_with(["w_baule"], ["t_matto", "t_matto"])
	_add("d_palermo", palermo)

	var padova := _stat_add({"consumable_slots": -1})
	padova["run_start"] = _start_with(["w_cannocchiale"], [])
	_add("d_padova", padova)

	var benevento := _stat_add({"omen_rate": 2})
	benevento["run_start"] = _start_with([], ["o_malocchio"])
	_add("d_benevento", benevento)

	var verona := func(run: RunState, _item: ItemCard) -> void:
		for s in 4:
			for r in [2, 3, 4, 5, 6, 7, 8, 9, 10, PlayingCard.ACE]:
				run.add_card(r, s)
	_add("d_verona", {"build": verona})

	var ferrara := func(run: RunState, _item: ItemCard) -> void:
		for s in [PlayingCard.Suit.SPADES, PlayingCard.Suit.HEARTS]:
			for copy in 2:
				for r in range(2, 15):
					run.add_card(r, s)
	_add("d_ferrara", {"build": ferrara})

	_add("d_bologna", {"run_start": _start_with(["w_mazzo_tarocchi", "w_mappa_celeste", "w_bottega"], [])})
	_add("d_firenze", _stat_add({"hand_size": 2, "zanni_slots": -1}))

	var roma := func(run: RunState, _item: ItemCard) -> void:
		if run.show_index == Shows.PATRON:
			run.gain_favor("f_gemello")
	_add("d_roma", {"show_end": roma})

	# Mantova evens out Points and Mult as the very last step, then doubles every target.
	var mantova := _stat_set({"target_pct": 200})
	var even_out := func(ctx: ScoreContext, _item: ItemCard) -> void:
		var middle := (ctx.points + ctx.mult) / 2.0
		ctx.points = middle
		ctx.mult = middle
		ctx.note("balanced", "d_mantova")
	mantova["before_total"] = even_out
	_add("d_mantova", mantova)

	var carnevale := func(run: RunState, _item: ItemCard) -> void:
		var r := run.rng("deck_build")
		for i in 52:
			run.add_card(2 + r.below(13), r.below(4))
	_add("d_carnevale", {"build": carnevale})


## A run_start hook that hands out Warrants and consumables.
static func _start_with(warrant_ids: Array, consumable_ids: Array) -> Callable:
	var f := func(run: RunState, _item: ItemCard) -> void:
		for w in warrant_ids:
			run.warrants.append(w)
		for c in consumable_ids:
			run.consumables.append(ItemCard.make(c, ContentDB.get_def(c).cost))
	return f


static func _stat_add(changes: Dictionary) -> Dictionary:
	var f := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value + int(changes.get(stat, 0))
	return {"modify_stat": f}


static func _stat_set(values: Dictionary) -> Dictionary:
	var f := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return int(values[stat]) if values.has(stat) else value
	return {"modify_stat": f}


static func _add(def_id: String, hooks: Dictionary) -> void:
	ContentDB.register(ContentDef.make(def_id, "deck", 0, 0, hooks))
