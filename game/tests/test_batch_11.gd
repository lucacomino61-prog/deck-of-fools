extends TestCase
## Card batch 11: decks, stakes, challenges and unlock rules do what cards/batch-11.md says.


func _deck(deck_id: String, stake_level := 1) -> RunState:
	ContentPacks.register_all()
	TestContent.add_test_defs()
	return RunState.create("B11", deck_id, stake_level)


func _challenge(challenge_id: String, seed_text := "B11C") -> RunState:
	ContentPacks.register_all()
	TestContent.add_test_defs()
	return RunState.create(seed_text, ContentDB.get_def(challenge_id).data["deck"], 1, challenge_id)


func _to_shop(run: RunState, ducats := 100) -> void:
	run.phase = RunState.Phase.CASH_OUT
	run.apply({"a": "cash_out"})
	run.ducats = ducats


func _win(run: RunState) -> void:
	run.zanni.append(ItemCard.make("z_huge", 1))
	run.apply({"a": "select_show"})
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})
	run.zanni.pop_back()


# --- content and text ---

func test_batch_contents_and_text() -> void:
	ContentPacks.register_all()
	eq(ContentDB.pool("deck").size(), 15, "15 decks")
	eq(ContentDB.pool("stake").map(func(d: ContentDef) -> int: return d.data["level"]), [1, 2, 3, 4, 5, 6, 7, 8], "8 stakes in order")
	eq(ContentDB.pool("challenge").size(), 20, "20 challenges")
	var keys := {}
	var f := FileAccess.open("res://i18n/cards.csv", FileAccess.READ)
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() >= 2 and line[1] != "":
			keys[line[0]] = true
	for kind in ["deck", "stake", "challenge"]:
		for d in ContentDB.pool(kind):
			ok(keys.has(d.id + ".name") and keys.has(d.id + ".text"), d.id + " has a name and text")


# --- decks ---

func test_stat_decks() -> void:
	eq(_deck("d_bergamo").stat("discards"), 4, "Bergamo: +1 discard")
	eq(_deck("d_venezia").stat("hands"), 5, "Venezia: +1 hand")
	eq(_deck("d_genova").ducats, 14, "Genova: +10 ducats")
	var napoli := _deck("d_napoli")
	eq([napoli.stat("zanni_slots"), napoli.stat("hands")], [6, 3], "Napoli: +1 slot, -1 hand")
	var firenze := _deck("d_firenze")
	eq([firenze.stat("hand_size"), firenze.stat("zanni_slots")], [10, 4], "Firenze: +2 cards, -1 slot")


func test_siena_pays_for_what_you_save() -> void:
	var run := _deck("d_siena")
	run.ducats = 50
	_win(run)
	ok(run.payout.has({"src": "hands", "v": 6}), "+2 per unused hand")
	ok(run.payout.has({"src": "discards", "v": 3}), "+1 per unused discard")
	ok(not run.payout.any(func(p: Dictionary) -> bool: return p["src"] == "interest"), "no interest")


func test_starting_card_decks() -> void:
	var palermo := _deck("d_palermo")
	ok(palermo.warrants.has("w_baule"), "Palermo: Il Baule")
	eq(palermo.consumables.map(func(c: ItemCard) -> String: return c.def_id), ["t_matto", "t_matto"], "and two Il Matto")
	var padova := _deck("d_padova")
	ok(padova.warrants.has("w_cannocchiale"), "Padova: Il Cannocchiale")
	eq(padova.stat("consumable_slots"), 1, "and one consumable slot")
	var bologna := _deck("d_bologna")
	eq(bologna.warrants, ["w_mazzo_tarocchi", "w_mappa_celeste", "w_bottega"] as Array[String], "Bologna: three Warrants")


func test_benevento_omens_in_the_shop() -> void:
	var run := _deck("d_benevento")
	eq(run.consumables[0].def_id, "o_malocchio", "starts with Il Malocchio")
	_to_shop(run, 10000)
	var omens := 0
	for i in 60:
		omens += run.shop.offers.filter(func(o: Dictionary) -> bool: return o["kind"] == "omen").size()
		run.apply({"a": "reroll"})
	ok(omens > 0, "Omens turn up in the shop (%d)" % omens)


