extends TestCase
## Card batch 13: Jester fame and the Maestri, the wagon (scudi, props, cosmetics, unlocks),
## the campaign (Il Lungo Giro) and the Patron rivalry do what cards/batch-13.md says.


func _real() -> void:
	ContentPacks.register_all()
	TestContent.add_test_defs()


## A run with these extras: on the test stand-in deck (classic rules) unless a deck is given.
func _run(extras := {}, deck := "standard", seed_text := "B13") -> RunState:
	_real()
	return RunState.create(seed_text, deck, 1, "", [], extras)


func _give(run: RunState, zanni_ids: Array) -> void:
	for id in zanni_ids:
		run.zanni.append(ItemCard.make(id, ContentDB.get_def(id).cost))


## Starts the show with `hand` in hand and a huge target (no win unless a test lowers it).
func _show(run: RunState, hand: String) -> void:
	run.apply({"a": "select_show"})
	run.show_target = 1000000000.0
	run.hand.assign(cards(hand))


func _play(run: RunState, n: int) -> Dictionary:
	return run.apply({"a": "play", "cards": ids(run.hand.slice(0, n))})


func _events(result: Dictionary, src: String) -> Array:
	return (result.get("events", []) as Array).filter(func(e: Dictionary) -> bool: return e["src"] == src) \
		.map(func(e: Dictionary) -> Array: return [e["t"], e["v"]])


## Wins the current show with one card.
func _win(run: RunState, hand := "2S 3S") -> void:
	_show(run, hand)
	run.show_target = 1.0
	_play(run, 1)


# --- content and text ---

func test_batch_contents_and_text() -> void:
	ContentPacks.register_all()
	var keys := {}
	var f := FileAccess.open("res://i18n/cards.csv", FileAccess.READ)
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() >= 2 and line[1] != "":
			keys[line[0]] = true
	eq(ContentDB.pool("prop").size(), 10, "10 props")
	for d in ContentDB.pool("prop"):
		ok(keys.has(d.id + ".name") and keys.has(d.id + ".text"), d.id + " has a name and text")
	var chapters := CampaignCards.chapters()
	eq(chapters.size(), 16, "16 chapters")
	var previous := "c_bergamo"
	for d in chapters:
		for k in ["name", "text", "before", "after"]:
			ok(keys.has("%s.%s" % [d.id, k]), "%s has a %s" % [d.id, k])
		eq(str(d.data["start"]), previous, d.id + " starts where the last chapter ended")
		previous = str(d.data["city"])
		ok(ContentDB.get_def(d.data["patron"]) != null, d.id + " has a story Patron")
		ok(ContentDB.get_def(d.data["city"]).kind == "city", d.id + " is a city")
		var reward: Dictionary = d.data["reward"]
		ok(int(reward["scudi"]) > 0, d.id + " pays scudi")
		if reward.has("deck"):
			ok(ContentDB.get_def(reward["deck"]).kind == "deck", d.id + " gives a deck")
		if reward.has("cosmetic"):
			ok(WagonCards.cosmetic(reward["cosmetic"])["campaign"], d.id + " gives a campaign cosmetic")
	eq(chapters.map(func(d: ContentDef) -> int: return d.data["stake"]), [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4], "the stake climbs")
	eq(str(chapters[15].data["city"]), "c_venezia", "the last chapter ends in Venezia")
	for d in ContentDB.pool("patron"):
		for k in ["name", "text", "enter", "beaten", "gloat", "revenge"]:
			ok(keys.has("%s.%s" % [d.id, k]), "%s has its %s line" % [d.id, k])
	for c in WagonCards.all_cosmetics():
		ok(keys.has(c["id"] + ".name"), c["id"] + " has a name")
	for id in Fame.FLAT:
		ok(ContentDB.get_def(id) != null and ContentDB.get_def(id).kind == "zanni", id + " is a Jester")


func test_maestro_names() -> void:
	eq(Fame.title("z_arlecchino", "Arlecchino"), "Maestro Arlecchino", "Maestro")
	eq(Fame.title("z_colombina", "Colombina"), "Maestra Colombina", "a woman without an article")
	eq(Fame.title("z_fioraia", "La Fioraia"), "Maestra Fioraia", "La → Maestra")
	eq(Fame.title("z_gemelli", "I Gemelli"), "Maestri Gemelli", "I → Maestri")
	eq(Fame.title("z_capitano", "Il Capitano"), "Maestro Capitano", "Il → Maestro")
	eq(Fame.title("z_maestro_cappella", "Il Maestro di Cappella"), "Il Gran Maestro di Cappella", "the Maestro's Maestro")
	eq([Fame.stars(0), Fame.stars(25), Fame.stars(59), Fame.stars(60), Fame.stars(120)], [0, 1, 1, 2, 3], "stars at 25, 60, 120")
	eq([Fame.to_next(10), Fame.to_next(100), Fame.to_next(130)], [15, 20, 0], "fame to the next star")


