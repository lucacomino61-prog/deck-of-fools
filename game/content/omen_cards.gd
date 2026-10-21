class_name OmenCards
extends RefCounted
## Card batch 9 (approved 2026-10-21): the 18 Omens, Italian superstitions with a price.
## The two marked "rare_omen" only turn up through the 0.3% roll in packs (PackMaker).
## "Your hand" is the show's hand, or the hand dealt while a pack is open.

const COST := 4


static func register() -> void:
	# O1 La Maschera Divina: a legendary Jester.
	_add("o_maschera_divina", _can_create_jester(3), _create_jester(3, "maschera"), {"rare_omen": true})

	# O2 L'Eclissi: every hand gains a level.
	var eclissi := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		for hand in HandTable.ORDER:
			run.hand_levels.level_up(hand)
	_add("o_eclissi", _always(), eclissi, {"rare_omen": true})

	# O3–O5: destroy a card, add enhanced cards of one kind.
	_add("o_janara", _hand_not_empty(), _replace_with(3, [11, 12, 13], "janara"))
	_add("o_fantasma", _hand_not_empty(), _replace_with(2, [PlayingCard.ACE], "fantasma"))
	_add("o_folletto", _hand_not_empty(), _replace_with(4, [2, 3, 4, 5, 6, 7, 8, 9, 10], "folletto"))

	# O6–O9: a seal on one selected card.
	_add("o_corno", _exactly(1), _set_seal("seal_ducal"))
	_add("o_ritorno", _exactly(1), _set_seal("seal_encore"))
	_add("o_civetta", _exactly(1), _set_seal("seal_astral"))
	_add("o_sibilla", _exactly(1), _set_seal("seal_oracle"))

	# O10 Il Fuoco Fatuo: a random edition on one selected card.
	var fuoco := func(run: RunState, _item: ItemCard, cards: Array) -> void:
		var ed := OmenCards.random_card_edition(run.rng("fuoco_fatuo"))
		if ed != "":
			(cards[0] as PlayingCard).edition = ed
	_add("o_fuoco_fatuo", _exactly(1), fuoco)

	# O11 Il Patto: a rare Jester, ducats halved.
	var patto := func(run: RunState, item: ItemCard, cards: Array) -> void:
		OmenCards._create_jester(2, "patto").call(run, item, cards)
		run.ducats = int(run.ducats / 2.0)
	_add("o_patto", _can_create_jester(2), patto)

	# O12 L'Acqua Alta: the whole hand becomes one suit.
	var acqua_alta := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		var suit := run.rng("acqua_alta").below(4)
		for card in run.hand:
			card.suit = suit
	_add("o_acqua_alta", _hand_not_empty(), acqua_alta)

	# O13 La Seduta: the whole hand becomes one rank; −1 discard for the run.
	var seduta := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		var rank := 2 + run.rng("seduta").below(13)
		for card in run.hand:
			card.rank = rank
		run.change_stat_for_run("discards", -1)
	_add("o_seduta", _hand_not_empty(), seduta)

	# O14 L'Ombra: a plain Jester becomes Shadow; −1 card in hand for the run.
	var ombra_can := func(run: RunState, _item: ItemCard, _cards: Array) -> bool:
		return not TarocchiCards.plain_zanni(run).is_empty()
	var ombra := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		var plain := TarocchiCards.plain_zanni(run)
		plain[run.rng("ombra").below(plain.size())].edition = "ed_shadow"
		run.change_stat_for_run("hand_size", -1)
	_add("o_ombra", ombra_can, ombra)

	# O15 Il Vesuvio: destroy 4 cards in hand, +16 ducats.
	var vesuvio := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		OmenCards.destroy_random_in_hand(run, 4, "vesuvio")
		run.ducats += 16
	_add("o_vesuvio", _hand_not_empty(), vesuvio)

	# O16 Il Sosia: copy a random Jester, destroy the rest.
	var sosia := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		var original: ItemCard = run.zanni[run.rng("sosia").below(run.zanni.size())]
		var copy := ItemCard.make(original.def_id, original.cost, "" if original.edition == "ed_shadow" else original.edition)
		copy.state = original.state.duplicate(true)
		run.zanni.assign(OmenCards.eternal_others(run, original) + [original, copy])
	_add("o_sosia", _has_jester(), sosia)

	# O17 Il Malocchio: a random Jester becomes Prismatic, the rest are destroyed.
	var malocchio := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		var chosen: ItemCard = run.zanni[run.rng("malocchio").below(run.zanni.size())]
		chosen.edition = "ed_prismatic"
		run.zanni.assign(OmenCards.eternal_others(run, chosen) + [chosen])
	_add("o_malocchio", _has_jester(), malocchio)

	# O18 Lo Specchio Magico: 2 copies of one selected card, into your hand.
	var specchio := func(run: RunState, _item: ItemCard, cards: Array) -> void:
		for i in 2:
			run.hand.append(run.copy_card(cards[0]))
	_add("o_specchio_magico", _exactly(1), specchio)


