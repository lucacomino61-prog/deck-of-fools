extends TestCase
## Learning the game (Luca, 2026-10-28): one new part per run for a new player, and the
## practice town before the first tour.


func _real() -> void:
	ContentPacks.register_all()
	TestContent.add_test_defs()


func _run_at(level: int, seed_text := "LEARN") -> RunState:
	_real()
	return RunState.create(seed_text, "d_bergamo", 1, "", [], {"learning": level})


## Every offer and pack kind the Market shows over many rerolls.
func _market_kinds(run: RunState) -> Dictionary:
	var kinds := {}
	run.apply({"a": "select_show"})
	run.show_target = 1.0
	run.apply({"a": "play", "cards": [run.hand[0].id]})
	run.apply({"a": "cash_out"})
	run.ducats = 100000
	for i in 60:
		for o in run.shop.offers:
			kinds[o["kind"]] = true
		for p in run.shop.packs:
			kinds["pack:" + str(ContentDB.get_def(p["id"]).data["contents"])] = true
		run.apply({"a": "reroll"})
	return kinds


func test_first_run_has_the_heart_only() -> void:
	var run := _run_at(0)
	ok(not run.tour, "no map yet: the classic route")
	eq(run.town_warrant, "", "no Warrants yet")
	ok(not run.apply({"a": "skip_show"})["ok"], "no skipping for Favors yet")
	var kinds := _market_kinds(run)
	ok(kinds.has("zanni"), "Jesters in the Market")
	ok(not kinds.has("sign") and not kinds.has("tarocchi") and not kinds.has("omen"), "no Signs, Tarocchi or Omens")
	ok(not kinds.has("pack:sign") and not kinds.has("pack:tarocchi") and not kinds.has("pack:omen"), "nor their packs")


func test_each_run_adds_a_part() -> void:
	ok(_market_kinds(_run_at(1, "L1")).has("sign"), "run 2: Signs")
	ok(_market_kinds(_run_at(2, "L2")).has("tarocchi"), "run 3: Tarocchi")
	var favors := _run_at(3, "L3")
	ok(favors.apply({"a": "skip_show"})["ok"], "run 4: skipping for Favors")
	var map := _run_at(4, "L4")
	ok(map.tour, "run 5: the Map of Italy")
	eq(map.scenario, "", "but no Scenarios yet")
	map.apply({"a": "select_show"})
	map.apply({"a": "play", "cards": [map.hand[0].id]})
	eq(map.mood, RunState.MOOD_START, "and the crowd doesn't react yet")
	var full := _run_at(5, "L5")
	ok(full.tour and full.scenario != "", "run 6: Scenarios")
	ok(not full.has_part("lazzi") and _run_at(Learning.FULL).has_part("lazzi"), "run 7: Lazzi and Omens")
	ok(RunState.create("ALL", "d_bergamo").has_part("omens"), "a run without a level has everything")


func test_news_for_each_level() -> void:
	eq(Learning.NEWS.size(), Learning.FULL + 1, "a line for every level")
	ok(Learning.next_news(0).begins_with("Signs"), "after the first run: Signs")
	eq(Learning.next_news(Learning.FULL), "", "nothing after everything")


func test_practice_town() -> void:
	_real()
	var run := RunState.create("PRACTICE", "d_bergamo", 1, "", [], {"learning": 0, "practice": true}, 1)
	eq(run.ducats, RunState.PRACTICE_DUCATS, "ducats to buy a Jester")
	eq(run.target_for_show(Shows.MATINEE), 200.0, "half targets")
	run.apply({"a": "select_show"})
	run.hands_left = 1
	run.apply({"a": "play", "cards": [run.hand[0].id]})
	eq(run.phase, RunState.Phase.CASH_OUT, "out of hands, the show passes anyway")
	run.apply({"a": "cash_out"})
	ok(run.shop.offers.any(func(o: Dictionary) -> bool: return o["kind"] == "zanni"), "the Market has a Jester")
	run.apply({"a": "leave_shop"})
	for i in 3:
		run.apply({"a": "select_show"})
		run.hands_left = 1
		run.apply({"a": "play", "cards": [run.hand[0].id]})
		run.apply({"a": "cash_out"})
		if not run.won:
			run.apply({"a": "leave_shop"})
	ok(run.won, "one town and it's done")
	eq(run.town, 1, "in town 1")