# --- Maestri ---

func test_a_maestro_grows_its_numbers() -> void:
	for maestro in [false, true]:
		var run := _run({"maestri": ["z_zanni", "z_lampionaio", "z_x2"]} if maestro else {})
		_give(run, ["z_zanni", "z_lampionaio", "z_x2"])
		_show(run, "2H")
		var result := _play(run, 1)
		eq(_events(result, "zanni:z_zanni#0"), [["mult", 5.0 if maestro else 4.0]], "+4 Mult (x1.25 as a Maestro)")
		eq(_events(result, "zanni:z_lampionaio#1"), [["points", 25.0 if maestro else 20.0]], "+20 Points (+25)")
		eq(_events(result, "zanni:z_x2#2"), [["xmult", 2.25 if maestro else 2.0]], "x2 Mult (x2.25)")


func test_a_maestro_with_nothing_to_grow_pays_ducats() -> void:
	var run := _run({"maestri": ["z_saltimbanco"]})
	_give(run, ["z_saltimbanco"])
	_win(run)
	ok(run.payout.has({"src": "zanni:z_saltimbanco#0", "v": Fame.FLAT_DUCATS}), "+2 ducats at cash-out")
	var plain := _run()
	_give(plain, ["z_saltimbanco"])
	_win(plain)
	ok(not plain.payout.any(func(p: Dictionary) -> bool: return str(p["src"]).begins_with("zanni:")), "nothing when it isn't a Maestro")


func test_a_duo_of_two_maestri_grows_more() -> void:
	for both in [false, true]:
		var run := _run({"maestri": ["z_isabella", "z_flavio"] if both else ["z_isabella"]})
		_give(run, ["z_isabella", "z_flavio"])
		run.phase = RunState.Phase.SHOP
		run.shop = ShopState.new()
		run.apply({"a": "merge", "index": 0, "other": 1})
		run.phase = RunState.Phase.CHOOSE_SHOW
		_show(run, "KH KS QH QS 2C")
		var mine := _events(_play(run, 4), "zanni:lz_isabella_flavio#0")
		var expected := [["points", 25.0], ["mult", 9.0], ["points", 35.0], ["mult", 11.0]] if both \
			else [["points", 25.0], ["mult", 8.0], ["points", 30.0], ["mult", 9.0]]
		eq(mine, expected, "both Maestri: x1.75; one: the duo's x1.5 only")


# --- fame ---

func test_fame_for_a_won_show() -> void:
	var run := _run()
	_give(run, ["z_zanni", "z_saltimbanco", "z_pair8"])
	_win(run)
	eq(run.fame.get("z_zanni", 0), 1, "it fired: +1")
	eq(run.fame.get("z_saltimbanco", 0), 1, "a slot Jester always works: +1")
	eq(run.fame.get("z_pair8", 0), 0, "no Pair, it never fired")


func test_fame_for_winning_the_run_and_a_duo() -> void:
	var run := _run()
	_give(run, ["z_zanni"])
	pin_town(run)
	run.town = Shows.FINAL_TOWN
	run.show_index = Shows.PATRON
	_win(run)
	ok(run.won, "the tour is won")
	eq(run.fame.get("z_zanni", 0), Fame.SHOW + Fame.RUN_WON, "+1 for the show, +3 for the run")

	var duo := _run()
	_give(duo, ["z_isabella", "z_flavio"])
	duo.phase = RunState.Phase.SHOP
	duo.shop = ShopState.new()
	duo.apply({"a": "merge", "index": 0, "other": 1})
	duo.phase = RunState.Phase.CHOOSE_SHOW
	_show(duo, "KH KS 2C")
	duo.show_target = 1.0
	_play(duo, 2)
	eq([duo.fame.get("z_isabella", 0), duo.fame.get("z_flavio", 0)], [1, 1], "a duo performs together: fame for both")


