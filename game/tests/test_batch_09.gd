extends TestCase
## Card batch 9: Omens, Warrants and booster packs do what cards/batch-09.md says.


func _run(zanni_ids := [], seed_text := "BATCH9") -> RunState:
	ContentPacks.register_all()
	TestContent.add_test_defs()
	var run := RunState.create(seed_text)
	for z in zanni_ids:
		run.zanni.append(ItemCard.make(z, ContentDB.get_def(z).cost))
	return run


func _to_shop(run: RunState, ducats := 100) -> void:
	run.phase = RunState.Phase.CASH_OUT
	run.apply({"a": "cash_out"})
	run.ducats = ducats


## Puts one pack on the shelf and opens it.
func _open(run: RunState, pack_id: String) -> Dictionary:
	run.shop.packs.assign([{"id": pack_id, "cost": ContentDB.get_def(pack_id).cost, "sold": false}])
	return run.apply({"a": "buy_pack", "slot": 0})


## Uses an Omen from the consumable slots on `targets`.
func _omen(run: RunState, id: String, targets: Array = []) -> bool:
	run.consumables.append(ItemCard.make(id, 4))
	var done: bool = run.apply({"a": "use", "index": run.consumables.size() - 1, "cards": ids(targets)})["ok"]
	if not done:
		run.consumables.pop_back()
	return done


func _in_show(zanni_ids := []) -> RunState:
	var run := _run(zanni_ids)
	run.apply({"a": "select_show"})
	return run


func _own(run: RunState, warrant_ids: Array) -> void:
	for w in warrant_ids:
		run.warrants.append(w)


# --- content ---

func test_batch_contents() -> void:
	ContentPacks.register_all()
	var omens := ContentDB.pool("omen")
	eq(omens.size(), 18, "18 Omens")
	ok(omens.all(func(d: ContentDef) -> bool: return d.cost == 4), "Omens cost 4")
	eq(omens.filter(func(d: ContentDef) -> bool: return d.data.get("rare_omen", false)).size(), 2, "two rare Omens")
	var warrants := ContentDB.pool("warrant")
	eq(warrants.size(), 32, "32 Warrants")
	ok(warrants.all(func(d: ContentDef) -> bool: return d.cost == 10), "Warrants cost 10")
	var upgrades := warrants.filter(func(d: ContentDef) -> bool: return d.data.has("requires"))
	eq(upgrades.size(), 16, "16 upgrades")
	ok(upgrades.all(func(d: ContentDef) -> bool: return ContentDB.get_def(d.data["requires"]) != null), "each names a real base")
	eq(ContentDB.pool("pack").size(), 15, "5 pack kinds x 3 sizes")


func test_every_card_has_text() -> void:
	ContentPacks.register_all()
	var keys := {}
	var f := FileAccess.open("res://i18n/cards.csv", FileAccess.READ)
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() >= 2 and line[1] != "":
			keys[line[0]] = true
	for kind in ["omen", "warrant", "pack"]:
		for d in ContentDB.pool(kind):
			ok(keys.has(d.id + ".name") and keys.has(d.id + ".text"), d.id + " has a name and text")


# --- packs ---

func test_shop_offers_two_packs() -> void:
	var run := _run()
	_to_shop(run)
	eq(run.shop.packs.size(), 2, "two packs on the shelf")
	ok(run.shop.packs.all(func(p: Dictionary) -> bool: return ContentDB.get_def(p["id"]).kind == "pack"), "real packs")


func test_tarocchi_pack_deals_a_hand_and_uses_the_pick() -> void:
	var run := _run()
	_to_shop(run)
	ok(_open(run, "pk_tarocchi_small")["ok"], "opened")
	eq(run.phase, RunState.Phase.PACK, "a pack is open")
	eq(run.ducats, 96, "paid 4")
	eq(run.hand.size(), 8, "8 cards dealt to target")
	eq(run.pack["items"].size(), 3, "three Tarocchi shown")
	run.pack["items"][0] = {"kind": "tarocchi", "id": "t_stella"}
	var targets := run.hand.slice(0, 3)
	ok(run.apply({"a": "pick", "index": 0, "cards": ids(targets)})["ok"], "picked and used")
	ok(targets.all(func(c: PlayingCard) -> bool: return c.suit == PlayingCard.Suit.HEARTS), "La Stella worked")
	eq(run.phase, RunState.Phase.SHOP, "one pick, so the pack closed")
	eq(run.hand.size(), 0, "the dealt hand went back")
	eq(run.counters.get("used_tarocchi"), 1, "counted as a Tarocchi use")


