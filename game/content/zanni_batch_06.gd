class_name ZanniBatch06
extends RefCounted
## Card batch 6 (approved 2026-10-21): 20 common Jesters and Tabarrino, the Clubs uncommon.
## Card names and text live in i18n/cards.csv.

const COMMON := 0
const UNCOMMON := 1


static func register() -> void:
	# Simple Mult and Points
	_add("z_lampionaio", 2, EffectKit.flat(20))

	var pagliaccio := func(ctx: ScoreContext, item: ItemCard) -> void:
		ctx.add_mult(3 * ctx.played.size(), ctx.run.item_source(item))
	_add("z_pagliaccio", 4, {"independent": pagliaccio})

	# Suits
	_add("z_fritellino", 4, EffectKit.per_card(EffectKit.suit_is(PlayingCard.Suit.CLUBS), 0, 4))
	_add("z_trivellino", 4, EffectKit.per_card(EffectKit.suit_is(PlayingCard.Suit.DIAMONDS), 25))

	var silvia := func(ctx: ScoreContext, item: ItemCard, card: PlayingCard) -> void:
		if card.has_suit(PlayingCard.Suit.HEARTS):
			ctx.add_mult(2, ctx.run.item_source(item), card.id)
	_add("z_silvia", 3, {"card_held": silvia})

	_add("z_graziano", 3, EffectKit.per_card(EffectKit.suit_is(PlayingCard.Suit.SPADES), 12, 1))

	var cassandro := func(ctx: ScoreContext, item: ItemCard) -> void:
		if not ctx.held.is_empty():
			ctx.add_mult(2 * ctx.held.size(), ctx.run.item_source(item))
	_add("z_cassandro", 4, {"independent": cassandro})

	# Big hands
	_add("z_rosaura", 4, EffectKit.if_hand(HandTable.FULL_HOUSE, 50, 8))
	_add("z_florindo", 4, EffectKit.if_hand(HandTable.FOUR_KIND, 60, 10))

	# Money and the stage crew
	var mirandolina := func(_run: RunState, _item: ItemCard) -> int:
		return 3
	_add("z_mirandolina", 4, {"payout": mirandolina})

	var bigliettaio := func(_run: RunState, item: ItemCard) -> void:
		item.state["extra_sell"] = int(item.state.get("extra_sell", 0)) + 2
	_add("z_bigliettaio", 3, {"cash_out": bigliettaio})

	var peppe_nappa := func(ctx: ScoreContext, item: ItemCard) -> void:
		if ctx.run.hands_left == 1:
			ctx.add_mult(10, ctx.run.item_source(item))
	_add("z_peppe_nappa", 3, {"independent": peppe_nappa})

	var macchinista := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value + 1 if stat == "discards" else value
	_add("z_macchinista", 4, {"modify_stat": macchinista})

	var trovarobe := func(run: RunState, _item: ItemCard) -> void:
		for c in run.consumables:
			var d := c.def()
			if d != null and (d.kind == "tarocchi" or d.kind == "sign"):
				run.ducats += 1
	_add("z_trovarobe", 3, {"show_start": trovarobe})

	var comparsa := func(ctx: ScoreContext, item: ItemCard) -> void:
		var empty := ctx.run.stat("zanni_slots") - ctx.run.zanni.size()
		if empty > 0:
			ctx.add_mult(4 * empty, ctx.run.item_source(item))
	_add("z_comparsa", 3, {"independent": comparsa})

	var mimo := func(ctx: ScoreContext, item: ItemCard) -> void:
		if ctx.hand_type == HandTable.HIGH_CARD:
			ctx.add_points(50, ctx.run.item_source(item))
	_add("z_mimo", 3, {"independent": mimo})

	var tamburino := func(ctx: ScoreContext, item: ItemCard) -> void:
		var beats := floori(ctx.run.draw_pile.size() / 5.0)
		if beats > 0:
			ctx.add_mult(beats, ctx.run.item_source(item))
	_add("z_tamburino", 3, {"independent": tamburino})

	# Suitless cards don't spoil the colour; Motley cards fit either.
	var ballerina := func(ctx: ScoreContext, item: ItemCard) -> void:
		var red := true
		var black := true
		var suited := 0
		for card in ctx.scoring:
			if card.debuffed or not card.has_suit(card.suit):
				continue
			suited += 1
			red = red and (card.has_suit(PlayingCard.Suit.HEARTS) or card.has_suit(PlayingCard.Suit.DIAMONDS))
			black = black and (card.has_suit(PlayingCard.Suit.SPADES) or card.has_suit(PlayingCard.Suit.CLUBS))
		if suited > 0 and (red or black):
			ctx.add_mult(8, ctx.run.item_source(item))
	_add("z_ballerina", 4, {"independent": ballerina})

	var burattino := func(ctx: ScoreContext, item: ItemCard) -> void:
		ctx.add_points(10 * ctx.run.zanni.size(), ctx.run.item_source(item))
	_add("z_burattino", 3, {"independent": burattino})

	var menestrello := func(run: RunState, _item: ItemCard, used: ItemCard) -> void:
		var d := used.def()
		if d != null and d.kind == "sign":
			run.ducats += 2
	_add("z_menestrello", 3, {"use": menestrello})

	# Tabarrino grows in before_score, which copiers never borrow, so a copy can't double it.
	var tabarrino_grows := func(ctx: ScoreContext, item: ItemCard) -> void:
		var clubs := 0
		for card in ctx.scoring:
			if not card.debuffed and card.has_suit(PlayingCard.Suit.CLUBS):
				clubs += 1
		if clubs > 0:
			item.state["mult"] = int(item.state.get("mult", 0)) + clubs
	var tabarrino := func(ctx: ScoreContext, item: ItemCard) -> void:
		var grown := int(item.state.get("mult", 0))
		if grown > 0:
			ctx.add_mult(grown, ctx.run.item_source(item))
	_add("z_tabarrino", 5, {"before_score": tabarrino_grows, "independent": tabarrino}, UNCOMMON)


static func _add(def_id: String, cost: int, hooks: Dictionary, rarity := COMMON) -> void:
	ContentDB.register(ContentDef.make(def_id, "zanni", cost, rarity, hooks))
