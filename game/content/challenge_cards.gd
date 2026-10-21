class_name ChallengeCards
extends RefCounted
## Card batch 11 (approved 2026-10-21): the 20 challenges. A challenge is a fixed run: its
## deck (data "deck"), starting set-up ("run_start", "build") and rules (any other hook).
## Start one with RunState.create(seed, def.data.deck, 1, challenge_id).

const DECK := "d_bergamo"


static func register() -> void:
	var monologo := _stats({"zanni_slots": [0, 1]})
	monologo["run_start"] = _start_with_eternal("z_prima_donna")
	_add("c_monologo", monologo)

	_add("c_tutti_fuori", _stats({"zanni_slots": [0, 0], "jesters_banned": [1, 1], "hands": [1, 0], "discards": [1, 0]}))
	_add("c_compagnia_povera", _stats({"start_ducats": [0, 0], "interest_per": [0, 0], "hands": [1, 0]}))

	_add("c_carnevale_eterno", {"run_start": _enhance_all("enh_motley")})

	var vetro := _stats({"mirror_odds": [0, 2]})
	vetro["run_start"] = _enhance_all("enh_mirror")
	_add("c_vetro_fragile", vetro)

	var marmo := func(run: RunState, _item: ItemCard) -> void:
		var deck := run.full_deck.duplicate()
		run.rng("challenge").shuffle(deck)
		for card: PlayingCard in deck.slice(0, 26):
			card.enhancement = "enh_marble"
	_add("c_teatro_marmo", {"run_start": marmo})

	var cinque := _stats({"hand_size": [0, 5]})
	var exactly_five := func(ctx: ScoreContext, _item: ItemCard) -> bool:
		return ctx.played.size() == 5
	cinque["allows"] = exactly_five
	_add("c_cinque_carte", cinque)

	var lusso := func(run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		if stat != "hand_size":
			return value
		return maxi(1, value - maxi(0, floori(run.ducats / 5.0)))
	_add("c_tassa_lusso", {"modify_stat": lusso})

	var inflate := func(run: RunState, _item: ItemCard, _bought: ItemCard) -> void:
		run.counters["inflation"] = int(run.counters.get("inflation", 0)) + 1
	var inflated := func(run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value - int(run.counters.get("inflation", 0)) if stat == "shop_discount" else value
	_add("c_inflazione", {"buy": inflate, "modify_stat": inflated})

	_add("c_ultima_replica", _stats({"hands": [0, 1], "discards": [0, 6]}))
	_add("c_solo_patroni", _stats({"all_patrons": [1, 1]}))

	var divieto := func(ctx: ScoreContext, _item: ItemCard) -> bool:
		return not (ctx.has(HandTable.STRAIGHT) or ctx.has(HandTable.FLUSH))
	_add("c_divieto", {"allows": divieto})

	_add("c_fame", _stats({"all_perishable": [1, 1]}))
	_add("c_contratto_eterno", _stats({"all_eternal": [1, 1]}))
	_add("c_noleggio", _stats({"all_rented": [1, 1]}))

	var salto := _stats({"hands": [-1, 0], "signs_banned": [1, 1]})
	var level_three := func(run: RunState, _item: ItemCard) -> void:
		for hand in HandTable.ORDER:
			run.hand_levels.level_up(hand, 2)
	salto["run_start"] = level_three
	_add("c_grande_salto", salto)

	_add("c_bancarotta", _stats({"start_ducats": [0, -20], "debt_limit": [20, 0]}))

	var notte := func(_run: RunState, _item: ItemCard, cards: Array, _first: bool) -> void:
		for card: PlayingCard in cards:
			card.face_down = true
	_add("c_notte_bianca", {"cards_drawn": notte})

	var doppio := func(run: RunState, _item: ItemCard) -> void:
		var all := []
		for s in 4:
			for r in range(2, 15):
				all.append([r, s])
		run.rng("challenge").shuffle(all)
		for pick in all.slice(0, 26):
			run.add_card(pick[0], pick[1])
			run.add_card(pick[0], pick[1])
	_add("c_mazzo_doppio", {"build": doppio})

	var finale := _stats({"start_ducats": [0, 50]})
	var gran_finale := func(run: RunState, _item: ItemCard) -> void:
		run.town = 5
		var rares := ContentDB.pool("zanni", func(d: ContentDef) -> bool: return d.rarity == 2 and not run.locked.has(d.id))
		run.rng("challenge").shuffle(rares)
		for d in rares.slice(0, 3):
			run.zanni.append(ItemCard.make(d.id, d.cost))
	finale["run_start"] = gran_finale
	_add("c_gran_finale", finale)


## Stat rules as {stat: [add, set_to]}: set_to replaces the value when it's non-zero or
## when add is 0 too (so [0, 0] sets a stat to 0); otherwise add is added.
static func _stats(rules: Dictionary) -> Dictionary:
	var f := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		if not rules.has(stat):
			return value
		var add := int(rules[stat][0])
		var set_to := int(rules[stat][1])
		if set_to != 0 or add == 0:
			return set_to
		return value + add
	return {"modify_stat": f}


static func _enhance_all(enhancement: String) -> Callable:
	var f := func(run: RunState, _item: ItemCard) -> void:
		for card in run.full_deck:
			card.enhancement = enhancement
	return f


static func _start_with_eternal(def_id: String) -> Callable:
	var f := func(run: RunState, _item: ItemCard) -> void:
		var item := ItemCard.make(def_id, ContentDB.get_def(def_id).cost)
		item.state["eternal"] = true
		run.zanni.append(item)
	return f


static func _add(def_id: String, hooks: Dictionary, deck := DECK) -> void:
	ContentDB.register(ContentDef.make(def_id, "challenge", 0, 0, hooks, {"deck": deck}))
