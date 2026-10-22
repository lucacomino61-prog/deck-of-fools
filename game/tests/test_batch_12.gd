extends TestCase
## Card batch 12: the tour (the Map of Italy, city twists, Scenarios, the crowd and the
## Encore) and the Lazzi do what cards/batch-12.md says.


## A tour run from Padova, whose twist (Signs level twice) doesn't touch scoring.
func _tour(deck := "d_padova", seed_text := "B12") -> RunState:
	ContentPacks.register_all()
	TestContent.add_test_defs()
	return RunState.create(seed_text, deck, 1)


## Starts the matinee with `hand` in hand and a huge target (no win unless a test lowers it).
func _show(run: RunState, hand: String, perform := false, scenario := "") -> void:
	if scenario != "":
		run.scenario = scenario
	run.apply({"a": "select_show", "perform": perform})
	run.show_target = 1000000000.0
	run.hand.assign(cards(hand))


## Plays the first `n` cards of the hand; returns the result.
func _play(run: RunState, n: int) -> Dictionary:
	return run.apply({"a": "play", "cards": ids(run.hand.slice(0, n))})


func _events(result: Dictionary, src: String) -> Array:
	return (result.get("events", []) as Array).filter(func(e: Dictionary) -> bool: return e["src"] == src)


func _to_shop(run: RunState) -> void:
	run.phase = RunState.Phase.CASH_OUT
	run.apply({"a": "cash_out"})
	run.ducats = 100


# --- content and text ---

func test_batch_contents_and_text() -> void:
	ContentPacks.register_all()
	for tier in [1, 2, 3]:
		eq(ContentDB.pool("scenario", func(d: ContentDef) -> bool: return d.data["tier"] == tier).size(), 8, "8 Scenarios in tier %d" % tier)
	eq(ContentDB.pool("city").size(), 24, "24 cities")
	eq(ContentDB.pool("lazzo").size(), 15, "15 duos")
	var keys := {}
	var f := FileAccess.open("res://i18n/cards.csv", FileAccess.READ)
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() >= 2 and line[1] != "":
			keys[line[0]] = true
	for d in ContentDB.pool("scenario"):
		ok(keys.has(d.id + ".name"), d.id + " has a name")
		eq((d.data["beats"] as Array).size(), 3, d.id + " has three beats")
	for d in ContentDB.pool("city"):
		for k in ["name", "gloss", "text", "lean"]:
			ok(keys.has("%s.%s" % [d.id, k]), "%s has a %s" % [d.id, k])
	for d in ContentDB.pool("lazzo"):
		ok(keys.has(d.id + ".name") and keys.has(d.id + ".text"), d.id + " has a name and text")
		for part in d.data["parts"]:
			ok(ContentDB.get_def(part) != null and ContentDB.get_def(part).kind == "zanni", "%s: %s is a Jester" % [d.id, part])
	for deck in ContentDB.pool("deck"):
		ok(CityCards.home_of(deck.id, RunState.new()) != "", deck.id + " has a home city")


# --- the map ---

func test_route_runs_from_home_to_venezia() -> void:
	var run := _tour()
	ok(run.tour, "a city deck goes on tour")
	eq(run.route.size(), 8, "8 rows")
	eq(run.city, "c_padova", "starts at home")
	eq((run.route[0] as Array).map(func(n: Dictionary) -> String: return n["city"]), ["c_padova"], "row 1 is home")
	eq((run.route[7] as Array).map(func(n: Dictionary) -> String: return n["city"]), ["c_venezia"], "row 8 is Venezia")
	var seen := {}
	for row in range(1, 7):
		eq((run.route[row] as Array).size(), 3, "row %d has 3 cities" % (row + 1))
		for node in run.route[row]:
			ok(not seen.has(node["city"]) and node["city"] != "c_padova" and node["city"] != "c_venezia", "%s only once" % node["city"])
			seen[node["city"]] = true
	for row in range(0, 7):
		for node in run.route[row]:
			ok(not (node["to"] as Array).is_empty(), "%s has a road on" % node["city"])
		for j in (run.route[row + 1] as Array).size():
			ok((run.route[row] as Array).any(func(n: Dictionary) -> bool: return (n["to"] as Array).has(j)), "row %d city %d can be reached" % [row + 2, j])
	var again := _tour()
	eq(JSON.stringify(again.route), JSON.stringify(run.route), "the same seed draws the same map")