func test_grand_pack_two_picks_and_skip() -> void:
	var run := _run()
	_to_shop(run)
	_open(run, "pk_sign_grand")
	eq(run.pack["items"].size(), 5, "five Signs shown")
	run.apply({"a": "pick", "index": 0})
	eq(run.phase, RunState.Phase.PACK, "still open after the first pick")
	run.apply({"a": "pick", "index": 0})
	eq(run.phase, RunState.Phase.SHOP, "closed after the second")
	_open(run, "pk_sign_small")
	ok(run.apply({"a": "skip_pack"})["ok"], "a pack can be skipped")
	eq(run.phase, RunState.Phase.SHOP, "back in the shop")


func test_sign_pack_levels_the_hand() -> void:
	var run := _run()
	_to_shop(run)
	_open(run, "pk_sign_small")
	run.pack["items"][0] = {"kind": "sign", "id": "s_gemini"}
	run.apply({"a": "pick", "index": 0})
	eq(run.hand_levels.level(HandTable.PAIR), 2, "Gemini used at once")


func test_jester_and_card_packs() -> void:
	var run := _run()
	_to_shop(run)
	_open(run, "pk_zanni_small")
	var entry: Dictionary = run.pack["items"][0]
	run.apply({"a": "pick", "index": 0})
	eq(run.zanni.size(), 1, "the Jester joined the troupe")
	eq(run.zanni[0].def_id, entry["id"], "the one picked")

	_open(run, "pk_card_small")
	run.apply({"a": "pick", "index": 0})
	eq(run.full_deck.size(), 53, "the card joined the deck")

	var full := _run(["z_payer", "z_payer", "z_payer", "z_payer", "z_payer"])
	_to_shop(full)
	_open(full, "pk_zanni_small")
	full.pack["items"][0]["edition"] = ""
	ok(not full.apply({"a": "pick", "index": 0})["ok"], "no free slot, no pick")


func test_rare_omens_are_rare_in_omen_packs() -> void:
	var rare := 0
	var shown := 0
	for i in 60:
		var run := _run([], "OMENS-%d" % i)
		_to_shop(run)
		_open(run, "pk_omen_big")
		for entry in run.pack["items"]:
			shown += 1
			if ContentDB.get_def(entry["id"]).data.get("rare_omen", false):
				rare += 1
	eq(shown, 240, "four Omens per big pack")
	ok(rare <= 5, "rare Omens stay rare: %d of %d" % [rare, shown])


func test_pack_save_round_trip() -> void:
	var run := _run()
	_to_shop(run)
	_open(run, "pk_card_big")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(run.to_dict()))
	var loaded := RunState.from_dict(saved)
	eq(JSON.stringify(loaded.to_dict()), JSON.stringify(run.to_dict()), "an open pack survives a save")
	loaded.apply({"a": "pick", "index": 0})
	run.apply({"a": "pick", "index": 0})
	eq(JSON.stringify(loaded.to_dict()), JSON.stringify(run.to_dict()), "and plays on identically")


# --- warrants ---

func test_one_warrant_per_town() -> void:
	var run := _run()
	ok(run.town_warrant != "", "a Warrant is on sale")
	ok(not ContentDB.get_def(run.town_warrant).data.has("requires"), "never an upgrade at first")
	_to_shop(run, 30)
	var bought := run.town_warrant
	ok(run.apply({"a": "buy_warrant"})["ok"], "bought")
	eq(run.ducats, 20, "paid 10")
	ok(run.warrants.has(bought), "owned")
	ok(not run.apply({"a": "buy_warrant"})["ok"], "only one per town")


func test_upgrades_need_their_base() -> void:
	var run := _run()
	for d in ContentDB.pool("warrant"):
		if not d.data.has("requires"):
			run.warrants.append(d.id)
	var offered := run._roll_warrant()
	ok(ContentDB.get_def(offered).data.get("requires", "") != "", "with every base owned, an upgrade is offered")