func test_the_profile_keeps_fame_and_makes_maestri() -> void:
	var run := _run()
	_give(run, ["z_zanni"])
	_win(run)
	var p := Profile.new()
	p.fame["z_zanni"] = Fame.MAESTRO - 1
	p.record_run(run)
	eq(p.fame_of("z_zanni"), Fame.MAESTRO, "fame adds up across runs")
	eq(p.maestri(), ["z_zanni"], "120: a Maestro")
	eq(p.extras_for()["maestri"], ["z_zanni"], "it comes along to the next run")
	var seeded := Profile.new()
	seeded.record_run(run, false)
	ok(seeded.fame.is_empty() and seeded.scudi == 0, "a seeded run earns no fame or scudi")


func test_fair_play() -> void:
	ok(Profile.brings_extras("", {}), "a normal run")
	ok(Profile.brings_extras("", {"chapter": "ch_01"}), "the campaign")
	ok(not Profile.brings_extras("", {"daily_date": "2026-10-22"}), "not the daily run")
	ok(not Profile.brings_extras("", {"daily_date": "2026-10-22", "practice": true}), "not even daily practice")
	ok(not Profile.brings_extras("", {"seeded": true}), "not a seeded run")
	ok(not Profile.brings_extras("c_bianco", {}), "not a challenge")
	ok(not _run().assisted(), "a run with no extras is ranked")
	ok(not _run({"rivalry": true, "nemesis": {"patron": "pt_censore", "town": 2}}).assisted(), "a nemesis doesn't help")
	ok(_run({"maestri": ["z_zanni"]}).assisted(), "Maestri do")
	ok(_run({"props": ["p_salvadanaio"]}).assisted(), "props do")


# --- the wagon ---

func test_scudi() -> void:
	_real()
	var run := RunState.new()
	run.counters = {"shows_won": 10, "scenarios_done": 2, "encores": 1, "patrons_beaten": 4}
	run.won = true
	run.stake = 3
	run.props.assign(["p_bandiera"])
	var total := 0
	for item in WagonCards.scudi_for(run):
		total += int(item["v"])
	eq(total, 10 + 2 + 2 + (5 + 2) + 4, "shows, Scenarios, Encores, the win (+stake), La Bandiera")


func test_props_at_the_start() -> void:
	eq(_run({"props": ["p_salvadanaio"]}).ducats, _run().ducats + 2, "Il Salvadanaio: +2 ducats")
	var toolbox := _run({"props": ["p_cassetta"]})
	eq(toolbox.consumables.map(func(i: ItemCard) -> String: return i.def().kind), ["tarocchi"], "La Cassetta: a Tarocchi")
	var portrait := _run({"props": ["p_ritratto"]})
	eq(portrait.zanni.size(), 1, "Il Ritratto: a Jester")
	eq(portrait.zanni[0].def().rarity, 0, "a common one")
	var script := _run({"props": ["p_copione"]})
	eq(script.stat("hands"), 5, "Il Copione Vecchio: +1 hand in the first show")
	script.show_index = Shows.EVENING
	eq(script.stat("hands"), 4, "and only there")
	var claque := _run({"props": ["p_claque"]}, "d_padova")
	claque.apply({"a": "select_show"})
	eq(claque.mood, 6, "La Claque: the crowd starts at 6")


func test_props_in_the_shop() -> void:
	var trunk := _run({"props": ["p_baule"]})
	var plain := _run()
	for run in [trunk, plain]:
		run.phase = RunState.Phase.CASH_OUT
		run.apply({"a": "cash_out"})
	eq(trunk.shop.offers.size(), plain.shop.offers.size() + 1, "Il Baule: one more offer in the first shop")
	eq(trunk.shop.offers.back()["kind"], "zanni", "a Jester")
	trunk.apply({"a": "leave_shop"})
	trunk.phase = RunState.Phase.CASH_OUT
	trunk.apply({"a": "cash_out"})
	eq(trunk.shop.offers.size(), plain.shop.offers.size(), "only the first shop")

	var mule := _run({"props": ["p_mulo"]})
	mule.phase = RunState.Phase.CASH_OUT
	mule.apply({"a": "cash_out"})
	mule.ducats = 50
	eq(mule.reroll_price(), mule.shop.reroll_cost - 1, "Il Mulo: the first reroll costs 1 less")
	mule.apply({"a": "reroll"})
	eq(mule.reroll_price(), mule.shop.reroll_cost, "then the full price")


