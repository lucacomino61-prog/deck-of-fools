class_name PatronCards
extends RefCounted
## Card batch 10 (approved 2026-10-21): the 28 Patrons, the third show of every town.
## A Patron's hooks only fire during its own show (RunState._sources). Data: target_mult
## (default 2), min_town, finale (town 8 only), reward_bonus.

const FINALE := {"finale": true, "reward_bonus": 3}


static func register() -> void:
	# Debuffs
	var censore := func(run: RunState, _item: ItemCard) -> void:
		for card in run.full_deck:
			if run.is_face(card):
				card.debuffed = true
	_add("pt_censore", 1, {"show_start": censore})
	_add("pt_badessa", 1, _debuff_suit(PlayingCard.Suit.HEARTS))
	_add("pt_banchiere", 1, _debuff_suit(PlayingCard.Suit.DIAMONDS))
	_add("pt_capitano_giustizia", 1, _debuff_suit(PlayingCard.Suit.SPADES))
	_add("pt_guardacaccia", 1, _debuff_suit(PlayingCard.Suit.CLUBS))

	# Rules about what you play
	var critico := func(ctx: ScoreContext, _item: ItemCard) -> bool:
		return not (ctx.run.show_counters.get("types", []) as Array).has(ctx.hand_type)
	_add("pt_critico", 1, {"allows": critico})

	var purista := func(ctx: ScoreContext, _item: ItemCard) -> bool:
		var types: Array = ctx.run.show_counters.get("types", [])
		return types.is_empty() or types[0] == ctx.hand_type
	_add("pt_purista", 2, {"allows": purista})

	var gabelliere := func(run: RunState, _item: ItemCard, cards: Array) -> void:
		run.ducats -= cards.size()
	_add("pt_gabelliere", 2, {"hand_played": gabelliere})

	var avaro := func(ctx: ScoreContext, _item: ItemCard) -> void:
		var mine := ctx.run.hand_levels.times_played(ctx.hand_type)
		for hand in HandTable.ORDER:
			if ctx.run.hand_levels.times_played(hand) > mine:
				return
		ctx.run.ducats = 0
		ctx.note("ducats_lost", "pt_avaro")
	_add("pt_avaro", 6, {"before_score": avaro})

	_add("pt_fortezza", 2, {}, {"target_mult": 4.0})

	# Face down
	var spione := func(run: RunState, _item: ItemCard, cards: Array, _first: bool) -> void:
		for card: PlayingCard in cards:
			if run.rng("spione").chance(1.0 / 7.0):
				card.face_down = true
	_add("pt_spione", 2, {"cards_drawn": spione})

	var maschera_grigia := func(_run: RunState, _item: ItemCard, cards: Array, first: bool) -> void:
		if first:
			for card: PlayingCard in cards:
				card.face_down = true
	_add("pt_maschera_grigia", 2, {"cards_drawn": maschera_grigia})

	var gioco_al_buio := func(_run: RunState, _item: ItemCard, cards: Array, first: bool) -> void:
		if not first:
			for card: PlayingCard in cards:
				card.face_down = true
	_add("pt_gioco_buio", 2, {"cards_drawn": gioco_al_buio})

	var marchese := func(run: RunState, _item: ItemCard, cards: Array, _first: bool) -> void:
		for card: PlayingCard in cards:
			if run.is_face(card):
				card.face_down = true
	_add("pt_marchese", 2, {"cards_drawn": marchese})

	# Hand, discards and draws
	var ciambellano := func(ctx: ScoreContext, _item: ItemCard) -> bool:
		return ctx.played.size() == 5
	_add("pt_ciambellano", 1, {"allows": ciambellano})
	_add("pt_priore", 2, _set_stat("discards", 0))
	_add("pt_maggiordomo", 1, _add_stat("hand_size", -1))

	var borsaiolo := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		for i in mini(2, run.hand.size()):
			var card: PlayingCard = run.hand[run.rng("borsaiolo").below(run.hand.size())]
			run.hand.erase(card)
			run.discard_pile.append(card)
	_add("pt_borsaiolo", 1, {"hand_played": borsaiolo})

	_add("pt_impaziente", 3, _set_stat("draw_exact", 3))

	var contessa := _set_stat("hands", 1)
	_add("pt_contessa", 2, contessa, {"target_mult": 1.0})

	# Levels and base values
	var vescovo := func(ctx: ScoreContext, _item: ItemCard) -> void:
		ctx.run.hand_levels.level_up(ctx.hand_type, -1)
	_add("pt_vescovo", 2, {"before_score": vescovo})

	var duca := func(ctx: ScoreContext, _item: ItemCard) -> void:
		ctx.points = maxf(1.0, floorf(ctx.points / 2.0 + 0.5))
		ctx.mult = maxf(1.0, floorf(ctx.mult / 2.0 + 0.5))
		ctx.note("halved", "pt_duca")
	_add("pt_duca", 2, {"after_base": duca})

	var siniscalco := func(run: RunState, _item: ItemCard) -> void:
		for card in run.full_deck:
			if run.town_played.has(card.id):
				card.debuffed = true
	_add("pt_siniscalco", 1, {"show_start": siniscalco})

	_finales()