func test_a_deck_without_a_city_plays_the_classic_rules() -> void:
	var run := RunState.create("CLASSIC")
	ok(not run.tour and run.route.is_empty() and run.city == "" and run.scenario == "", "no tour")


func test_travel_follows_the_roads() -> void:
	var run := _tour()
	run.show_index = Shows.PATRON
	_to_shop(run)
	run.apply({"a": "leave_shop"})
	eq(run.phase, RunState.Phase.MAP, "after the Patron, the map")
	eq(run.town, 2, "town 2")
	var roads: Array = (run.route[0] as Array)[0]["to"]
	var blocked := -1
	for j in 3:
		if not roads.has(j):
			blocked = j
	if blocked >= 0:
		ok(not run.apply({"a": "travel", "index": blocked})["ok"], "no road, no travel")
	ok(run.apply({"a": "travel", "index": roads[0]})["ok"], "travel along a road")
	eq(run.city, (run.route[1] as Array)[roads[0]]["city"], "arrived")
	eq(run.phase, RunState.Phase.CHOOSE_SHOW, "ready for the matinee")
	ok(run.scenario != "", "the show has a Scenario")


func test_messina_asks_on_arrival() -> void:
	var run := _tour()
	run.route[1] = [{"city": "c_messina", "to": [0]}]
	(run.route[0] as Array)[0]["to"] = [0]
	run.show_index = Shows.PATRON
	_to_shop(run)
	run.apply({"a": "leave_shop"})
	ok(not run.apply({"a": "travel", "index": 0, "slot": 5})["ok"], "an answer is needed")
	ok(run.apply({"a": "travel", "index": 0, "slot": 1})["ok"], "targets x1.25")
	eq([run.stat("target_pct"), run.stat("hands")], [125, 4], "bigger targets, same hands")
	run.town_option = 0
	eq([run.stat("target_pct"), run.stat("hands")], [100, 3], "or one hand less")


# --- cities ---

func test_city_stats() -> void:
	var run := _tour()
	var expect := {
		"c_bergamo": {"hands": 5, "zanni_rate_pct": 150},
		"c_lucca": {"hands": 5, "discards": 2, "warrant_discount": 2},
		"c_bari": {"hand_size": 9},
		"c_milano": {"target_pct": 125, "reward_matinee": 6, "pack_discount": 1},
		"c_torino": {"reward_patron": 10, "tarocchi_rate_pct": 200},
		"c_roma": {"patron_target_pct": 150, "reward_patron": 15},
		"c_genova": {"sell_pct": 200},
		"c_padova": {"sign_levels": 2},
		"c_amalfi": {"gilt_mult": 2, "card_rate": 6},
		"c_palermo": {"reverse_jesters": 1, "pack_zanni_pct": 300},
		"c_venezia": {"edition_rate_pct": 200},
	}
	for c in expect:
		run.city = c
		for s in expect[c]:
			eq(run.stat(s), expect[c][s], "%s: %s" % [c, s])
	run.city = "c_pisa"
	ok(run.eval_options()["straight_gap"], "Pisa: Straights may skip a rank")


## The same pair of Kings (Hearts and Spades) played in each city.
func _kings_in(city_id: String, hand := "KH KS") -> float:
	var run := _tour()
	run.city = city_id
	_show(run, hand)
	return float(_play(run, hand.split(" ").size())["total"])


func test_city_scoring_twists() -> void:
	eq(_kings_in("c_padova"), 60.0, "plain: (10 + 20) x 2")
	eq(_kings_in("c_verona"), 150.0, "Verona: the Heart adds 3 Mult")
	eq(_kings_in("c_firenze"), 100.0, "Firenze: two faces add 20 Points")
	eq(_kings_in("c_ferrara"), 90.0, "Ferrara: red then black x1.5")
	eq(_kings_in("c_mantova"), 120.0, "Mantova: the first hand x2")
	eq(_kings_in("c_parma", "5H 5S"), 60.0, "Parma: two number cards add 10 Points")
	eq(_kings_in("c_urbino", "KH KS 2C 7D 9S"), 90.0, "Urbino: five cards x1.5")


func test_palermo_turns_the_jesters_round() -> void:
	var totals := []
	for city_id in ["c_padova", "c_palermo"]:
		var run := _tour()
		run.city = city_id
		run.zanni.assign([ItemCard.make("z_plus4", 3), ItemCard.make("z_x2", 6)])
		_show(run, "2H")
		totals.append(float(_play(run, 1)["total"]))
	eq(totals, [7.0 * 10.0, 7.0 * 6.0], "High Card 5+2 Points; +4 then x2 makes 10 Mult, x2 then +4 makes 6")


