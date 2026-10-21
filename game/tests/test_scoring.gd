extends TestCase


func _score(run: RunState, played: String, held := "") -> ScoreContext:
	return Scorer.score(run, cards(played), cards(held))


func _with(zanni_ids: Array) -> RunState:
	var run := RunState.create("SCORING")
	for z in zanni_ids:
		run.zanni.append(ItemCard.make(z, 0))
	return run


func test_base_hands() -> void:
	var run := _with([])
	eq(_score(run, "KH KS 2C").total, 60, "pair of kings: (10+10+10) x 2")
	eq(_score(run, "AS").total, 16, "high card ace: (5+11) x 1")
	eq(_score(run, "2H 7H 9H JH KH").total, 292, "flush: (35+2+7+9+10+10) x 4")


func test_flat_and_card_effects() -> void:
	eq(_score(_with(["z_plus4"]), "KH KS 2C").total, 180, "+4 mult")
	eq(_score(_with(["z_kings20"]), "KH KS 2C").total, 140, "+20 points per king")
	eq(_score(_with(["z_pair8"]), "3H 3S 3C 9D 9H").total, 804, "full house contains a pair: 67 x 12")


func test_zanni_order_matters() -> void:
	eq(_score(_with(["z_plus4", "z_x2"]), "KH KS").total, 360, "+4 then x2: 30 x 12")
	eq(_score(_with(["z_x2", "z_plus4"]), "KH KS").total, 240, "x2 then +4: 30 x 8")


func test_held_cards() -> void:
	var ctx := _score(_with(["z_steel_queens"]), "KH KS", "QH QS 2C")
	eq(ctx.total, 135, "two held queens: 30 x 2 x 1.5 x 1.5")


func test_retriggers_and_debuffs() -> void:
	var run := _with([])
	var played := cards("KH KS")
	played[0].seal = "seal_red"
	eq(Scorer.score(run, played, cards("")).total, 80, "red seal scores the king twice")
	eq(_score(_with(["z_echo_first"]), "KH KS").total, 80, "first card retriggered")
	var debuffed := cards("KH KS")
	debuffed[0].debuffed = true
	eq(Scorer.score(run, debuffed, cards("")).total, 40, "debuffed card adds nothing")


func test_stone_and_levels() -> void:
	var run := _with([])
	eq(_score(run, "KH KS 5C:enh_stone").total, 160, "stone adds 50 and always scores")
	run.hand_levels.level_up(HandTable.PAIR)
	eq(_score(run, "KH KS").total, 135, "pair level 2: (25+20) x 3")
	eq(run.hand_levels.times_played(HandTable.PAIR), 2, "plays counted")


func test_events_trace_the_score() -> void:
	var ctx := _score(_with(["z_plus4"]), "KH KS")
	eq(ctx.events[0]["t"], "base", "starts with the base")
	var last: Dictionary = ctx.events[ctx.events.size() - 1]
	eq(last["points"], 30, "running points")
	eq(last["mult"], 6, "running mult")
	eq(last["src"], "zanni:z_plus4#0", "source label")