func test_the_prompter_swaps_a_scenario() -> void:
	var run := _run({"props": ["p_suggeritore"]}, "d_padova")
	var before := run.scenario
	var result := run.apply({"a": "swap_scenario"})
	ok(result["ok"], "swapped")
	ok(run.scenario != before and run.scenario != "", "another Scenario")
	eq(ContentDB.get_def(run.scenario).data["tier"], ContentDB.get_def(before).data["tier"], "of the same tier")
	ok(not run.apply({"a": "swap_scenario"})["ok"], "once per town")
	ok(not _run({}, "d_padova").apply({"a": "swap_scenario"})["ok"], "not without the prop")


func test_the_lantern_shows_the_patrons() -> void:
	var run := _run({"props": ["p_lanterna"]}, "d_padova")
	for row in range(1, run.route.size()):
		for node in run.route[row]:
			ok((node as Dictionary).has("patron"), "row %d: %s has its Patron" % [row + 1, node["city"]])
	eq(str((run.route[7] as Array)[0]["patron"]).begins_with("pt_"), true, "Venezia's too")
	ok(ContentDB.get_def((run.route[7] as Array)[0]["patron"]).data.get("finale", false), "a finale Patron in town 8")
	run.show_index = Shows.PATRON
	run.phase = RunState.Phase.CASH_OUT
	run.apply({"a": "cash_out"})
	run.apply({"a": "leave_shop"})
	var col: int = run.roads()[0]
	run.apply({"a": "travel", "index": col})
	eq(run.town_patron, str((run.route[1] as Array)[col]["patron"]), "the Patron waiting is the one on the map")


func test_buying_in_the_wagon() -> void:
	_real()
	var p := Profile.new()
	p.scudi = 300
	ok(p.buy_prop("p_salvadanaio"), "a prop")
	eq(p.carried, ["p_salvadanaio"] as Array[String], "carried at once")
	ok(not p.buy_prop("p_salvadanaio"), "not twice")
	ok(p.buy_prop("p_claque"), "another")
	eq(p.carried, ["p_salvadanaio"] as Array[String], "one slot")
	p.carry_prop("p_claque", true)
	eq(p.carried, ["p_claque"] as Array[String], "swapped in")
	ok(p.buy_prop_slot(), "a second slot")
	p.carry_prop("p_salvadanaio", true)
	eq(p.carried, ["p_claque", "p_salvadanaio"] as Array[String], "two carried")
	eq(p.scudi, 300 - 40 - 60 - 200, "paid")
	ok(not p.buy_cosmetic("paint_oro"), "a campaign reward can't be bought")
	p.scudi = 100
	ok(p.buy_cosmetic("trim_flags") and p.buy_cosmetic("trim_bells"), "trims")
	p.wear("trim", "trim_flags")
	p.wear("trim", "trim_bells")
	p.wear("trim", "trim_flags")
	eq(p.worn["trims"], ["trim_bells"], "trims toggle on and off")
	p.wear("paint", "paint_rosso")
	ok(not p.worn.has("paint") or p.worn["paint"] == "", "only owned paint can be worn")


func test_buying_unlocks() -> void:
	_real()
	var p := Profile.new()
	p.scudi = 200
	ok(not p.deck_unlocked("d_roma"), "Roma is locked")
	ok(p.buy_unlock("d_roma"), "bought")
	ok(p.deck_unlocked("d_roma"), "and open")
	ok(not p.buy_unlock("d_roma"), "not twice")
	ok(not p.buy_unlock("d_bergamo"), "nothing to buy: it's open")
	ok(not p.is_unlocked("z_fenice") and p.buy_unlock("z_fenice") and p.is_unlocked("z_fenice"), "a rare Jester")
	ok(not p.locked_cards().has("z_fenice"), "it can turn up in runs")
	eq(p.scudi, 200 - 80 - 50, "paid")


# --- Patron rivalry ---

