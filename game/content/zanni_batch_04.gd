class_name ZanniBatch04
extends RefCounted
## Card batch 4 (approved 2026-10-21): 20 more uncommon Jesters (kind "zanni" in code).
## Card names and text live in i18n/cards.csv.

const UNCOMMON := 1


static func register() -> void:
	# The stage and the audience
	var claque := func(ctx: ScoreContext, item: ItemCard) -> void:
		var bonus := mini(15, floori(ctx.run.ducats / 3.0))
		if bonus > 0:
			ctx.add_mult(bonus, ctx.run.item_source(item))
	_add("z_claque", 6, {"independent": claque})

	# The hand was already counted as played when scoring began, so ties count as "most played".
	var loggione := func(ctx: ScoreContext, item: ItemCard) -> void:
		var mine := ctx.run.hand_levels.times_played(ctx.hand_type)
		for hand in HandTable.ORDER:
			if ctx.run.hand_levels.times_played(hand) > mine:
				return
		ctx.x_mult(1.5, ctx.run.item_source(item))
	_add("z_loggione", 6, {"independent": loggione})

	var prima := func(ctx: ScoreContext, _item: ItemCard, _card: PlayingCard) -> int:
		return 1 if int(ctx.run.show_counters.get("hands_played", 0)) == 0 else 0
	_add("z_prima", 7, {"retrigger_scored": prima})

	# last_hand still holds the previous hand while this one is scored.
	var copione := func(ctx: ScoreContext, item: ItemCard) -> void:
		if str(ctx.run.counters.get("last_hand", "")) == ctx.hand_type:
			ctx.add_mult(10, ctx.run.item_source(item))
	_add("z_copione", 5, {"independent": copione})

	var canovaccio := func(ctx: ScoreContext, item: ItemCard) -> void:
		var suits := 0
		for s in 4:
			for card in ctx.scoring:
				if not card.debuffed and card.has_suit(s):
					suits += 1
					break
		if suits > 0:
			ctx.add_mult(3 * suits, ctx.run.item_source(item))
	_add("z_canovaccio", 5, {"independent": canovaccio})

	_add("z_teatrino", 6, _stat_plus("shop_slots", 1))

	var impresario := func(run: RunState, _item: ItemCard) -> int:
		return run.zanni.size()
	_add("z_impresario", 5, {"payout": impresario})

	# Suits and ranks
	_add("z_scaramuccia", 6, EffectKit.per_card(EffectKit.rank_in([PlayingCard.JACK]), 0, 0, 1.2))

	var beltrame := func(ctx: ScoreContext, item: ItemCard, card: PlayingCard) -> void:
		if card.has_suit(PlayingCard.Suit.SPADES):
			ctx.add_mult(3, ctx.run.item_source(item), card.id)
	_add("z_beltrame", 5, {"card_held": beltrame})

	_add("z_lucinda", 5, EffectKit.per_card(EffectKit.suit_is(PlayingCard.Suit.HEARTS), 20, 3))

	var mercante := func(ctx: ScoreContext, item: ItemCard, card: PlayingCard) -> void:
		if card.has_suit(PlayingCard.Suit.DIAMONDS) and ctx.run.roll("mercante", 1, 3):
			ctx.add_ducats(3, ctx.run.item_source(item), card.id)
	_add("z_mercante", 5, {"card_scored": mercante})

	var moretta := func(ctx: ScoreContext, item: ItemCard) -> void:
		if ctx.played.size() == 1:
			ctx.x_mult(3, ctx.run.item_source(item))
	_add("z_moretta", 6, {"independent": moretta})

	var pappagallo := func(ctx: ScoreContext, _item: ItemCard, card: PlayingCard) -> int:
		if ctx.hand_type != HandTable.PAIR or not card.has_rank():
			return 0
		var same := 0
		for other in ctx.scoring:
			if other.has_rank() and other.rank == card.rank:
				same += 1
		return 1 if same >= 2 else 0
	_add("z_pappagallo", 6, {"retrigger_scored": pappagallo})

	# Shaping the deck
	var cerusico := func(run: RunState, _item: ItemCard, cards: Array) -> void:
		for card: PlayingCard in cards:
			if run.is_face(card):
				run.destroy_card(card)
				run.ducats += 2
	_add("z_cerusico", 5, {"discard": cerusico})

	var lelio := func(ctx: ScoreContext, item: ItemCard, card: PlayingCard) -> void:
		if card.enhancement == "enh_mirror":
			ctx.x_mult(1.5, ctx.run.item_source(item), card.id)
	_add("z_lelio", 6, {"card_scored": lelio})

	var ottavio := func(ctx: ScoreContext, item: ItemCard) -> void:
		var enhanced := 0
		for card in ctx.run.full_deck:
			if card.enhancement != "":
				enhanced += 1
		if enhanced > 0:
			ctx.add_mult(2 * enhanced, ctx.run.item_source(item))
	_add("z_ottavio", 6, {"independent": ottavio})

	var volto := func(ctx: ScoreContext, item: ItemCard, card: PlayingCard) -> void:
		if card.enhancement == "" and card.edition == "" and card.seal == "":
			ctx.add_mult(3, ctx.run.item_source(item), card.id)
	_add("z_volto", 5, {"card_scored": volto})

	# Growth
	var giangurgolo_grows := func(_run: RunState, item: ItemCard, sold: ItemCard) -> void:
		if sold != item:
			item.state["mult"] = int(item.state.get("mult", 0)) + 2
	_add("z_giangurgolo", 5, {"sell": giangurgolo_grows, "independent": _grown_mult()})

	var pasquariello_grows := func(_run: RunState, item: ItemCard) -> void:
		item.state["mult"] = int(item.state.get("mult", 0)) + 4
	_add("z_pasquariello", 5, {"skip": pasquariello_grows, "independent": _grown_mult()})

	var chiromante := func(run: RunState, _item: ItemCard, used: ItemCard) -> void:
		var used_def := used.def()
		if used_def == null or used_def.kind != "tarocchi" or run.free_consumable_slots() <= 0:
			return
		if not run.roll("chiromante", 1, 3):
			return
		var signs := ContentDB.pool("sign", func(d: ContentDef) -> bool:
			return not d.has_hook("available") or bool(d.fire("available", [run, null])))
		if not signs.is_empty():
			run.create_consumable(signs[run.rng("chiromante").below(signs.size())].id)
	_add("z_chiromante", 5, {"use": chiromante})


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


static func _add(def_id: String, cost: int, hooks: Dictionary) -> void:
	ContentDB.register(ContentDef.make(def_id, "zanni", cost, UNCOMMON, hooks))
