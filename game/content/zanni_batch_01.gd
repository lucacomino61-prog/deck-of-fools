class_name ZanniBatch01
extends RefCounted
## Card batch 1 (approved 2026-10-21): the first 20 common zanni.
## Card names and text live in i18n/cards.csv.

const COMMON := 0


static func register() -> void:
	# Plain and positional
	_add("z_zanni", 2, EffectKit.flat(0, 4))

	var arlecchino := func(ctx: ScoreContext, item: ItemCard) -> void:
		var left := ctx.run.zanni.find(item)
		if left > 0:
			ctx.add_mult(2 * left, ctx.run.item_source(item))
	_add("z_arlecchino", 4, {"independent": arlecchino})

	var capitano := func(ctx: ScoreContext, item: ItemCard) -> void:
		if int(ctx.run.show_counters.get("hands_played", 0)) == 0:
			ctx.add_mult(12, ctx.run.item_source(item))
	_add("z_capitano", 4, {"independent": capitano})

	var pedrolino := func(ctx: ScoreContext, item: ItemCard) -> void:
		var before := int(ctx.run.show_counters.get("hands_played", 0))
		if before > 0:
			ctx.add_mult(3 * before, ctx.run.item_source(item))
	_add("z_pedrolino", 4, {"independent": pedrolino})

	var scapino := func(ctx: ScoreContext, item: ItemCard) -> void:
		var used := int(ctx.run.show_counters.get("discards_used", 0))
		if used > 0:
			ctx.add_mult(4 * used, ctx.run.item_source(item))
	_add("z_scapino", 4, {"independent": scapino})

	# Hand shapes
	_add("z_isabella", 3, EffectKit.if_hand(HandTable.PAIR, 15, 5))
	_add("z_flavio", 4, EffectKit.if_hand(HandTable.TWO_PAIR, 20, 6))
	_add("z_gianduja", 4, EffectKit.if_hand(HandTable.THREE_KIND, 40, 6))
	_add("z_coviello", 4, EffectKit.if_hand(HandTable.STRAIGHT, 60, 4))
	_add("z_stenterello", 4, EffectKit.if_hand(HandTable.FLUSH, 40, 5))

	var dottore := func(ctx: ScoreContext, item: ItemCard) -> void:
		if ctx.played.size() == 5:
			ctx.add_points(45, ctx.run.item_source(item))
	_add("z_dottore", 4, {"independent": dottore})

	# Cards that score
	_add("z_tartaglia", 4, EffectKit.per_card(EffectKit.rank_in([2, 3, 4]), 0, 3))
	_add("z_colombina", 5, EffectKit.per_card(EffectKit.rank_in([PlayingCard.QUEEN]), 15, 3))

	var pulcinella := func(ctx: ScoreContext, item: ItemCard, card: PlayingCard) -> void:
		var first := ctx.scoring[0]
		if first.has_suit(first.suit) and card.has_suit(first.suit):
			ctx.add_mult(2, ctx.run.item_source(item), card.id)
	_add("z_pulcinella", 5, {"card_scored": pulcinella})

	_add("z_sandrone", 3, EffectKit.per_card(EffectKit.rank_in([8, 9, 10]), 12))

	var meneghino := func(ctx: ScoreContext, item: ItemCard) -> void:
		for card in ctx.scoring:
			if ctx.run.is_face(card):
				return
		ctx.add_points(35, ctx.run.item_source(item))
	_add("z_meneghino", 3, {"independent": meneghino})

	# Money and growth
	var brighella := func(run: RunState, _item: ItemCard) -> int:
		return run.discards_left
	_add("z_brighella", 5, {"payout": brighella})

	var pantalone_grows := func(_run: RunState, item: ItemCard, _bought: ItemCard) -> void:
		item.state["mult"] = int(item.state.get("mult", 0)) + 1
	var pantalone_scores := func(ctx: ScoreContext, item: ItemCard) -> void:
		var grown := int(item.state.get("mult", 0))
		if grown > 0:
			ctx.add_mult(grown, ctx.run.item_source(item))
	_add("z_pantalone", 5, {"buy": pantalone_grows, "independent": pantalone_scores})

	var truffaldino := func(run: RunState, _item: ItemCard) -> void:
		run.ducats += 4
	_add("z_truffaldino", 4, {"skip": truffaldino})

	_add("z_mezzetino", 4, EffectKit.per_card(EffectKit.rank_in([7]), 0, 0, 1.0, 1))


static func _add(def_id: String, cost: int, hooks: Dictionary) -> void:
	ContentDB.register(ContentDef.make(def_id, "zanni", cost, COMMON, hooks))
