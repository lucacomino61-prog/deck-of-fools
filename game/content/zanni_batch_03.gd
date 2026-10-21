class_name ZanniBatch03
extends RefCounted
## Card batch 3 (approved 2026-10-21): 20 uncommon zanni, the first ×Mult.
## Card names and text live in i18n/cards.csv.

const UNCOMMON := 1


static func register() -> void:
	# ×Mult
	var capocomico := func(ctx: ScoreContext, item: ItemCard) -> void:
		if ctx.run.zanni.size() >= ctx.run.stat("zanni_slots"):
			ctx.x_mult(1.5, ctx.run.item_source(item))
	_add("z_capocomico", 6, {"independent": capocomico})

	var maschera_hands := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return maxi(1, value - 1) if stat == "hands" else value
	_add("z_maschera_nera", 7, EffectKit.flat(0, 0, 2.5).merged({"modify_stat": maschera_hands}))

	var funambolo := func(ctx: ScoreContext, item: ItemCard) -> void:
		if ctx.run.hands_left == 1:
			ctx.x_mult(2, ctx.run.item_source(item))
	_add("z_funambolo", 6, {"independent": funambolo})

	var lazzo := func(ctx: ScoreContext, item: ItemCard) -> void:
		if ctx.played.size() == 3:
			ctx.x_mult(2, ctx.run.item_source(item))
	_add("z_lazzo", 6, {"independent": lazzo})

	var fracasso := func(ctx: ScoreContext, item: ItemCard) -> void:
		if int(ctx.run.show_counters.get("discards_used", 0)) == 0:
			ctx.x_mult(1.5, ctx.run.item_source(item))
	_add("z_fracasso", 5, {"independent": fracasso})

	# Rugantino's streak counts this hand too, so the first Pair already gives ×1.15.
	var rugantino_streak := func(ctx: ScoreContext, item: ItemCard) -> void:
		item.state["streak"] = int(item.state.get("streak", 0)) + 1 if ctx.has(HandTable.PAIR) else 0
	var rugantino := func(ctx: ScoreContext, item: ItemCard) -> void:
		var streak := int(item.state.get("streak", 0))
		if streak > 0:
			ctx.x_mult(1.0 + 0.15 * streak, ctx.run.item_source(item))
	_add("z_rugantino", 6, {"before_score": rugantino_streak, "independent": rugantino})

	var mangiafuoco_feeds := func(_run: RunState, item: ItemCard, _card: PlayingCard) -> void:
		item.state["burned"] = int(item.state.get("burned", 0)) + 1
	var mangiafuoco := func(ctx: ScoreContext, item: ItemCard) -> void:
		var burned := int(item.state.get("burned", 0))
		if burned > 0:
			ctx.x_mult(1.0 + 0.25 * burned, ctx.run.item_source(item))
	_add("z_mangiafuoco", 6, {"card_destroyed": mangiafuoco_feeds, "independent": mangiafuoco})

	# Encores
	var suggeritore := func(ctx: ScoreContext, _item: ItemCard, card: PlayingCard) -> int:
		return 1 if card == ctx.scoring.back() else 0
	_add("z_suggeritore", 6, {"retrigger_scored": suggeritore})

	var trombettiere := func(_ctx: ScoreContext, _item: ItemCard, card: PlayingCard) -> int:
		return 1 if card.has_rank() and card.rank == PlayingCard.ACE else 0
	_add("z_trombettiere", 6, {"retrigger_scored": trombettiere})

	# Slots and stats
	_add("z_saltimbanco", 5, _stat_plus("hand_size", 1))
	_add("z_carro_tespi", 5, _stat_plus("consumable_slots", 1))
	_add("z_notaio", 6, _stat_plus("interest_cap", 5))

	# Money and luck
	_add("z_sipario", 5, _stat_plus("hand_reward", 1))

	var gobbo := func(ctx: ScoreContext, item: ItemCard, card: PlayingCard) -> void:
		if card.enhancement == "enh_charmed":
			ctx.add_ducats(2, ctx.run.item_source(item), card.id)
	_add("z_gobbo", 5, {"card_scored": gobbo})

	var ciarlatano := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value * 2 if stat == "luck" else value
	_add("z_ciarlatano", 6, {"modify_stat": ciarlatano})

	# Built on batch 2
	var smeraldina := func(ctx: ScoreContext, item: ItemCard, card: PlayingCard) -> void:
		if card.enhancement != "":
			ctx.add_mult(6, ctx.run.item_source(item), card.id)
	_add("z_smeraldina", 6, {"card_scored": smeraldina})

	var corallina := func(ctx: ScoreContext, item: ItemCard, card: PlayingCard) -> void:
		if card.enhancement == "enh_iron":
			ctx.x_mult(1.25, ctx.run.item_source(item), card.id)
	_add("z_corallina", 6, {"card_held": corallina})

	_add("z_vetraio", 5, _stat_plus("mirror_safe", 1))

	var cantastorie := func(ctx: ScoreContext, item: ItemCard) -> void:
		var used := int(ctx.run.counters.get("used_tarocchi", 0)) + int(ctx.run.counters.get("used_sign", 0))
		if used > 0:
			ctx.add_mult(used, ctx.run.item_source(item))
	_add("z_cantastorie", 5, {"independent": cantastorie})

	var bauta := func(ctx: ScoreContext, item: ItemCard, card: PlayingCard) -> void:
		if ctx.run.is_face(card):
			ctx.add_mult(4, ctx.run.item_source(item), card.id)
	_add("z_bauta", 5, {"card_held": bauta})


static func _stat_plus(stat_name: String, amount: int) -> Dictionary:
	var f := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value + amount if stat == stat_name else value
	return {"modify_stat": f}


static func _add(def_id: String, cost: int, hooks: Dictionary) -> void:
	ContentDB.register(ContentDef.make(def_id, "zanni", cost, UNCOMMON, hooks))
