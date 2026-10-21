class_name ZanniBatch08
extends RefCounted
## Card batch 8 (approved 2026-10-21): the last 22 Jesters (7 common, 13 uncommon, 2 rare),
## completing the set at 150. Card names and text live in i18n/cards.csv.

const COMMON := 0
const UNCOMMON := 1
const RARE := 2


static func register() -> void:
	_commons()
	_uncommons()
	_rares()


static func _commons() -> void:
	_add("z_orafo", 4, _per_enhanced("enh_gilt", 0, 0, 1.0, 3))
	_add("z_rattoppatore", 4, _per_enhanced("enh_motley", 0, 8))

	var gonfaloniere := func(run: RunState, _item: ItemCard) -> int:
		return 6 if run.show_index == Shows.PATRON else 0
	_add("z_gonfaloniere", 4, {"payout": gonfaloniere})

	var scultore := func(ctx: ScoreContext, item: ItemCard) -> void:
		var marble := ZanniBatch08._count_in_deck(ctx.run, "enh_marble")
		if marble > 0:
			ctx.add_points(25 * marble, ctx.run.item_source(item))
	_add("z_scultore", 4, {"independent": scultore})

	var mendicante := func(ctx: ScoreContext, item: ItemCard) -> void:
		if ctx.run.ducats <= 0:
			ctx.add_mult(15, ctx.run.item_source(item))
	_add("z_mendicante", 3, {"independent": mendicante})

	var merciaio_grows := func(_run: RunState, item: ItemCard) -> void:
		item.state["mult"] = int(item.state.get("mult", 0)) + 1
	_add("z_merciaio", 4, {"reroll": merciaio_grows, "independent": _grown_mult()})

	_add("z_pescivendolo", 3, EffectKit.per_card(EffectKit.rank_in([5, 6, 7]), 0, 3))


static func _uncommons() -> void:
	# Encores
	var smemorato := func(_ctx: ScoreContext, _item: ItemCard, card: PlayingCard) -> int:
		return 1 if card.has_rank() and card.rank >= 2 and card.rank <= 5 else 0
	_add("z_smemorato", 6, {"retrigger_scored": smemorato}, UNCOMMON)

	var commedia := func(ctx: ScoreContext, _item: ItemCard, card: PlayingCard) -> int:
		return 1 if ctx.run.is_face(card) else 0
	_add("z_commedia", 6, {"retrigger_scored": commedia}, UNCOMMON)

	# Card types in your deck
	_add("z_ritrattista", 5, _stat_plus("all_faces", 1), UNCOMMON)

	var fabbro := func(ctx: ScoreContext, item: ItemCard) -> void:
		var iron := ZanniBatch08._count_in_deck(ctx.run, "enh_iron")
		if iron > 0:
			ctx.x_mult(1.0 + 0.2 * iron, ctx.run.item_source(item))
	_add("z_fabbro", 7, {"independent": fabbro}, UNCOMMON)

	var gioielliere := func(ctx: ScoreContext, item: ItemCard, card: PlayingCard) -> void:
		if card.edition != "":
			ctx.x_mult(1.25, ctx.run.item_source(item), card.id)
	_add("z_gioielliere", 6, {"card_scored": gioielliere}, UNCOMMON)

	var asceta := func(ctx: ScoreContext, item: ItemCard) -> void:
		var missing := 52 - ctx.run.full_deck.size()
		if missing > 0:
			ctx.x_mult(1.0 + 0.05 * missing, ctx.run.item_source(item))
	_add("z_asceta", 6, {"independent": asceta}, UNCOMMON)

	var tipografo := func(run: RunState, _item: ItemCard) -> void:
		if run.full_deck.is_empty():
			return
		var original: PlayingCard = run.full_deck[run.rng("tipografo").below(run.full_deck.size())]
		var copy := run.add_card(original.rank, original.suit)
		copy.enhancement = original.enhancement
		copy.edition = original.edition
		copy.seal = original.seal
		copy.bonus_points = original.bonus_points
	_add("z_tipografo", 6, {"show_start": tipografo}, UNCOMMON)

	# Signs and Tarocchi
	var astronomo := func(ctx: ScoreContext, item: ItemCard) -> void:
		var extra := 0
		for hand in HandTable.ORDER:
			extra += ctx.run.hand_levels.level(hand) - 1
		if extra > 0:
			ctx.add_mult(2 * extra, ctx.run.item_source(item))
	_add("z_astronomo", 6, {"independent": astronomo}, UNCOMMON)

	var copista := func(run: RunState, _item: ItemCard, used: ItemCard) -> void:
		var d := used.def()
		if d == null or d.kind != "tarocchi" or run.show_counters.has("copista_done"):
			return
		run.show_counters["copista_done"] = 1
		run.create_consumable(used.def_id)
	_add("z_copista", 6, {"use": copista}, UNCOMMON)

	# Tricks
	var buttafuori := func(run: RunState, _item: ItemCard) -> void:
		if run.phase != RunState.Phase.IN_SHOW or run.show_index != Shows.PATRON:
			return
		run.show_counters["patron_muted"] = 1
		for card in run.full_deck:
			card.debuffed = false
		for z in run.zanni:
			z.debuffed = false
	_add("z_buttafuori", 5, {"sold": buttafuori}, UNCOMMON)

	var ruffiana := func(ctx: ScoreContext, _item: ItemCard) -> void:
		if not ctx.has(HandTable.PAIR) or ctx.scoring.is_empty():
			return
		var first := ctx.scoring[0]
		var counts := {}
		for card in ctx.scoring:
			if card.has_rank():
				counts[card.rank] = int(counts.get(card.rank, 0)) + 1
		for card in ctx.scoring:
			if card.has_rank() and int(counts[card.rank]) >= 2:
				card.suit = first.suit
	_add("z_ruffiana", 6, {"after_score": ruffiana}, UNCOMMON)

	_add("z_avvocato", 5, _stat_plus("free_single_discards", 1), UNCOMMON)

	var nonna_grows := func(_run: RunState, item: ItemCard) -> void:
		item.state["mult"] = int(item.state.get("mult", 0)) + 2
	_add("z_nonna", 5, {"cash_out": nonna_grows, "independent": _grown_mult()}, UNCOMMON)


