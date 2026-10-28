class_name CityCards
extends RefCounted
## Card batch 12 (approved 2026-10-22): the 24 cities of the Map of Italy. A city is a
## source for the whole town (RunState._sources): its twist changes the three shows, its
## lean changes the shop. Data: lon/lat (where it sits on the map), deck (the deck whose home
## it is), options (what it asks on arrival; RunState.town_option holds the answer).

const VENEZIA := "c_venezia"


static func register() -> void:
	_add("c_bergamo", 9.67, 45.70, "d_bergamo", _stats({"hands": 1}, {"zanni_rate_pct": 150}))
	_add("c_milano", 9.19, 45.46, "", _stats({"reward_matinee": 3, "reward_evening": 3, "reward_gala": 3, "reward_patron": 3, "pack_discount": 1}, {}, {"target_pct": 1.25}))
	_add("c_torino", 7.69, 45.07, "", _stats({}, {"tarocchi_rate_pct": 200}, {"reward_patron": 2.0}))
	_add("c_genova", 8.93, 44.41, "d_genova", _stats({"pack_discount": 1}, {}, {"sell_pct": 2.0}))

	# Carnevale: every Jester starts each show masked, until it first does something.
	var venezia := _stats({}, {}, {"edition_rate_pct": 2.0})
	venezia["show_start"] = func(run: RunState, _item: ItemCard) -> void:
		for z in run.zanni:
			z.face_down = true
	venezia["after_score"] = func(ctx: ScoreContext, _item: ItemCard) -> void:
		for z in ctx.run.zanni:
			if z.face_down and ctx.events.any(func(e: Dictionary) -> bool: return e["src"] == ctx.run.item_source(z)):
				z.face_down = false
	_add(VENEZIA, 12.33, 45.44, "d_venezia", venezia)

	_add("c_padova", 11.88, 45.41, "d_padova", _stats({}, {"sign_rate_pct": 200}, {"sign_levels": 2.0}))
	_add("c_verona", 10.99, 45.44, "d_verona", _scored_bonus(func(card: PlayingCard, _run: RunState) -> bool: return card.has_suit(PlayingCard.Suit.HEARTS), 0, 3, {"pack_hearts": 1}))

	var mantova := _stats({}, {"rare_rate_pct": 200})
	mantova["before_total"] = func(ctx: ScoreContext, _item: ItemCard) -> void:
		if int(ctx.run.show_counters.get("hands_played", 0)) == 0:
			ctx.x_mult(2.0, "city")
		if ctx.run.hands_left == 1:
			ctx.x_mult(0.5, "city")
	_add("c_mantova", 10.79, 45.16, "d_mantova", mantova)

	var ferrara := _stats({}, {"pack_card_pct": 200})
	ferrara["before_total"] = func(ctx: ScoreContext, _item: ItemCard) -> void:
		if ctx.played.size() < 2:
			return
		for i in range(1, ctx.played.size()):
			if _is_red(ctx.played[i]) == _is_red(ctx.played[i - 1]):
				return
		ctx.x_mult(1.5, "city")
	_add("c_ferrara", 11.62, 44.84, "d_ferrara", ferrara)

	# The doctors: each discard grows the hand by a card for the show, up to 2.
	var bologna := _stats({}, {"tarocchi_rate_pct": 200})
	var bologna_stats: Callable = bologna["modify_stat"]
	bologna["modify_stat"] = func(run: RunState, item: ItemCard, name: String, value: int) -> int:
		value = bologna_stats.call(run, item, name, value)
		if name == "hand_size" and run.phase == RunState.Phase.IN_SHOW:
			value += mini(int(run.show_counters.get("discards_used", 0)), 2)
		return value
	_add("c_bologna", 11.34, 44.49, "d_bologna", bologna)

	_add("c_firenze", 11.26, 43.77, "d_firenze", _scored_bonus(func(card: PlayingCard, run: RunState) -> bool: return run.is_face(card), 10, 0, {"card_rate": 6, "card_quality": 1}))

	# The Palio: the first hand of a show worth half its target pays 5 ducats.
	var siena := _stats({"reroll_discount": 1}, {})
	siena["after_score"] = func(ctx: ScoreContext, _item: ItemCard) -> void:
		var run := ctx.run
		if not run.previewing and not run.show_counters.has("palio") and ctx.total >= run.show_target / 2.0:
			run.show_counters["palio"] = true
			ctx.add_ducats(5, "city")
	_add("c_siena", 11.33, 43.32, "d_siena", siena)

	_add("c_pisa", 10.40, 43.72, "", _stats({"straight_gap": 1}, {"zanni_rate_pct": 150}))
	_add("c_lucca", 10.50, 43.84, "", _stats({"hands": 1, "discards": -1, "warrant_discount": 2}, {}))
	_add("c_roma", 12.50, 41.90, "d_roma", _stats({}, {"rare_rate_pct": 200}, {"patron_target_pct": 1.5, "reward_patron": 3.0}))

	# Vesuvius: after the second hand of each show, two cards in the draw pile turn to Marble.
	var napoli := _stats({}, {"pack_omen_pct": 400})
	napoli["hand_played"] = func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		if int(run.show_counters.get("hands_played", 0)) != 2:
			return
		var r := run.rng("vesuvio")
		for i in 2:
			var plain := run.draw_pile.filter(func(c: PlayingCard) -> bool: return c.enhancement != "enh_marble")
			if plain.is_empty():
				return
			(plain[r.below(plain.size())] as PlayingCard).enhancement = "enh_marble"
	_add("c_napoli", 14.27, 40.85, "d_napoli", napoli)

	_add("c_palermo", 13.36, 38.12, "d_palermo", _stats({"reverse_jesters": 1}, {"pack_zanni_pct": 300}))
	_add("c_benevento", 14.78, 41.13, "d_benevento", _stats({}, {"omen_rate": 3}))
	_add("c_bari", 16.87, 41.12, "", _stats({"hand_size": 1}, {"sign_rate_pct": 200}))
	_add("c_amalfi", 14.60, 40.63, "", _stats({}, {"card_rate": 6, "card_quality": 1}, {"gilt_mult": 2.0}))
	_add("c_parma", 10.33, 44.80, "", _scored_bonus(func(card: PlayingCard, _run: RunState) -> bool: return card.has_rank() and card.rank <= 10, 5, 0, {"pack_card_pct": 200}))

	var urbino := _stats({"warrant_discount": 2}, {})
	urbino["before_total"] = func(ctx: ScoreContext, _item: ItemCard) -> void:
		if ctx.played.size() == 5:
			ctx.x_mult(1.5, "city")
	_add("c_urbino", 12.64, 43.73, "", urbino)

	# The bora: each discard blows one more card out of the hand.
	var trieste := _stats({"reroll_discount": 1}, {})
	trieste["discard"] = func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		if run.hand.is_empty():
			return
		var card: PlayingCard = run.hand[run.rng("bora").below(run.hand.size())]
		run.hand.erase(card)
		run.discard_pile.append(card)
	_add("c_trieste", 13.78, 45.65, "", trieste)

	# Scylla and Charybdis: on arrival, −1 hand each show (0) or targets ×1.25 (1).
	var messina := _stats({}, {"omen_rate": 2})
	var messina_stats: Callable = messina["modify_stat"]
	messina["modify_stat"] = func(run: RunState, item: ItemCard, name: String, value: int) -> int:
		value = messina_stats.call(run, item, name, value)
		if run.town_option == 0 and name == "hands":
			value -= 1
		elif run.town_option == 1 and name == "target_pct":
			value = value * 5 / 4
		return value
	_add("c_messina", 15.55, 38.19, "", messina, ["-1 hand each show", "Targets x1.25"])