func test_built_decks() -> void:
	var verona := _deck("d_verona")
	eq(verona.full_deck.size(), 40, "Verona: 40 cards")
	ok(verona.full_deck.all(func(c: PlayingCard) -> bool: return not c.is_face()), "no face cards")
	var ferrara := _deck("d_ferrara")
	eq(ferrara.full_deck.size(), 52, "Ferrara: 52 cards")
	ok(ferrara.full_deck.all(func(c: PlayingCard) -> bool: return c.suit == PlayingCard.Suit.SPADES or c.suit == PlayingCard.Suit.HEARTS),
		"only Spades and Hearts")
	var carnevale := _deck("d_carnevale")
	eq(carnevale.full_deck.size(), 52, "Carnevale: 52 cards")
	var distinct := {}
	for c in carnevale.full_deck:
		distinct["%d-%d" % [c.rank, c.suit]] = true
	ok(distinct.size() < 52, "random cards repeat (%d distinct)" % distinct.size())


func test_roma_and_mantova() -> void:
	var roma := _deck("d_roma")
	pin_town(roma)
	roma.show_index = Shows.PATRON
	_win(roma)
	ok(roma.favors.has("f_gemello"), "Roma: Il Gemello after a Patron")

	var mantova := _deck("d_mantova")
	mantova.apply({"a": "select_show"})
	eq(mantova.show_target, 600, "Mantova: targets x2")
	eq(Scorer.score(mantova, cards("KH KS"), cards("")).total, 256, "30 and 2 even out to 16 x 16")


# --- stakes ---

func test_stakes_stack() -> void:
	var top := _deck("standard", 8)
	eq([top.stat("reward_matinee"), top.stat("target_scaling"), top.stat("discards")], [0, 3, 2],
		"no matinee pay, steepest targets, -1 discard")
	eq([top.stat("eternal_pct"), top.stat("perishable_on"), top.stat("rented_pct")], [30, 1, 30], "all three stickers")
	var low := _deck("standard", 3)
	eq([low.stat("target_scaling"), low.stat("discards"), low.stat("eternal_pct")], [2, 3, 0], "stake 3 has only the first three")


func test_stickers_in_the_shop() -> void:
	var run := _deck("standard", 8)
	_to_shop(run, 100000)
	var kinds := {}
	for i in 150:
		for o in run.shop.offers:
			if o["kind"] == "zanni":
				kinds[o.get("sticker", "none")] = true
				if o.get("rented", false):
					kinds["rented"] = true
					eq(o["cost"], 1, "a Rented Jester costs 1")
		run.apply({"a": "reroll"})
	ok(kinds.has("eternal") and kinds.has("perishable") and kinds.has("rented") and kinds.has("none"), "every sticker turns up: %s" % [kinds.keys()])


func test_sticker_rules() -> void:
	var run := _deck("standard", 8)
	_to_shop(run)
	run.shop.offers.assign([
		{"kind": "zanni", "id": "z_zanni", "cost": 2, "edition": "", "sold": false, "sticker": "eternal"},
		{"kind": "zanni", "id": "z_payer", "cost": 1, "edition": "", "sold": false, "rented": true},
		{"kind": "zanni", "id": "z_plus4", "cost": 3, "edition": "", "sold": false, "sticker": "perishable"},
	])
	for slot in 3:
		run.apply({"a": "buy", "slot": slot})
	ok(not run.apply({"a": "sell", "zone": "zanni", "index": 0})["ok"], "an Eternal Jester can't be sold")
	run.apply({"a": "leave_shop"})
	_win(run)
	ok(run.payout.has({"src": "zanni:z_payer#1", "v": -3}), "rent is due at cash-out")
	eq(run.zanni[2].state["perish"], 4, "the Perishable one has 4 shows left")
	for i in 4:
		run.apply({"a": "cash_out"})
		run.apply({"a": "leave_shop"})
		_win(run)
	ok(run.zanni[2].state.get("perished", false), "after 5 shows it has perished")
	run.apply({"a": "cash_out"})
	run.apply({"a": "leave_shop"})
	run.apply({"a": "select_show"})
	ok(run.zanni[2].debuffed, "and stays out of work")