static func _finales() -> void:
	_add("pt_granduca", 8, {}, {"target_mult": 6.0, "finale": true, "reward_bonus": 3})

	# One random Jester stops working; a different one after each hand.
	var granduchessa_start := func(run: RunState, _item: ItemCard) -> void:
		PatronCards._disable_one_jester(run)
	var granduchessa_turn := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		for z in run.zanni:
			z.debuffed = false
		PatronCards._disable_one_jester(run)
	_add("pt_granduchessa", 8, {"show_start": granduchessa_start, "hand_played": granduchessa_turn}, FINALE)

	var inquisitore_start := func(run: RunState, _item: ItemCard) -> void:
		for card in run.full_deck:
			card.debuffed = true
	var inquisitore_sell := func(run: RunState, _item: ItemCard, sold: ItemCard) -> void:
		var d := sold.def()
		if d == null or d.kind != "zanni" or run.show_counters.has("inquisitore_lifted"):
			return
		run.show_counters["inquisitore_lifted"] = 1
		for card in run.full_deck:
			card.debuffed = false
	_add("pt_inquisitore", 8, {"show_start": inquisitore_start, "sell": inquisitore_sell}, FINALE)

	var cardinale := func(run: RunState, _item: ItemCard) -> void:
		run.rng("cardinale").shuffle(run.zanni)
		for z in run.zanni:
			z.face_down = true
	_add("pt_cardinale", 8, {"show_start": cardinale}, FINALE)

	# One card in hand is always selected: it must go in the next play or discard.
	var regina := func(run: RunState, _item: ItemCard, _cards: Array, _first: bool) -> void:
		var forced := int(run.show_counters.get("forced", -1))
		if run.hand.is_empty() or run._hand_card(forced) != null:
			return
		run.show_counters["forced"] = run.hand[run.rng("regina").below(run.hand.size())].id
	_add("pt_regina", 8, {"cards_drawn": regina}, FINALE)


static func _disable_one_jester(run: RunState) -> void:
	if not run.zanni.is_empty():
		run.zanni[run.rng("granduchessa").below(run.zanni.size())].debuffed = true


static func _debuff_suit(suit: int) -> Dictionary:
	var f := func(run: RunState, _item: ItemCard) -> void:
		for card in run.full_deck:
			if card.has_suit(suit):
				card.debuffed = true
	return {"show_start": f}


static func _set_stat(stat_name: String, value_to: int) -> Dictionary:
	var f := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value_to if stat == stat_name else value
	return {"modify_stat": f}


static func _add_stat(stat_name: String, amount: int) -> Dictionary:
	var f := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value + amount if stat == stat_name else value
	return {"modify_stat": f}


static func _add(def_id: String, min_town: int, hooks: Dictionary, data := {}) -> void:
	var full := {"min_town": min_town}
	full.merge(data, true)
	ContentDB.register(ContentDef.make(def_id, "patron", 0, 0, hooks, full))