func test_stat_warrants() -> void:
	var run := _run()
	_own(run, ["w_bottega", "w_bottega_grande", "w_copione_lungo", "w_cestino", "w_baule",
		"w_pennello", "w_tavolozza", "w_foglio_bianco", "w_inchiostro_nero"])
	eq(run.stat("shop_slots"), 4, "two extra shop slots")
	eq(run.stat("hands"), 5, "+1 hand")
	eq(run.stat("discards"), 4, "+1 discard")
	eq(run.stat("consumable_slots"), 3, "+1 consumable slot")
	eq(run.stat("hand_size"), 10, "+2 cards in hand")
	eq(run.stat("zanni_slots"), 6, "+1 Jester slot from the black ink")


func test_discounts() -> void:
	var run := _run()
	_own(run, ["w_sconto"])
	eq(run.offer_price({"cost": 4}), 3, "25% off a 4-ducat pack")
	eq(run.offer_price({"cost": 6}), 4, "25% off 6, rounded down")
	_own(run, ["w_svendita"])
	eq(run.offer_price({"cost": 6}), 3, "50% off")
	_to_shop(run)
	_own(run, ["w_rimescolo"])
	eq(run.reroll_price(), 3, "reroll 5 - 2")
	_own(run, ["w_rimescolo_perpetuo"])
	eq(run.reroll_price(), 1, "reroll 5 - 4")


func test_interest_warrants() -> void:
	var run := _run()
	_own(run, ["w_salvadanaio"])
	eq(run.stat("interest_cap"), 10, "cap 10")
	_own(run, ["w_banca_san_giorgio"])
	eq(run.stat("interest_cap"), 20, "cap 20")


func test_osservatorio() -> void:
	var run := _run()
	_own(run, ["w_cannocchiale", "w_osservatorio"])
	run.consumables.append(ItemCard.make("s_gemini", 3))
	eq(Scorer.score(run, cards("KH KS"), cards("")).total, 90, "holding Gemini: pair x1.5")
	eq(Scorer.score(run, cards("AS"), cards("")).total, 16, "other hands: nothing")


func test_cannocchiale_favourite_sign() -> void:
	var run := _run()
	_own(run, ["w_cannocchiale"])
	run.hand_levels.mark_played(HandTable.FLUSH)
	_to_shop(run)
	_open(run, "pk_sign_small")
	var first: Dictionary = run.pack["items"][0]
	ok(first["id"] == "s_aquarius" or first["id"] == "o_eclissi", "the first card is Aquarius (unless the 0.3% Eclissi)")


func test_baule_dei_presagi() -> void:
	var omens := 0
	for i in 30:
		var run := _run([], "BAULE-%d" % i)
		_own(run, ["w_baule", "w_baule_presagi"])
		_to_shop(run)
		_open(run, "pk_tarocchi_big")
		for entry in run.pack["items"]:
			if entry["kind"] == "omen":
				omens += 1
	ok(omens > 10 and omens < 60, "about 1 in 5 cards is an Omen: %d of 150" % omens)


func test_playing_cards_in_the_shop() -> void:
	var run := _run()
	_own(run, ["w_mazzo_prestigiatore", "w_gran_trucco"])
	_to_shop(run, 1000)
	var bought := 0
	for i in 40:
		for slot in run.shop.offers.size():
			var offer: Dictionary = run.shop.offers[slot]
			if offer["kind"] == "card" and not offer["sold"]:
				var c: Dictionary = offer["card"]
				ok(c["enh"] != "" or c["seal"] != "" or c["ed"] != "", "Il Gran Trucco: every card has something")
				run.apply({"a": "buy", "slot": slot})
				bought += 1
		run.apply({"a": "reroll"})
	ok(bought > 3, "cards turned up in the shop: %d" % bought)
	eq(run.full_deck.size(), 52 + bought, "bought cards joined the deck")


func test_clessidra_goes_back_a_town() -> void:
	var run := _run()
	run.town = 3
	_to_shop(run)
	run.town_warrant = "w_clessidra"
	run.apply({"a": "buy_warrant"})
	eq(run.town, 2, "back one town")
	eq(run.stat("hands"), 3, "-1 hand")


func test_ricatto_swaps_the_patron() -> void:
	var run := _run()
	ContentDB.register(ContentDef.make("patron_other", "patron", 0, 0, {}, {"target_mult": 2.0}))
	_own(run, ["w_ricatto"])
	run.ducats = 30
	var before := run.town_patron
	ok(run.apply({"a": "swap_patron"})["ok"], "swapped")
	ok(run.town_patron != before, "a different Patron")
	eq(run.ducats, 20, "paid 10")
	ok(not run.apply({"a": "swap_patron"})["ok"], "only once per town")
	_own(run, ["w_corruzione"])
	ok(run.apply({"a": "swap_patron"})["ok"], "La Corruzione: again")