## An edition for a playing card, weighted like L'Appeso (Silvered, Opaline, Prismatic).
static func random_card_edition(r: ZRng) -> String:
	var editions := ContentDB.pool("edition", func(d: ContentDef) -> bool: return d.data.has("appeso_weight"))
	if editions.is_empty():
		return ""
	var weights := editions.map(func(d: ContentDef) -> int: return int(d.data["appeso_weight"]))
	return editions[r.pick_weighted(weights)].id


## The other Jesters that survive "destroy all your other Jesters": the Eternal ones.
static func eternal_others(run: RunState, keep: ItemCard) -> Array:
	return run.zanni.filter(func(z: ItemCard) -> bool: return z != keep and bool(z.state.get("eternal", false)))


static func destroy_random_in_hand(run: RunState, count: int, stream: String) -> void:
	for i in mini(count, run.hand.size()):
		run.destroy_card(run.hand[run.rng(stream).below(run.hand.size())])


## Destroy 1 random card in hand, then add `count` cards with ranks from `ranks`, random
## suits and random enhancements, to the hand and the deck. Enhancements that take away
## the rank (Marble) are left out, so a promised face card or Ace stays one.
static func _replace_with(count: int, ranks: Array, stream: String) -> Callable:
	var f := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		OmenCards.destroy_random_in_hand(run, 1, stream)
		var r := run.rng(stream)
		var enhancements := ContentDB.pool("enhancement", func(d: ContentDef) -> bool:
			return not bool(d.data.get("no_rank", false)))
		for i in count:
			var card := run.add_card(ranks[r.below(ranks.size())], r.below(4))
			if not enhancements.is_empty():
				card.enhancement = enhancements[r.below(enhancements.size())].id
			run.hand.append(card)
	return f


## A random Jester of `rarity` that you don't own yet.
static func _create_jester(rarity: int, stream: String) -> Callable:
	var f := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		var pool := OmenCards._unowned(run, rarity)
		if not pool.is_empty():
			run.add_zanni(pool[run.rng(stream).below(pool.size())].id)
	return f


static func _can_create_jester(rarity: int) -> Callable:
	var f := func(run: RunState, _item: ItemCard, _cards: Array) -> bool:
		return run.zanni.size() < run.stat("zanni_slots") and not OmenCards._unowned(run, rarity).is_empty()
	return f


static func _unowned(run: RunState, rarity: int) -> Array[ContentDef]:
	var owned := {}
	for z in run.zanni:
		owned[z.def_id] = true
	return ContentDB.pool("zanni", func(d: ContentDef) -> bool:
		return d.rarity == rarity and not owned.has(d.id) and not run.locked.has(d.id))


static func _set_seal(seal: String) -> Callable:
	var f := func(_run: RunState, _item: ItemCard, cards: Array) -> void:
		(cards[0] as PlayingCard).seal = seal
	return f


static func _exactly(n: int) -> Callable:
	var f := func(_run: RunState, _item: ItemCard, cards: Array) -> bool:
		return cards.size() == n
	return f


static func _hand_not_empty() -> Callable:
	var f := func(run: RunState, _item: ItemCard, _cards: Array) -> bool:
		return not run.hand.is_empty()
	return f


static func _has_jester() -> Callable:
	var f := func(run: RunState, _item: ItemCard, _cards: Array) -> bool:
		return not run.zanni.is_empty()
	return f


static func _always() -> Callable:
	var f := func(_run: RunState, _item: ItemCard, _cards: Array) -> bool:
		return true
	return f


static func _add(def_id: String, can_use: Callable, on_use: Callable, data := {}) -> void:
	ContentDB.register(ContentDef.make(def_id, "omen", COST, 0, {"can_use": can_use, "on_use": on_use}, data))
