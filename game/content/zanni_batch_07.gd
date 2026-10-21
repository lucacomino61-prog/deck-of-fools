class_name ZanniBatch07
extends RefCounted
## Card batch 7 (approved 2026-10-21): 14 common and 8 uncommon Jesters, the town around
## the theatre. Card names and text live in i18n/cards.csv.

const COMMON := 0
const UNCOMMON := 1


static func register() -> void:
	_commons()
	_uncommons()


static func _commons() -> void:
	var innamorati := func(ctx: ScoreContext, item: ItemCard) -> void:
		if ctx.played.size() == 2:
			ctx.add_mult(10, ctx.run.item_source(item))
	_add("z_innamorati", 4, {"independent": innamorati})

	_add("z_rigattiere", 4, _stat_plus("free_rerolls", 1))

	var spazzino := func(run: RunState, _item: ItemCard, cards: Array) -> void:
		if cards.size() == 5:
			run.ducats += 3
	_add("z_spazzino", 3, {"discard": spazzino})

	_add("z_principe", 4, EffectKit.per_card(EffectKit.rank_in([PlayingCard.KING]), 15, 2))
	_add("z_garzone", 4, EffectKit.per_card(EffectKit.rank_in([2, 3, 4, 5, 6, 7, 8, 9, 10]), 0, 2))

	var lavandaia := func(ctx: ScoreContext, item: ItemCard) -> void:
		if ctx.run.discards_left > 0:
			ctx.add_mult(4 * ctx.run.discards_left, ctx.run.item_source(item))
	_add("z_lavandaia", 4, {"independent": lavandaia})

	# hands_left still counts the hand being scored.
	var postino := func(ctx: ScoreContext, item: ItemCard) -> void:
		if ctx.run.hands_left > 0:
			ctx.add_points(15 * ctx.run.hands_left, ctx.run.item_source(item))
	_add("z_postino", 3, {"independent": postino})

	var cuoco := func(ctx: ScoreContext, item: ItemCard) -> void:
		var held := 0
		for c in ctx.run.consumables:
			var d := c.def()
			if d != null and (d.kind == "tarocchi" or d.kind == "sign"):
				held += 1
		if held > 0:
			ctx.add_mult(3 * held, ctx.run.item_source(item))
	_add("z_cuoco", 3, {"independent": cuoco})

	var calzolaio := func(ctx: ScoreContext, item: ItemCard, card: PlayingCard) -> void:
		if card.seal != "":
			ctx.add_mult(5, ctx.run.item_source(item), card.id)
	_add("z_calzolaio", 4, {"card_scored": calzolaio})

	var fioraia := func(run: RunState, _item: ItemCard) -> int:
		return 4 if int(run.show_counters.get("hands_played", 0)) == 1 else 0
	_add("z_fioraia", 4, {"payout": fioraia})

	var almanacchi := func(ctx: ScoreContext, item: ItemCard) -> void:
		var kinds := 0
		for hand in HandTable.ORDER:
			if ctx.run.hand_levels.times_played(hand) > 0:
				kinds += 1
		ctx.add_mult(kinds, ctx.run.item_source(item))
	_add("z_almanacchi", 4, {"independent": almanacchi})

	var sbandieratore := func(ctx: ScoreContext, item: ItemCard) -> void:
		var right := ctx.run.zanni.size() - 1 - ctx.run.zanni.find(item)
		if right > 0:
			ctx.add_points(20 * right, ctx.run.item_source(item))
	_add("z_sbandieratore", 3, {"independent": sbandieratore})

	var sarta := func(run: RunState, _item: ItemCard) -> void:
		var plain := run.full_deck.filter(func(c: PlayingCard) -> bool: return c.enhancement == "")
		if not plain.is_empty():
			var card: PlayingCard = plain[run.rng("sarta").below(plain.size())]
			card.enhancement = "enh_lacquered"
	_add("z_sarta", 4, {"show_start": sarta})

	var specchiaio := func(run: RunState, _item: ItemCard, card: PlayingCard) -> void:
		if card.enhancement == "enh_mirror":
			run.ducats += 4
	_add("z_specchiaio", 3, {"card_destroyed": specchiaio})


static func _uncommons() -> void:
	var gigante := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		if stat == "hand_size":
			return value + 2
		if stat == "hands":
			return maxi(1, value - 1)
		return value
	_add("z_gigante", 5, {"modify_stat": gigante}, UNCOMMON)

	_add("z_mecenate", 6, _stat_plus("shop_discount", 1), UNCOMMON)

	# The hand was already counted as played when scoring began.
	var straniero := func(ctx: ScoreContext, item: ItemCard) -> void:
		if ctx.run.hand_levels.times_played(ctx.hand_type) == 1:
			ctx.x_mult(2, ctx.run.item_source(item))
	_add("z_straniero", 6, {"independent": straniero}, UNCOMMON)

	var eco := func(_ctx: ScoreContext, _item: ItemCard, _card: PlayingCard) -> int:
		return 1
	_add("z_eco", 6, {"retrigger_held": eco}, UNCOMMON)

	var sagrestano := func(_ctx: ScoreContext, _item: ItemCard, card: PlayingCard) -> int:
		return 1 if card.seal != "" else 0
	_add("z_sagrestano", 6, {"retrigger_scored": sagrestano}, UNCOMMON)

	_add("z_usuraio", 4, _stat_plus("debt_limit", 20), UNCOMMON)

	var fattucchiere := func(run: RunState, _item: ItemCard) -> void:
		var pool := ContentDB.pool("tarocchi")
		if not pool.is_empty() and run.free_consumable_slots() > 0:
			run.create_consumable(pool[run.rng("fattucchiere").below(pool.size())].id)
	_add("z_fattucchiere", 5, {"skip": fattucchiere}, UNCOMMON)

	var becchino_grows := func(_run: RunState, item: ItemCard, sold: ItemCard) -> void:
		var d := sold.def()
		if sold != item and d != null and d.kind == "zanni":
			item.state["buried"] = int(item.state.get("buried", 0)) + 1
	var becchino := func(ctx: ScoreContext, item: ItemCard) -> void:
		var buried := int(item.state.get("buried", 0))
		if buried > 0:
			ctx.x_mult(1.0 + 0.2 * buried, ctx.run.item_source(item))
	_add("z_becchino", 6, {"sell": becchino_grows, "independent": becchino}, UNCOMMON)


static func _stat_plus(stat_name: String, amount: int) -> Dictionary:
	var f := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value + amount if stat == stat_name else value
	return {"modify_stat": f}


static func _add(def_id: String, cost: int, hooks: Dictionary, rarity := COMMON) -> void:
	ContentDB.register(ContentDef.make(def_id, "zanni", cost, rarity, hooks))