func test_the_nemesis_waits_where_it_beat_you() -> void:
	var p := Profile.new()
	_real()
	var lost := RunState.create("LOSS", "standard", 1, "", [], {"rivalry": true})
	lost.phase = RunState.Phase.LOST
	lost.town = 3
	lost.show_index = Shows.PATRON
	lost.town_patron = "pt_duca"
	p.record_run(lost, true, true)
	ok(p.nemesis.is_empty(), "giving up makes no nemesis")
	p.record_run(lost)
	eq(p.nemesis, {"patron": "pt_duca", "town": 3}, "the Patron that beat you")
	eq(p.extras_for()["nemesis"], {"patron": "pt_duca", "town": 3}, "comes along to the next run")

	var run := _run(p.extras_for())
	_give(run, ["z_zanni"])
	run.town = 3
	run._start_town()
	eq(run.town_patron, "pt_duca", "in town 3")
	ok(run.is_nemesis(), "as the nemesis")
	run.show_index = Shows.PATRON
	_win(run)
	ok(run.payout.has({"src": "nemesis", "v": RunState.NEMESIS_DUCATS}), "+10 ducats")
	ok(run.feats.has("vendetta"), "Vendetta")
	eq(run.fame.get("z_zanni", 0), Fame.SHOW + Fame.NEMESIS, "+2 fame for the troupe")
	p.record_run(run)
	ok(p.nemesis.is_empty(), "beaten: no more nemesis")


func test_where_a_nemesis_can_appear() -> void:
	eq(_run({"nemesis": {"patron": "pt_granduca", "town": 3}}).nemesis_town(), 8, "a finale Patron waits in town 8")
	eq(_run({"nemesis": {"patron": "pt_avaro", "town": 2}}).nemesis_town(), 6, "not before its first town")
	eq(_run({"nemesis": {"patron": "pt_grifone", "town": 8}}).nemesis_town(), -1, "Messer Grifone only in the last chapter")
	eq(_run({"nemesis": {"patron": "pt_grifone", "town": 8}, "chapter": "ch_16"}, "d_venezia").nemesis_town(), 8, "where he is")


func test_a_rematch() -> void:
	_real()
	var drawn := 0
	for i in 100:
		var run := RunState.create("RM%d" % i, "standard", 1, "", [], {"rivalry": true})
		run.beaten.assign(["pt_censore"])
		run.town = 5
		run._roll_rematch()
		if not run.rematch.is_empty():
			drawn += 1
			eq(run.rematch, {"town": 5, "patron": "pt_censore"}, "a beaten Patron comes back")
	ok(drawn >= 10 and drawn <= 30, "about 1 in 5 (%d of 100)" % drawn)
	var none := RunState.create("RM", "standard", 1, "", [], {})
	none.beaten.assign(["pt_censore"])
	none.town = 5
	for i in 30:
		none._roll_rematch()
	ok(none.rematch.is_empty(), "not without the rivalry (daily, seeded, challenge runs)")

	var plain := _run({"rivalry": true})
	plain.town = 5
	plain.town_patron = "pt_censore"
	var run := _run({"rivalry": true})
	run.rematch = {"town": 5, "patron": "pt_censore"}
	run.town = 5
	run._start_town()
	eq(run.town_patron, "pt_censore", "the rematch")
	ok(run.is_rematch(), "is one")
	eq(run.target_for_show(Shows.PATRON), floorf(plain.target_for_show(Shows.PATRON) * 1.25), "target x1.25")
	run.show_index = Shows.PATRON
	_win(run)
	ok(run.payout.has({"src": "show", "v": run.stat("reward_patron") * 2}), "pays double")


# --- the campaign ---

func test_a_chapter_runs_to_its_city() -> void:
	var run := _run({"chapter": "ch_02"}, "d_bergamo")
	ok(run.tour, "on tour")
	eq((run.route[0] as Array)[0]["city"], "c_bergamo", "from where chapter 1 ended")
	eq((run.route[7] as Array)[0]["city"], "c_milano", "to Milano")
	eq(run.stat("target_pct"), 125, "the Milano twist all tour")
	run.town = 8
	run.city = "c_milano"
	eq(run.stat("target_pct"), 125, "and only once in Milano itself")
	run._start_town()
	eq(run.town_patron, "pt_banchiere", "the story Patron waits in town 8")

	var loop := _run({"chapter": "ch_01"}, "d_bergamo")
	eq([(loop.route[0] as Array)[0]["city"], (loop.route[7] as Array)[0]["city"]], ["c_bergamo", "c_bergamo"], "chapter 1 loops out and back")
	loop.town = 7
	loop._roll_scenario()
	eq(ContentDB.get_def(loop.scenario).data["tier"], 1, "Scenarios stay tier 1")


