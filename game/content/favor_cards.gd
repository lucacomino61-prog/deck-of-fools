class_name FavorCards
extends RefCounted
## Card batch 10 (approved 2026-10-21): the 24 Favors you take for skipping a show.
## Favors with data "pending" wait in run.favors and erase themselves when used; the rest
## act at once in "gain". L'Oroscopo names its hand when offered (data "names_hand").

const PENDING := {"pending": true}


static func register() -> void:
	# Free Jesters in the next shop
	_add("f_raccomandazione", {"shop_enter": _free_jester(1, "f_raccomandazione")}, PENDING)
	_add("f_lettera_principe", {"shop_enter": _free_jester(2, "f_lettera_principe")}, PENDING)

	# The next plain Jester in the shop gains an edition, free
	for row in [["f_velo_nero", "ed_shadow"], ["f_filo_argento", "ed_silvered"],
			["f_perla", "ed_opaline"], ["f_caleidoscopio", "ed_prismatic"]]:
		var shine := FavorCards._shine_next_jester(row[0], row[1])
		_add(row[0], {"shop_enter": shine, "reroll": shine}, PENDING)

	var dote := func(run: RunState, _item: ItemCard) -> void:
		if run.show_index == Shows.PATRON:
			run.ducats += 25
			run.favors.erase("f_dote")
	_add("f_dote", {"show_end": dote}, PENDING)

	var sigillo := func(run: RunState, _item: ItemCard) -> void:
		run.shop.extra_warrant = run._roll_warrant(run.town_warrant)
		run.shop.extra_bought = false
		run.favors.erase("f_sigillo_reale")
	_add("f_sigillo_reale", {"shop_enter": sigillo}, PENDING)

	var lasciapassare := func(run: RunState, _item: ItemCard) -> void:
		var others := run._patron_pool().filter(func(d: ContentDef) -> bool: return d.id != run.town_patron)
		if not others.is_empty():
			run.town_patron = others[run.rng("patron").below(others.size())].id
	_add("f_lasciapassare", {"gain": lasciapassare})

	# Free packs, opened at once
	_add("f_biglietto_omaggio", {"gain": _free_pack("pk_card_grand")})
	_add("f_mazzo_incantato", {"gain": _free_pack("pk_tarocchi_grand")})
	_add("f_stella_cadente", {"gain": _free_pack("pk_sign_grand")})
	_add("f_invito", {"gain": _free_pack("pk_zanni_grand")})
	_add("f_visione", {"gain": _free_pack("pk_omen_small")})

	# Money from the run so far
	var mancia := func(run: RunState, _item: ItemCard) -> void:
		run.ducats += int(run.counters.get("hands_played", 0))
	_add("f_mancia", {"gain": mancia})

	var straccio := func(run: RunState, _item: ItemCard) -> void:
		run.ducats += int(run.counters.get("discards_unused", 0))
	_add("f_straccio", {"gain": straccio})

	var fretta := func(run: RunState, _item: ItemCard) -> void:
		run.ducats += 5 * int(run.counters.get("skips", 0))
	_add("f_fretta", {"gain": fretta})

	var raddoppio := func(run: RunState, _item: ItemCard) -> void:
		run.ducats += clampi(run.ducats, 0, 40)
	_add("f_raddoppio", {"gain": raddoppio})

	# The next shop
	var buono := func(run: RunState, _item: ItemCard) -> void:
		for offer in run.shop.offers:
			offer["free"] = true
		for p in run.shop.packs:
			p["free"] = true
		run.favors.erase("f_buono")
	_add("f_buono", {"shop_enter": buono}, PENDING)

	var rimpasto := func(run: RunState, _item: ItemCard) -> void:
		run.shop.reroll_cost = 0
		run.favors.erase("f_rimpasto")
	_add("f_rimpasto", {"shop_enter": rimpasto}, PENDING)

	# Il Gemello's doubling is handled by RunState when the next Favor is taken.
	_add("f_gemello", {}, PENDING)

	# +3 cards in hand for the next show only
	var bagaglio := func(run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value + 3 if stat == "hand_size" and run.phase == RunState.Phase.IN_SHOW else value
	var bagaglio_done := func(run: RunState, _item: ItemCard) -> void:
		run.favors.erase("f_bagaglio")
	_add("f_bagaglio", {"modify_stat": bagaglio, "show_end": bagaglio_done}, PENDING)

	var rinforzo := func(run: RunState, _item: ItemCard) -> void:
		for i in 2:
			var commons := run._shop_pool("zanni").filter(func(d: ContentDef) -> bool: return d.rarity == 0)
			if commons.is_empty() or run.zanni.size() >= run.stat("zanni_slots"):
				return
			run.add_zanni(commons[run.rng("rinforzo").below(commons.size())].id)
	_add("f_rinforzo", {"gain": rinforzo})

	var oroscopo := func(run: RunState, _item: ItemCard) -> void:
		if run.favor_note != "":
			run.hand_levels.level_up(run.favor_note, 3)
	_add("f_oroscopo", {"gain": oroscopo}, {"names_hand": true})


static func _free_jester(rarity: int, favor_id: String) -> Callable:
	var f := func(run: RunState, _item: ItemCard) -> void:
		var pool := run._shop_pool("zanni").filter(func(d: ContentDef) -> bool: return d.rarity == rarity)
		if not pool.is_empty():
			var def: ContentDef = pool[run.rng("favor_shop").below(pool.size())]
			run.shop.offers.append({"kind": "zanni", "id": def.id, "cost": def.cost, "edition": "", "sold": false, "free": true})
		run.favors.erase(favor_id)
	return f


## Waits until a plain Jester is on offer, then makes it shine and free.
static func _shine_next_jester(favor_id: String, edition: String) -> Callable:
	var f := func(run: RunState, _item: ItemCard) -> void:
		for offer in run.shop.offers:
			if offer["kind"] == "zanni" and offer["edition"] == "" and not offer["sold"]:
				offer["edition"] = edition
				offer["free"] = true
				run.favors.erase(favor_id)
				return
	return f


static func _free_pack(pack_id: String) -> Callable:
	var f := func(run: RunState, _item: ItemCard) -> void:
		run.open_pack(pack_id)
	return f


static func _add(def_id: String, hooks: Dictionary, data := {}) -> void:
	ContentDB.register(ContentDef.make(def_id, "favor", 0, 0, hooks, data))