func test_siena_napoli_trieste_bologna() -> void:
	var siena := _tour()
	siena.city = "c_siena"
	_show(siena, "KH KS")
	siena.show_target = 100.0
	var before := siena.ducats
	_play(siena, 2)
	eq(siena.ducats - before, 5, "Siena: the Palio pays 5")

	var napoli := _tour()
	napoli.city = "c_napoli"
	_show(napoli, "2H 3H 4H 5H")
	_play(napoli, 1)
	eq(napoli.draw_pile.filter(func(c: PlayingCard) -> bool: return c.enhancement == "enh_marble").size(), 0, "nothing after one hand")
	_play(napoli, 1)
	eq(napoli.draw_pile.filter(func(c: PlayingCard) -> bool: return c.enhancement == "enh_marble").size(), 2, "two Marble cards after the second")

	var trieste := _tour()
	trieste.city = "c_trieste"
	_show(trieste, "2H 3H 4H 5H 6H 7H 8H 9H")
	trieste.apply({"a": "discard", "cards": [trieste.hand[0].id]})
	eq(trieste.discard_pile.size(), 2, "Trieste: the bora takes a second card")

	var bologna := _tour()
	bologna.city = "c_bologna"
	_show(bologna, "2H 3H 4H 5H 6H 7H 8H 9H")
	bologna.apply({"a": "discard", "cards": [bologna.hand[0].id]})
	eq([bologna.stat("hand_size"), bologna.hand.size()], [9, 9], "Bologna: a discard grows the hand")


func test_venezia_masks_until_a_jester_acts() -> void:
	var run := _tour()
	run.city = "c_venezia"
	run.zanni.assign([ItemCard.make("z_plus4", 3), ItemCard.make("z_payer", 4)])
	_show(run, "KH KS")
	ok(run.zanni.all(func(z: ItemCard) -> bool: return z.face_down), "masked at the start")
	_play(run, 2)
	eq(run.zanni.map(func(z: ItemCard) -> bool: return z.face_down), [false, true], "the one that scored unmasks")


# --- Scenarios ---

func test_scenario_beats_pay() -> void:
	var run := _tour()
	_show(run, "KH KS QH QS 2C 3D", true, "sc_servitore")
	var one := _play(run, 2)
	eq(_events(one, "scenario"), [], "beat 1 has no xMult")
	eq(run.scenario_beat, 1, "beat 1 hit")
	var two := _play(run, 2)
	eq((_events(two, "scenario")[0] as Dictionary)["v"], 2.0, "beat 2 x2")
	run.hand.assign(cards("KH KS QH QS 2C"))
	run.show_target = 1.0
	var three := _play(run, 4)
	eq((_events(three, "scenario")[0] as Dictionary)["v"], 3.0, "the finale x3")
	ok(run.payout.has({"src": "scenario", "v": 8}), "3 + 5 ducats at cash-out")
	eq(run.show_counters["scenario"], "done", "performed to the end")


func test_fiasco_halves_the_hand_and_ends_the_scenario() -> void:
	var run := _tour()
	_show(run, "KH 9S 2C", true, "sc_servitore")
	var miss := _play(run, 2)
	eq((_events(miss, "fiasco")[0] as Dictionary)["v"], 0.5, "the missed beat halves the hand")
	ok(not run.scenario_on, "the Scenario is over")
	eq(run.show_counters["scenario"], "fiasco", "a Fiasco")
	eq(run.mood, 0, "a weak hand (-2) and a Fiasco (-3) empty the crowd")


func test_improvising_has_no_beats() -> void:
	var run := _tour()
	_show(run, "KH 9S", false, "sc_servitore")
	var hand := _play(run, 2)
	eq(_events(hand, "fiasco") + _events(hand, "scenario"), [], "no Scenario, no beat")