func test_chapter_rules() -> void:
	eq(_run({"chapter": "ch_04"}, "d_genova").ducats, 0, "Il Porto: 0 ducats")
	eq(_run({"chapter": "ch_04", "props": ["p_salvadanaio"]}, "d_genova").ducats, 2, "a piggy bank still helps")
	var sea := _run({"chapter": "ch_10"}, "d_bergamo")
	eq(sea.city, "c_napoli", "chapter 10 sets out from Napoli")
	eq([sea.stat("hands"), sea.stat("hand_size")], [4 - 1, 8 + 1], "Il Mare: -1 hand, +1 card")
	var shop := _run({"chapter": "ch_06"}, "d_firenze")
	shop.phase = RunState.Phase.SHOP
	shop.open_pack("pk_tarocchi_small")
	var last: Dictionary = (shop.pack["items"] as Array).back()
	ok(last["kind"] == "card" and last["card"]["enh"] != "", "La Bottega: every pack holds an enhanced card")


func test_messer_grifone_buys_out_the_troupe() -> void:
	var run := _run({"chapter": "ch_16"}, "d_venezia")
	run.town = 8
	run._start_town()
	eq(run.town_patron, "pt_grifone", "Grifone waits in Venezia")
	_give(run, ["z_plus4", "z_plus4", "z_plus4"])
	run.show_index = Shows.PATRON
	_show(run, "2H 3H 4H 5H")
	_play(run, 1)
	eq(run.zanni.map(func(z: ItemCard) -> bool: return z.debuffed), [false, false, true], "the rightmost stops working")
	_play(run, 1)
	eq(run.zanni.map(func(z: ItemCard) -> bool: return z.debuffed), [false, true, true], "then the next")
	_real()
	for i in 40:
		var late := RunState.create("NOGRIF%d" % i)
		late.town = 8
		late._start_town()
		ok(late.town_patron != "pt_grifone", "never outside the campaign")


func test_the_carried_jester() -> void:
	var one := _run({"chapter": "ch_03", "carry": {"id": "z_zanni"}}, "d_bergamo")
	eq(one.zanni.map(func(z: ItemCard) -> String: return z.def_id), ["z_zanni"], "joins first")
	var duo := _run({"chapter": "ch_03", "carry": {"id": "lz_sposi", "parts": ["z_arlecchino", "z_colombina"]}}, "d_bergamo")
	eq(duo.zanni[0].parts.map(func(z: ItemCard) -> String: return z.def_id), ["z_arlecchino", "z_colombina"], "a duo with its two Jesters")


func test_clearing_a_chapter() -> void:
	var p := Profile.new()
	p.chapters_cleared = 3
	var run := _run({"chapter": "ch_04"}, "d_genova")
	run.won = true
	p.record_run(run)
	eq(p.chapters_cleared, 4, "chapter 4 cleared")
	ok(p.bought.has("d_genova") and p.deck_unlocked("d_genova"), "the Genova deck")
	eq(p.scudi, 20 + WagonCards.RUN_WON, "20 scudi, plus the run's own")
	eq(p.last_gains["reward"]["scudi"], 20, "shown on the end screen")
	p.record_run(run)
	eq(p.chapters_cleared, 4, "clearing it again gives nothing more")
	p.carry = {"id": "z_zanni", "parts": []}
	ok(p.extras_for("ch_05").has("carry"), "the carried Jester goes into the next chapter")
	ok(not p.extras_for("ch_02").has("carry"), "not into an old one")
	var last := _run({"chapter": "ch_16"}, "d_venezia")
	last.won = true
	p.chapters_cleared = 15
	p.record_run(last)
	ok(p.titles.has("Compagnia Reale") and p.cosmetics.has("paint_oro") and p.bought.has("d_carnevale"), "the finale's rewards")


# --- saves ---

func test_extras_survive_a_save_and_replay() -> void:
	var extras := {"maestri": ["z_zanni"], "props": ["p_salvadanaio", "p_lanterna"], "chapter": "ch_03",
		"carry": {"id": "z_zanni", "parts": []}, "rivalry": true, "nemesis": {"patron": "pt_duca", "town": 4}}
	var run := _run(extras, "d_padova", "B13-SAVE")
	run.apply({"a": "select_show", "perform": true})
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 2))})
	run.rematch = {}
	var text := JSON.stringify(run.to_dict())
	var loaded := RunState.from_dict(JSON.parse_string(text))
	eq(JSON.stringify(loaded.to_dict()), text, "saved and loaded")
	ok(loaded.is_maestro(loaded.zanni[0]) and loaded.chapter == "ch_03" and loaded.props.size() == 2, "the extras come back")
	var again := RunState.replay("B13-SAVE", "d_padova", 1, run.action_log, "", [], extras)
	eq(JSON.stringify(again.to_dict()), text, "and replay from the log")
