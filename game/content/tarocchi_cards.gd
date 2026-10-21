class_name TarocchiCards
extends RefCounted
## Card batch 2 (approved 2026-10-21): the 22 Tarocchi, the Italian Major Arcana.
## "Selected" cards are the use action's targets, in hand order, left first.
## Registered in arcana order 0–21; keep it, pools follow registration order.

const COST := 3


static func register() -> void:
	# 0 Il Matto: up to 2 cards become random cards with a random enhancement.
	var matto := func(run: RunState, _item: ItemCard, cards: Array) -> void:
		var r := run.rng("matto")
		var enhancements := ContentDB.pool("enhancement")
		for card: PlayingCard in cards:
			card.rank = 2 + r.below(13)
			card.suit = r.below(4)
			if not enhancements.is_empty():
				card.enhancement = enhancements[r.below(enhancements.size())].id
	_add("t_matto", _between(1, 2), matto)

	_add("t_bagatto", _between(1, 1), _enhance("enh_motley"))

	# 2 La Papessa: the Sign of your most played hand.
	var papessa_can := func(run: RunState, item: ItemCard, _cards: Array) -> bool:
		return TarocchiCards.most_played(run) != "" and run.free_consumable_slots(item) > 0
	var papessa := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		run.create_consumable(SignCards.for_hand(TarocchiCards.most_played(run)))
	_add("t_papessa", papessa_can, papessa)

	_add("t_imperatrice", _between(1, 2), _enhance("enh_lacquered"))
	_add("t_imperatore", _between(1, 1), _enhance("enh_gilt"))

	# 5 Il Papa: up to 2 random Tarocchi, never itself.
	var papa_can := func(run: RunState, item: ItemCard, _cards: Array) -> bool:
		return run.free_consumable_slots(item) > 0
	var papa := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		var pool := ContentDB.pool("tarocchi", func(d: ContentDef) -> bool: return d.id != "t_papa")
		for i in 2:
			if pool.is_empty() or run.free_consumable_slots() <= 0:
				break
			run.create_consumable(pool[run.rng("papa").below(pool.size())].id)
	_add("t_papa", papa_can, papa)

	_add("t_amanti", _between(1, 2), _enhance("enh_masked"))

	# 7 Il Carro: rank +1, King to Ace, Ace to 2.
	var carro := func(_run: RunState, _item: ItemCard, cards: Array) -> void:
		for card: PlayingCard in cards:
			card.rank = 2 if card.rank == PlayingCard.ACE else card.rank + 1
	_add("t_carro", _between(1, 2), carro)

	# 8 La Giustizia: the left card becomes an exact copy of the right one.
	var giustizia := func(_run: RunState, _item: ItemCard, cards: Array) -> void:
		var left: PlayingCard = cards[0]
		var right: PlayingCard = cards[1]
		left.rank = right.rank
		left.suit = right.suit
		left.enhancement = right.enhancement
		left.edition = right.edition
		left.seal = right.seal
		left.bonus_points = right.bonus_points
	_add("t_giustizia", _between(2, 2), giustizia)

	# 9 L'Eremita: destroy up to 2 cards.
	var eremita := func(run: RunState, _item: ItemCard, cards: Array) -> void:
		for card: PlayingCard in cards:
			run.destroy_card(card)
	_add("t_eremita", _between(1, 2), eremita)

	_add("t_ruota", _between(1, 2), _enhance("enh_charmed"))
	_add("t_forza", _between(1, 1), _enhance("enh_iron"))

	# 12 L'Appeso: 1 in 4, a plain zanni gains Silvered, Opaline or Prismatic.
	var appeso_can := func(run: RunState, _item: ItemCard, _cards: Array) -> bool:
		return not TarocchiCards.plain_zanni(run).is_empty()
	var appeso := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		if not run.roll("appeso", 1, 4):
			return
		var plain := TarocchiCards.plain_zanni(run)
		var r := run.rng("appeso")
		var target: ItemCard = plain[r.below(plain.size())]
		var editions := ContentDB.pool("edition", func(d: ContentDef) -> bool: return d.data.has("appeso_weight"))
		var weights := editions.map(func(d: ContentDef) -> int: return int(d.data["appeso_weight"]))
		target.edition = editions[r.pick_weighted(weights)].id
	_add("t_appeso", appeso_can, appeso)

	# 13 La Morte: ducats equal to your zanni's sell value, max 50.
	var morte := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		var total := 0
		for z in run.zanni:
			total += z.sell_value()
		run.ducats += mini(total, 50)
	_add("t_morte", _always(), morte)

	_add("t_temperanza", _between(1, 1), _enhance("enh_mirror"))

	# 15 Il Diavolo: double your ducats, max +20.
	var diavolo := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		run.ducats += clampi(run.ducats, 0, 20)
	_add("t_diavolo", _always(), diavolo)

	_add("t_torre", _between(1, 1), _enhance("enh_marble"))
	_add("t_stella", _between(1, 3), _to_suit(PlayingCard.Suit.HEARTS))
	_add("t_luna", _between(1, 3), _to_suit(PlayingCard.Suit.SPADES))
	_add("t_sole", _between(1, 3), _to_suit(PlayingCard.Suit.DIAMONDS))

	# 20 Il Giudizio: a random zanni, if there's a free slot.
	var giudizio_can := func(run: RunState, _item: ItemCard, _cards: Array) -> bool:
		return run.zanni.size() < run.stat("zanni_slots")
	var giudizio := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		var def := run.random_zanni_def("giudizio")
		if def != null:
			run.add_zanni(def.id)
	_add("t_giudizio", giudizio_can, giudizio)

	_add("t_mondo", _between(1, 3), _to_suit(PlayingCard.Suit.CLUBS))


## The hand played most this run (the stronger one on a tie), or "" before any hand.
static func most_played(run: RunState) -> String:
	var best := ""
	var best_count := 0
	for hand in HandTable.ORDER:
		var n := run.hand_levels.times_played(hand)
		if n > 0 and n >= best_count:
			best = hand
			best_count = n
	return best


static func plain_zanni(run: RunState) -> Array[ItemCard]:
	var out: Array[ItemCard] = []
	for z in run.zanni:
		if z.edition == "":
			out.append(z)
	return out


static func _add(def_id: String, can_use: Callable, on_use: Callable) -> void:
	ContentDB.register(ContentDef.make(def_id, "tarocchi", COST, 0, {"can_use": can_use, "on_use": on_use}))


static func _between(least: int, most: int) -> Callable:
	var f := func(_run: RunState, _item: ItemCard, cards: Array) -> bool:
		return cards.size() >= least and cards.size() <= most
	return f


static func _always() -> Callable:
	return func(_run: RunState, _item: ItemCard, _cards: Array) -> bool: return true


static func _enhance(enhancement: String) -> Callable:
	var f := func(_run: RunState, _item: ItemCard, cards: Array) -> void:
		for card: PlayingCard in cards:
			card.enhancement = enhancement
	return f


static func _to_suit(suit: int) -> Callable:
	var f := func(_run: RunState, _item: ItemCard, cards: Array) -> void:
		for card: PlayingCard in cards:
			card.suit = suit
	return f