func test_beat_checks() -> void:
	var run := _tour()
	_show(run, "KH KS")
	var ctx := ScoreContext.new()
	ctx.run = run
	ctx.played.assign(cards("KH KS 4H"))
	ctx.contains = {HandTable.PAIR: true, HandTable.HIGH_CARD: true}
	ctx.hand_type = HandTable.PAIR
	ok(ScenarioCards.beat_met(ctx, {"hand": HandTable.PAIR}), "contains a Pair")
	ok(not ScenarioCards.beat_met(ctx, {"exact": HandTable.HIGH_CARD}), "isn't a High Card")
	ok(ScenarioCards.beat_met(ctx, {"cards": 3}), "three cards")
	ok(ScenarioCards.beat_met(ctx, {"faces": true}) and not ScenarioCards.beat_met(ctx, {"faces": false}), "has a face card")
	ok(ScenarioCards.beat_met(ctx, {"suit_any": PlayingCard.Suit.SPADES}) and not ScenarioCards.beat_met(ctx, {"suit_all": PlayingCard.Suit.HEARTS}), "a Spade, not only Hearts")
	ok(ScenarioCards.beat_met(ctx, {"rank_any": PlayingCard.KING}) and not ScenarioCards.beat_met(ctx, {"rank_any": PlayingCard.QUEEN}), "a King, no Queen")
	eq(ScenarioCards.beat_text({"hand": HandTable.TWO_PAIR}), "Two Pair", "beat text")
	eq(ScenarioCards.beat_text({"suit_all": PlayingCard.Suit.DIAMONDS}), "only Diamonds", "beat text")


# --- the crowd and the Encore ---

func test_mood_ovation() -> void:
	var run := _tour()
	_show(run, "KH KS KD KC QH QS QD QC")
	run.show_target = 100.0
	var moods := []
	var ovations := []
	for i in 3:
		run.show_score = 0.0
		var result := _play(run, 2)
		moods.append(run.mood)
		ovations.append(_events(result, "ovation").size())
	eq(moods, [8, 10, 10], "+3 per big hand; after an ovation the meter drops to 7 first")
	eq(ovations, [0, 0, 1], "the hand after a full meter gets the ovation")


func test_walkout_costs_ducats() -> void:
	var run := _tour()
	_show(run, "2H 3S 4D 5C 7H 9S KH KS")
	for i in 3:
		_play(run, 1)
	eq(run.mood, 0, "three weak hands empty the crowd")
	run.show_target = 1.0
	_play(run, 2)
	ok(run.payout.has({"src": "crowd", "v": -3}), "the crowd walked out: -3 ducats")
	eq(run.phase, RunState.Phase.CASH_OUT, "no Encore for an empty house")


func _won_to_encore(run: RunState) -> int:
	_show(run, "KH KS KD KC 2H 3S 4D 5C")
	run.show_target = 100.0
	_play(run, 2)
	_play(run, 2)
	var total := 0
	for p in run.payout:
		total += int(p["v"])
	return total


func test_encore_hit_doubles_the_cash_out() -> void:
	var run := _tour()
	var before := _won_to_encore(run)
	eq(run.phase, RunState.Phase.ENCORE, "the crowd demands an Encore")
	ok(run.apply({"a": "encore"})["ok"], "Encore!")
	eq(run.encore_target(), 50.0, "half the target")
	run.hand.assign(cards("QH QS 2C"))
	var result := _play(run, 2)
	ok(bool(result["encore"]), "60 beats 50")
	ok(run.payout.has({"src": "encore", "v": before}), "the cash-out doubles")
	eq(run.phase, RunState.Phase.CASH_OUT, "then cash out")


func test_encore_miss_loses_the_show_reward() -> void:
	var run := _tour()
	_won_to_encore(run)
	run.apply({"a": "encore"})
	run.hand.assign(cards("2C 3D"))
	_play(run, 1)
	ok(not run.payout.any(func(p: Dictionary) -> bool: return p["src"] == "show"), "the show's reward is gone")


func test_bowing_out_keeps_the_cash_out() -> void:
	var run := _tour()
	var before := _won_to_encore(run)
	ok(run.apply({"a": "bow"})["ok"], "a bow")
	var after := 0
	for p in run.payout:
		after += int(p["v"])
	eq([run.phase, after], [RunState.Phase.CASH_OUT, before], "the cash-out as it was")
	ok(not run.apply({"a": "encore"})["ok"], "too late for an Encore")


# --- Lazzi ---

func _shop_with(zanni_ids: Array) -> RunState:
	ContentPacks.register_all()
	TestContent.add_test_defs()
	var run := RunState.create("LAZZI")
	for id in zanni_ids:
		run.zanni.append(ItemCard.make(id, ContentDB.get_def(id).cost))
	_to_shop(run)
	return run