static func _add(id: String, lon: float, lat: float, deck: String, hooks: Dictionary, options: Array = []) -> void:
	ContentDB.register(ContentDef.make(id, "city", 0, 0, hooks, {"lon": lon, "lat": lat, "deck": deck, "options": options}))


## Stat changes: `add` adds, `at_least` raises to at least (shop leans), `times` multiplies.
static func _stats(add: Dictionary, at_least: Dictionary, times := {}) -> Dictionary:
	var f := func(_run: RunState, _item: ItemCard, name: String, value: int) -> int:
		if add.has(name):
			value += int(add[name])
		if at_least.has(name):
			value = maxi(value, int(at_least[name]))
		if times.has(name):
			value = int(value * float(times[name]))
		return value
	return {"modify_stat": f}


## Each scoring card that passes `test` adds Points and Mult before the cards score.
static func _scored_bonus(test: Callable, points: int, mult: int, lean: Dictionary) -> Dictionary:
	var hooks := _stats({}, lean)
	hooks["after_base"] = func(ctx: ScoreContext, _item: ItemCard) -> void:
		var n := 0
		for card in ctx.scoring:
			if not card.debuffed and test.call(card, ctx.run):
				n += 1
		if n > 0:
			ctx.bonus(points * n, mult * n, 1.0, "city")
	return hooks


static func _is_red(card: PlayingCard) -> bool:
	return card.suit == PlayingCard.Suit.HEARTS or card.suit == PlayingCard.Suit.DIAMONDS


## The city a deck starts from: its own home, a random one for the Carnevale deck, none
## for decks that aren't cities (the rules tests' stand-in).
static func home_of(deck_id: String, run: RunState) -> String:
	var homes := ContentDB.pool("city", func(d: ContentDef) -> bool: return d.data["deck"] == deck_id)
	if not homes.is_empty():
		return homes[0].id
	if deck_id == "d_carnevale":
		var any := ContentDB.pool("city", func(d: ContentDef) -> bool: return d.id != VENEZIA)
		return any[run.rng("route").below(any.size())].id if not any.is_empty() else ""
	return ""