static func _rares() -> void:
	# The second most played hand: most plays, the stronger hand winning a tie.
	var cometa := func(run: RunState, _item: ItemCard, used: ItemCard) -> void:
		var d := used.def()
		if d == null or d.kind != "sign":
			return
		var ranked: Array = HandTable.ORDER.filter(func(h: String) -> bool: return run.hand_levels.times_played(h) > 0)
		ranked.sort_custom(func(a: String, b: String) -> bool:
			var pa := run.hand_levels.times_played(a)
			var pb := run.hand_levels.times_played(b)
			if pa != pb:
				return pa > pb
			return HandTable.ORDER.find(a) > HandTable.ORDER.find(b))
		if ranked.size() >= 2:
			run.hand_levels.level_up(ranked[1])
	_add("z_cometa", 8, {"use": cometa}, RARE)

	var prima_donna := func(ctx: ScoreContext, item: ItemCard) -> void:
		ctx.x_mult(4 if ctx.run.zanni.size() == 1 else 2, ctx.run.item_source(item))
	_add("z_prima_donna", 8, {"independent": prima_donna}, RARE)


static func _count_in_deck(run: RunState, enhancement: String) -> int:
	var n := 0
	for card in run.full_deck:
		if card.enhancement == enhancement:
			n += 1
	return n


## Each scored card with `enhancement` adds the bonus (and optional ducats).
static func _per_enhanced(enhancement: String, points := 0.0, mult := 0.0, xmult := 1.0, ducats := 0) -> Dictionary:
	var test := func(card: PlayingCard) -> bool: return card.enhancement == enhancement
	return EffectKit.per_card(test, points, mult, xmult, ducats)


## Adds the Mult this copy has grown, kept in state["mult"].
static func _grown_mult() -> Callable:
	var f := func(ctx: ScoreContext, item: ItemCard) -> void:
		var grown := int(item.state.get("mult", 0))
		if grown > 0:
			ctx.add_mult(grown, ctx.run.item_source(item))
	return f


static func _stat_plus(stat_name: String, amount: int) -> Dictionary:
	var f := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value + amount if stat == stat_name else value
	return {"modify_stat": f}


static func _add(def_id: String, cost: int, hooks: Dictionary, rarity := COMMON) -> void:
	ContentDB.register(ContentDef.make(def_id, "zanni", cost, rarity, hooks))