# --- omens ---

func test_creating_omens() -> void:
	var run := _in_show()
	ok(_omen(run, "o_maschera_divina"), "Maschera Divina used")
	eq(run.zanni[0].def().rarity, 3, "a legendary Jester")
	ok(_omen(run, "o_patto"), "Patto used")
	eq(run.zanni[1].def().rarity, 2, "a rare Jester")
	eq(run.ducats, 2, "ducats halved")
	ok(_omen(run, "o_eclissi"), "Eclissi used")
	ok(HandTable.ORDER.all(func(h: String) -> bool: return run.hand_levels.level(h) == 2), "every hand levelled")


func test_replacing_omens() -> void:
	var run := _in_show()
	ok(_omen(run, "o_janara"), "Janara used")
	eq([run.full_deck.size(), run.hand.size()], [54, 10], "one card gone, three added")
	var added := run.hand.slice(7)
	ok(added.all(func(c: PlayingCard) -> bool: return c.is_face() and c.enhancement != ""), "enhanced face cards")
	for i in 30:
		var again := _run([], "JANARA-%d" % i)
		again.apply({"a": "select_show"})
		_omen(again, "o_janara")
		ok(again.hand.slice(7).all(func(c: PlayingCard) -> bool: return c.is_face()),
			"never Marble, which would erase the rank (seed %d)" % i)
	ok(_omen(run, "o_fantasma"), "Fantasma used")
	eq(run.full_deck.size(), 55, "two Aces added")
	ok(_omen(run, "o_folletto"), "Folletto used")
	eq(run.full_deck.size(), 58, "four number cards added")


func test_seal_and_edition_omens() -> void:
	var table := [["o_corno", "seal_ducal"], ["o_ritorno", "seal_encore"], ["o_civetta", "seal_astral"], ["o_sibilla", "seal_oracle"]]
	for row in table:
		var run := _in_show()
		ok(not _omen(run, row[0], run.hand.slice(0, 2)), row[0] + " needs exactly 1 card")
		ok(_omen(run, row[0], [run.hand[0]]), row[0] + " used")
		eq(run.hand[0].seal, row[1], row[0] + " sealed the card")
	var run := _in_show()
	_omen(run, "o_fuoco_fatuo", [run.hand[0]])
	ok(run.hand[0].edition in ["ed_silvered", "ed_opaline", "ed_prismatic"], "Fuoco Fatuo gave an edition")


func test_hand_changing_omens() -> void:
	var run := _in_show()
	_omen(run, "o_acqua_alta")
	ok(run.hand.all(func(c: PlayingCard) -> bool: return c.suit == run.hand[0].suit), "Acqua Alta: one suit")
	_omen(run, "o_seduta")
	ok(run.hand.all(func(c: PlayingCard) -> bool: return c.rank == run.hand[0].rank), "Seduta: one rank")
	eq(run.stat("discards"), 2, "and -1 discard for the run")
	_omen(run, "o_vesuvio")
	eq(run.full_deck.size(), 48, "Vesuvio destroyed 4")
	eq(run.ducats, 20, "and paid 16")
	var copied := _in_show()
	_omen(copied, "o_specchio_magico", [copied.hand[0]])
	eq([copied.full_deck.size(), copied.hand.size()], [54, 10], "Specchio Magico: two copies in hand")


func test_jester_omens() -> void:
	var shadow := _in_show(["z_zanni"])
	_omen(shadow, "o_ombra")
	eq(shadow.zanni[0].edition, "ed_shadow", "Ombra: Shadow")
	eq(shadow.stat("hand_size"), 7, "and -1 card in hand")
	var double := _in_show(["z_zanni", "z_payer", "z_colombina"])
	_omen(double, "o_sosia")
	eq(double.zanni.size(), 2, "Sosia: the original and its copy")
	eq(double.zanni[0].def_id, double.zanni[1].def_id, "of the same Jester")
	var cursed := _in_show(["z_zanni", "z_payer", "z_colombina"])
	_omen(cursed, "o_malocchio")
	eq(cursed.zanni.size(), 1, "Malocchio: one survivor")
	eq(cursed.zanni[0].edition, "ed_prismatic", "and it's Prismatic")
	ok(not _omen(_in_show(), "o_sosia"), "Sosia needs a Jester")