# --- challenges ---

func test_jester_challenges() -> void:
	var mono := _challenge("c_monologo")
	eq([mono.stat("zanni_slots"), mono.zanni.size(), mono.zanni[0].def_id], [1, 1, "z_prima_donna"], "Monologo: one slot, La Prima Donna")
	ok(mono.zanni[0].state.get("eternal", false), "and she's Eternal")

	var none := _challenge("c_tutti_fuori")
	eq(none.stat("zanni_slots"), 0, "Tutti Fuori: no slots")
	_to_shop(none, 100000)
	var jesters := 0
	for i in 40:
		jesters += none.shop.offers.filter(func(o: Dictionary) -> bool: return o["kind"] == "zanni").size()
		jesters += none.shop.packs.filter(func(p: Dictionary) -> bool: return str(p["id"]).begins_with("pk_zanni")).size()
		none.apply({"a": "reroll"})
	eq(jesters, 0, "no Jesters or Jester packs in the shop")

	for row in [["c_fame", "perish"], ["c_contratto_eterno", "eternal"], ["c_noleggio", "rented"]]:
		var run := _challenge(row[0])
		run.add_zanni("z_zanni")
		ok(run.zanni[0].state.has(row[1]), row[0] + " stickers every Jester")


func test_deck_challenges() -> void:
	ok(_challenge("c_carnevale_eterno").full_deck.all(func(c: PlayingCard) -> bool: return c.enhancement == "enh_motley"), "every card Motley")
	var glass := _challenge("c_vetro_fragile")
	ok(glass.full_deck.all(func(c: PlayingCard) -> bool: return c.enhancement == "enh_mirror"), "every card Mirror")
	eq(glass.stat("mirror_odds"), 2, "shattering 1 in 2")
	eq(_challenge("c_teatro_marmo").full_deck.filter(func(c: PlayingCard) -> bool: return c.enhancement == "enh_marble").size(), 26, "26 Marble cards")
	var double := _challenge("c_mazzo_doppio")
	var counts := {}
	for c in double.full_deck:
		var key := "%d-%d" % [c.rank, c.suit]
		counts[key] = int(counts.get(key, 0)) + 1
	eq([double.full_deck.size(), counts.size()], [52, 26], "26 cards, twice each")
	ok(counts.values().all(func(n: int) -> bool: return n == 2), "exactly twice")


func test_money_challenges() -> void:
	var poor := _challenge("c_compagnia_povera")
	eq([poor.ducats, poor.stat("interest_per"), poor.stat("hands")], [0, 0, 5], "Compagnia Povera")
	var broke := _challenge("c_bancarotta")
	eq([broke.ducats, broke.stat("debt_limit")], [-20, 20], "Bancarotta: 20 in debt")
	var tax := _challenge("c_tassa_lusso")
	tax.ducats = 20
	eq(tax.stat("hand_size"), 4, "Tassa sul Lusso: 20 ducats cost 4 cards")
	var inflation := _challenge("c_inflazione")
	_to_shop(inflation)
	var before := inflation.offer_price({"cost": 4})
	inflation.apply({"a": "buy", "slot": 0})
	eq(inflation.offer_price({"cost": 4}), before + 1, "Inflazione: prices rise after a purchase")