func test_merging_a_duo() -> void:
	var run := _shop_with(["z_flavio", "z_plus4", "z_isabella"])
	eq(LazziCards.merges_for(run, 0), [{"duo": "lz_isabella_flavio", "index": 0, "other": 2}], "Flavio can merge with Isabella")
	ok(not run.apply({"a": "merge", "index": 0, "other": 1})["ok"], "no routine with z_plus4")
	ok(run.apply({"a": "merge", "index": 2, "other": 0})["ok"], "merged")
	eq(run.zanni.map(func(z: ItemCard) -> String: return z.def_id), ["lz_isabella_flavio", "z_plus4"], "one slot, at the first's seat")
	eq(run.zanni[0].parts.map(func(z: ItemCard) -> String: return z.def_id), ["z_isabella", "z_flavio"], "in the duo's order")
	eq(run.zanni[0].sell_value(), run.zanni[0].parts[0].sell_value() + run.zanni[0].parts[1].sell_value(), "sells for both")


func test_duo_numbers_grow() -> void:
	var run := _shop_with(["z_isabella", "z_flavio"])
	run.apply({"a": "merge", "index": 0, "other": 1})
	run.phase = RunState.Phase.CHOOSE_SHOW
	_show(run, "KH KS QH QS 2C")
	var result := _play(run, 4)
	var mine := _events(result, "zanni:lz_isabella_flavio#0")
	eq(mine.map(func(e: Dictionary) -> Array: return [e["t"], e["v"]]),
		[["points", 25.0], ["mult", 8.0], ["points", 30.0], ["mult", 9.0]], "Pair +25/+8, Two Pair +30/+9")


func test_duo_seat_copy_and_xmult() -> void:
	var run := _shop_with(["z_plus4", "z_plus4", "z_martinelli", "z_arlecchino"])
	run.apply({"a": "merge", "index": 2, "other": 3})
	run.phase = RunState.Phase.CHOOSE_SHOW
	_show(run, "2H")
	var mine := _events(_play(run, 1), "zanni:lz_primo_arlecchino#2")
	ok(mine.has({"t": "mult", "v": 6.0, "src": "zanni:lz_primo_arlecchino#2", "card": -1, "points": mine[0]["points"], "mult": mine[0]["mult"]}) or mine.any(func(e: Dictionary) -> bool: return e["t"] == "mult" and e["v"] == 6.0), "Arlecchino: +3 for each of 2 Jesters to the left")
	eq(mine.filter(func(e: Dictionary) -> bool: return e["t"] == "xmult").map(func(e: Dictionary) -> float: return e["v"]), [1.75, 1.75], "Martinelli: x1.75 per Jester to the left")

	var copy := _shop_with(["z_burattinaio", "z_burattino", "z_plus4"])
	copy.apply({"a": "merge", "index": 0, "other": 1})
	copy.phase = RunState.Phase.CHOOSE_SHOW
	_show(copy, "2H")
	var theirs := _events(_play(copy, 1), "zanni:lz_burattini#0")
	eq(theirs.map(func(e: Dictionary) -> Array: return [e["t"], e["v"]]), [["mult", 6.0], ["points", 30.0]], "copies +4 as +6; +15 Points per Jester (2)")


func test_duo_ducats_grow() -> void:
	var run := _shop_with(["z_brighella", "z_truffaldino"])
	run.apply({"a": "merge", "index": 0, "other": 1})
	run.apply({"a": "leave_shop"})
	var before := run.ducats
	run.apply({"a": "skip_show"})
	eq(run.ducats - before - 5, 6, "Truffaldino's +4 for a skip becomes +6 (and the test Favor's +5)")


func test_duo_survives_a_save() -> void:
	var run := _shop_with(["z_pantalone", "z_dottore"])
	run.apply({"a": "merge", "index": 0, "other": 1})
	run.zanni[0].parts[0].state["mult"] = 3
	var text := JSON.stringify(run.to_dict())
	var loaded := RunState.from_dict(JSON.parse_string(text))
	eq(JSON.stringify(loaded.to_dict()), text, "saved and loaded")
	eq(loaded.zanni[0].parts[0].state["mult"], 3, "each Jester keeps its own state")


func test_tour_survives_a_save_and_replay() -> void:
	var run := _tour("d_bergamo", "B12-SAVE")
	run.apply({"a": "select_show", "perform": true})
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 2))})
	var text := JSON.stringify(run.to_dict())
	eq(JSON.stringify(RunState.from_dict(JSON.parse_string(text)).to_dict()), text, "a tour save loads back")
	var again := RunState.replay("B12-SAVE", "d_bergamo", 1, run.action_log)
	eq(JSON.stringify(again.to_dict()), text, "and replays from its log")
