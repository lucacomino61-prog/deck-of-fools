extends TestCase
## Longer runs (Luca, 2026-10-28): every town has a fourth show, the Gala; towns 1–3 ask for
## more; and the Grand Tour runs 16 towns from Palermo to Venezia.


func _real() -> void:
	ContentPacks.register_all()
	TestContent.add_test_defs()


func test_four_shows_a_town() -> void:
	eq(Shows.SIZE, [1.0, 1.5, 1.75, 2.0], "Matinee, Evening, Gala, Patron")
	var run := RunState.create("GALA")
	eq(run.town_favors.size(), 3, "a Favor for every show that can be skipped")
	ok(run.town_favors.all(func(f: String) -> bool: return f != ""), "all three are drawn")
	eq(run.target_for_show(Shows.GALA), 700.0, "the Gala: 400 x 1.75")
	eq(run.stat("reward_gala"), 4, "it pays 4 ducats")


func test_harder_early_towns() -> void:
	eq([Shows.base_target(1, 1), Shows.base_target(2, 1), Shows.base_target(3, 1), Shows.base_target(4, 1)],
		[400.0, 1100.0, 2600.0, 5000.0], "towns 1-3 raised, town 4 on as before")
	eq(Shows.base_target(8, 1), 50000.0, "the last town as before")


func test_grand_tour_targets() -> void:
	var last := Shows.base_target(Shows.GRAND_TOWNS, 1, Shows.GRAND_TOWNS)
	eq(last, Shows.base_target(10, 1), "its last town is as hard as town 10 of a normal tour")
	eq(Shows.base_target(1, 1, Shows.GRAND_TOWNS), 400.0, "it starts at the same 400")
	var climbing := true
	for t in range(2, Shows.GRAND_TOWNS + 3):
		if Shows.base_target(t, 1, Shows.GRAND_TOWNS) <= Shows.base_target(t - 1, 1, Shows.GRAND_TOWNS):
			climbing = false
	ok(climbing, "every town asks for more than the one before, past the end too")
	ok(Shows.base_target(8, 1, Shows.GRAND_TOWNS) < Shows.base_target(8, 1), "halfway is gentler than a normal tour's town 8")


func test_grand_tour_route() -> void:
	_real()
	var run := RunState.create("GRAND", "d_bergamo", 1, "", [], {}, Shows.GRAND_TOWNS)
	ok(run.tour, "on tour")
	eq(run.route.size(), Shows.GRAND_TOWNS, "16 towns on the map")
	eq(run.city, Shows.GRAND_START, "it sets out from Palermo, whatever the deck")
	eq(run.route[Shows.GRAND_TOWNS - 1][0]["city"], CityCards.VENEZIA, "and ends in Venezia")
	var repeats := false
	for row in range(1, run.route.size()):
		for node in run.route[row]:
			if (run.route[row - 1] as Array).any(func(n: Dictionary) -> bool: return n["city"] == node["city"]):
				repeats = true
	ok(not repeats, "no city twice in a row")
	ok(run.assisted(), "off the leaderboards")
	eq(RunState.from_dict(run.to_dict()).towns, Shows.GRAND_TOWNS, "the save keeps it")
	ok(not RunState.create("NORMAL", "d_bergamo").assisted(), "a normal tour stays ranked")


func test_grand_tour_is_won_in_town_16() -> void:
	var run := RunState.create("LONG", "standard", 1, "", [], {}, Shows.GRAND_TOWNS)
	run.zanni.append(ItemCard.make("z_huge", 1))
	for i in 200:
		if run.won:
			break
		if run.phase == RunState.Phase.CHOOSE_SHOW:
			run.apply({"a": "select_show"})
		run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})
		run.apply({"a": "cash_out"})
		if not run.won:
			run.apply({"a": "leave_shop"})
	ok(run.won, "won")
	eq(run.town, Shows.GRAND_TOWNS, "in town 16, not town 8")
	eq(run.counters.get("shows_won", 0), Shows.GRAND_TOWNS * (Shows.PATRON + 1), "four shows in each of 16 towns")


func test_old_saves_move_the_patron() -> void:
	var run := RunState.create("OLD")
	run.show_index = Shows.PATRON
	var data := run.to_dict()
	data["v"] = 3
	data["show"] = 2
	data["town_favors"] = ["f_a", "f_b"]
	data.erase("towns")
	var loaded := RunState.from_dict(data)
	eq(loaded.show_index, Shows.PATRON, "the old third show (the Patron) is the fourth now")
	eq(loaded.town_favors, ["f_a", "f_b", ""], "two old Favors, none for the Gala")
	eq(loaded.towns, Shows.FINAL_TOWN, "an old save is a normal tour")
