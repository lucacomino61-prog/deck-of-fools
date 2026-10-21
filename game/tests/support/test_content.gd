class_name TestContent
extends RefCounted
## Stand-in content for the rules tests. The real cards come from the approved batches.


static func register_all() -> void:
	ContentDB.reset()
	add_test_defs()


## The stand-ins without clearing the registry, for tests that mix them with real cards.
static func add_test_defs() -> void:
	# Zanni
	ContentDB.register(ContentDef.make("z_plus4", "zanni", 3, 0, EffectKit.flat(0, 4)))
	ContentDB.register(ContentDef.make("z_x2", "zanni", 6, 1, EffectKit.flat(0, 0, 2)))
	ContentDB.register(ContentDef.make("z_pair8", "zanni", 4, 0, EffectKit.if_hand(HandTable.PAIR, 0, 8)))
	ContentDB.register(ContentDef.make("z_kings20", "zanni", 5, 0,
		EffectKit.per_card(EffectKit.rank_in([PlayingCard.KING]), 20)))
	ContentDB.register(ContentDef.make("z_huge", "zanni", 1, 2, EffectKit.flat(0, 0, 1000000), {"in_shop": false}))

	var on_buy := func(_run: RunState, item: ItemCard, _bought: ItemCard) -> void:
		item.state["mult"] = int(item.state.get("mult", 0)) + 1
	var buyer_mult := func(ctx: ScoreContext, item: ItemCard) -> void:
		ctx.add_mult(int(item.state.get("mult", 0)), ctx.run.item_source(item))
	ContentDB.register(ContentDef.make("z_buyer", "zanni", 5, 0, {"buy": on_buy, "independent": buyer_mult}))

	var pays := func(_run: RunState, _item: ItemCard) -> int: return 2
	ContentDB.register(ContentDef.make("z_payer", "zanni", 4, 0, {"payout": pays}))

	var steel_queens := func(ctx: ScoreContext, item: ItemCard, card: PlayingCard) -> void:
		if card.rank == PlayingCard.QUEEN:
			ctx.x_mult(1.5, ctx.run.item_source(item), card.id)
	ContentDB.register(ContentDef.make("z_steel_queens", "zanni", 6, 1, {"card_held": steel_queens}))

	var echo_first := func(ctx: ScoreContext, _item: ItemCard, card: PlayingCard) -> int:
		return 1 if card == ctx.scoring[0] else 0
	ContentDB.register(ContentDef.make("z_echo_first", "zanni", 6, 1, {"retrigger_scored": echo_first}))

	# Makes every "N in M" chance certain, so chance effects can be tested exactly.
	var lucky := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value * 100 if stat == "luck" else value
	ContentDB.register(ContentDef.make("z_lucky", "zanni", 5, 0, {"modify_stat": lucky}, {"in_shop": false}))

	var bigger_hand := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value + 1 if stat == "hand_size" else value
	ContentDB.register(ContentDef.make("z_big_hand", "zanni", 5, 0, {"modify_stat": bigger_hand}))

	# Consumables
	var level_pair := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		run.hand_levels.level_up(HandTable.PAIR)
	ContentDB.register(ContentDef.make("s_pair", "sign", 3, 0, {"on_use": level_pair}))

	var one_card := func(_run: RunState, _item: ItemCard, picked: Array) -> bool: return picked.size() == 1
	var add_thirty := func(_run: RunState, _item: ItemCard, picked: Array) -> void:
		picked[0].bonus_points += 30
	ContentDB.register(ContentDef.make("t_thirty", "tarocchi", 3, 0, {"can_use": one_card, "on_use": add_thirty}))

	# Card modifiers
	ContentDB.register(ContentDef.make("enh_wild", "enhancement", 0, 0, {}, {"any_suit": true}))
	ContentDB.register(ContentDef.make("enh_stone", "enhancement", 0, 0, {},
		{"no_rank": true, "no_suit": true, "always_scores": true, "points_override": 50}))
	var red_seal := func(_ctx: ScoreContext, _item: ItemCard, _card: PlayingCard) -> int: return 1
	ContentDB.register(ContentDef.make("seal_red", "seal", 0, 0, {"retrigger_scored": red_seal}))
	var one_more_slot := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value + 1 if stat == "zanni_slots" else value
	ContentDB.register(ContentDef.make("ed_negative", "edition", 0, 0,
		{"modify_stat": one_more_slot}, {"adds_slot": true}))

	# Patrons, favors, decks
	var debuff_hearts := func(run: RunState, _item: ItemCard) -> void:
		for card in run.full_deck:
			if card.suit == PlayingCard.Suit.HEARTS:
				card.debuffed = true
	ContentDB.register(ContentDef.make("patron_hearts", "patron", 0, 0, {"show_start": debuff_hearts},
		{"target_mult": 2.0}))
	ContentDB.register(ContentDef.make("patron_finale", "patron", 0, 0, {}, {"finale": true, "target_mult": 6.0}))

	var five_ducats := func(run: RunState, _item: ItemCard) -> void:
		run.ducats += 5
	ContentDB.register(ContentDef.make("favor_cash", "favor", 0, 0, {"gain": five_ducats}))

	# A deck that starts rich and with z_huge, so replay tests can win shows through actions only.
	var rich := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return 50 if stat == "start_ducats" else value
	var give_huge := func(run: RunState, _item: ItemCard) -> void:
		run.zanni.append(ItemCard.make("z_huge", 1))
	ContentDB.register(ContentDef.make("deck_test_rich", "deck", 0, 0, {"modify_stat": rich, "run_start": give_huge}))