func test_rule_challenges() -> void:
	var five := _challenge("c_cinque_carte")
	eq(five.stat("hand_size"), 5, "Cinque Carte: 5 cards")
	five.apply({"a": "select_show"})
	eq(five.apply({"a": "play", "cards": [five.hand[0].id]})["total"], 0, "a 1-card hand scores nothing")

	var last := _challenge("c_ultima_replica")
	eq([last.stat("hands"), last.stat("discards")], [1, 6], "Ultima Replica: 1 hand, 6 discards")

	var ban := _challenge("c_divieto")
	ban.apply({"a": "select_show"})
	eq(Scorer.score(ban, cards("2H 7H 9H JH KH"), cards("")).total, 0, "Divieto: a Flush scores nothing")

	var leap := _challenge("c_grande_salto")
	ok(HandTable.ORDER.all(func(h: String) -> bool: return leap.hand_levels.level(h) == 3), "Grande Salto: every hand at level 3")
	eq(leap.stat("signs_banned"), 1, "and no Signs")

	var night := _challenge("c_notte_bianca")
	night.apply({"a": "select_show"})
	ok(night.hand.all(func(c: PlayingCard) -> bool: return c.face_down), "Notte Bianca: everything face down")

	var patrons := _challenge("c_solo_patroni")
	patrons.apply({"a": "select_show"})
	ok(patrons.current_patron() != "", "Solo Patroni: the matinee has a Patron")

	var finale := _challenge("c_gran_finale")
	eq([finale.town, finale.ducats, finale.zanni.size()], [5, 50, 3], "Gran Finale: town 5, 50 ducats, 3 Jesters")
	ok(finale.zanni.all(func(z: ItemCard) -> bool: return z.def().rarity == 2), "all rare")


# --- profile and unlocks ---

func test_fresh_profile() -> void:
	ContentPacks.register_all()
	var p := Profile.new()
	ok(p.deck_unlocked("d_bergamo") and not p.deck_unlocked("d_venezia"), "only Bergamo")
	eq(p.locked_cards().size(), 22, "every rare locked")
	ok(p.is_unlocked("z_zanni") and p.is_unlocked("z_martinelli"), "commons and legendaries never are")
	eq(p.max_stake("d_bergamo"), 1, "stake 1 only")
	ok(not p.challenge_unlocked("c_monologo"), "no challenges yet")


func test_a_won_run_unlocks_things() -> void:
	var run := _deck("d_bergamo")
	run.won = true
	run.feats["won_run"] = true
	var p := Profile.new()
	p.record_run(run)
	ok(p.is_unlocked("z_re_dei_folli"), "Il Re dei Folli: win a run")
	ok(p.deck_unlocked("d_palermo"), "Palermo: win with Bergamo")
	eq(p.max_stake("d_bergamo"), 2, "the next stake opens")
	ok(p.challenge_unlocked("c_monologo") and p.challenge_unlocked("c_vetro_fragile"), "C1-C5 open")
	ok(not p.challenge_unlocked("c_teatro_marmo"), "C6 not yet")


func test_discovery_and_lifetime_unlocks() -> void:
	ContentPacks.register_all()
	var p := Profile.new()
	for i in 20:
		p.discovered["card_%d" % i] = true
	ok(p.deck_unlocked("d_venezia") and not p.deck_unlocked("d_genova"), "20 discovered: Venezia")
	p.runs_lost = 5
	ok(p.is_unlocked("z_fenice"), "La Fenice: lose 5 runs")
	p.signs_used = 49
	ok(not p.is_unlocked("z_cometa"), "La Cometa needs 50 Signs")
	p.signs_used = 50
	ok(p.is_unlocked("z_cometa"), "and gets them")


func test_feats_come_from_play() -> void:
	var run := _deck("standard")
	run.apply({"a": "select_show"})
	for i in 5:
		run.hand[i].suit = PlayingCard.Suit.HEARTS
		run.hand[i].rank = [2, 5, 7, 9, 12][i]
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})
	ok(run.feats.has("played_flush"), "playing a Flush earns its feat")
	var p := Profile.new()
	p.record_run(run)
	ok(p.is_unlocked("z_pittore"), "which unlocks Il Pittore")


func test_locked_cards_never_turn_up() -> void:
	ContentPacks.register_all()
	var locked := Profile.new().locked_cards()
	var run := RunState.create("LOCKED", "standard", 1, "", locked)
	ok(run._shop_pool("zanni").all(func(d: ContentDef) -> bool: return not locked.has(d.id)), "no locked rare in the shop pool")


func test_profile_round_trip() -> void:
	var p := Profile.new()
	p.discovered["z_zanni"] = true
	p.feats["won_run"] = true
	p.best_stake["d_bergamo"] = 3
	p.total_wins = 2
	p.badges["z_zanni"] = 3
	var back := Profile.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	eq(JSON.stringify(back.to_dict()), JSON.stringify(p.to_dict()), "a profile survives a save")
