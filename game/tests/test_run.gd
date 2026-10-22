extends TestCase


func _hand_ids(run: RunState, count: int) -> Array:
	return ids(run.hand.slice(0, count))


func _lowest_card(run: RunState) -> int:
	var best := run.hand[0]
	for card in run.hand:
		if card.rank < best.rank:
			best = card
	return best.id


## Wins the current show with z_huge in the troupe, then cashes out into the shop.
func _win_show(run: RunState) -> void:
	if run.phase == RunState.Phase.CHOOSE_SHOW:
		run.apply({"a": "select_show"})
	run.apply({"a": "play", "cards": _hand_ids(run, 5)})
	run.apply({"a": "cash_out"})


func test_new_run() -> void:
	var run := RunState.create("NEW")
	eq(run.full_deck.size(), 52, "52 cards")
	eq(run.ducats, 4, "starting ducats")
	eq(run.phase, RunState.Phase.CHOOSE_SHOW, "choosing a show")
	eq(run.town_patron, "patron_hearts", "regular patron for town 1")
	ok(run.apply({"a": "select_show"})["ok"], "select works")
	eq(run.hand.size(), 8, "8 cards in hand")
	eq(run.draw_pile.size(), 44, "44 left to draw")
	eq(run.hands_left, 4, "4 hands")
	eq(run.discards_left, 3, "3 discards")
	eq(run.show_target, 300, "town 1 matinee target")


func test_play_and_discard() -> void:
	var run := RunState.create("PLAY")
	run.apply({"a": "select_show"})
	var bad := run.apply({"a": "play", "cards": [99999]})
	ok(not bad["ok"], "card not in hand refused")
	ok(not run.apply({"a": "play", "cards": _hand_ids(run, 6)})["ok"], "six cards refused")
	eq(run.action_log.size(), 1, "refused actions aren't logged")
	ok(run.apply({"a": "discard", "cards": _hand_ids(run, 3)})["ok"], "discard works")
	eq(run.hand.size(), 8, "hand refilled after discard")
	eq(run.discards_left, 2, "discard used")
	eq(run.draw_pile.size(), 41, "three more drawn")
	var result := run.apply({"a": "play", "cards": [_lowest_card(run)]})
	ok(result["ok"], "play works")
	ok(result["total"] > 0, "scored")
	eq(run.hands_left, 3, "hand used")
	eq(run.hand.size(), 8, "hand refilled after play")


## The score preview matches the real score (no luck involved here) and changes nothing.
func test_score_preview() -> void:
	var run := RunState.create("PREVIEW")
	run.zanni.append(ItemCard.make("z_plus4", 3))
	eq(run.preview(_hand_ids(run, 2)), -1.0, "no preview outside a show")
	run.apply({"a": "select_show"})
	var picked := _hand_ids(run, 3)
	var before := JSON.stringify(run.to_dict())
	var guess := run.preview(picked)
	eq(JSON.stringify(run.to_dict()), before, "previewing leaves the run as it was")
	ok(guess > 0.0, "preview scores")
	eq(run.preview([99999]), -1.0, "a card not in hand can't be previewed")
	eq(float(run.apply({"a": "play", "cards": picked})["total"]), guess, "the play scores what the preview said")


## A Jester's value right now (from what it has grown or from the run) and its share of
## a previewed hand, as scoring events labelled with its place in the row.
func test_jester_values() -> void:
	ContentPacks.register_all()
	TestContent.add_test_defs()
	var run := RunState.create("NOW")
	var pantalone := ItemCard.make("z_pantalone", 5)
	pantalone.state["mult"] = 4
	run.zanni.append(ItemCard.make("z_claque", 6))
	run.zanni.append(pantalone)
	run.ducats = 9
	var claque_now := run.jester_now(0)
	eq(claque_now.size(), 1, "Claque adds one thing")
	if claque_now.size() == 1:
		eq(str(claque_now[0]["t"]), "mult", "Claque adds Mult")
		eq(float(claque_now[0]["v"]), 3.0, "9 ducats make +3 Mult")
	var pantalone_now := run.jester_now(1)
	eq(float(pantalone_now[0]["v"]) if not pantalone_now.is_empty() else 0.0, 4.0, "Pantalone has grown +4 Mult")
	eq(run.jester_now(5), [], "no Jester there")
	run.apply({"a": "select_show"})
	var detail := run.preview_detail(_hand_ids(run, 2))
	ok(detail.get("events", []).any(func(e: Dictionary) -> bool: return str(e["src"]) == "zanni:z_pantalone#1"), "the preview says which Jester added what")
	eq(run.preview_detail([99999]), {}, "nothing to preview for a card not in hand")


## A seeded run: the same seed deals the same run; it counts only for discoveries.
func test_seeded_runs() -> void:
	var a := RunState.create("SK67HXC2")
	var b := RunState.create("SK67HXC2")
	a.apply({"a": "select_show"})
	b.apply({"a": "select_show"})
	eq(ids(a.hand), ids(b.hand), "the same seed deals the same hand")
	var p := Profile.new()
	a.seen["z_zanni"] = true
	a.feats["won_run"] = true
	a.won = true
	p.record_run(a, false)
	ok(p.discovered.has("z_zanni"), "its discoveries count")
	eq(p.total_wins, 0, "its win doesn't")
	ok(not p.feats.has("won_run"), "nor its feats")


func test_losing_when_out_of_hands() -> void:
	var run := RunState.create("LOSE")
	run.apply({"a": "select_show"})
	for i in 4:
		run.apply({"a": "play", "cards": [_lowest_card(run)]})
	eq(run.phase, RunState.Phase.LOST, "single low cards can't reach 300")
	ok(not run.apply({"a": "play", "cards": [run.hand[0].id]})["ok"], "no play after losing")


## A Jester without a rescue ability used to crash the loss check.
func test_losing_with_a_jester() -> void:
	var run := RunState.create("LOSE-JESTER")
	run.zanni.append(ItemCard.make("z_plus4", 3))
	run.apply({"a": "select_show"})
	for i in 4:
		run.apply({"a": "play", "cards": [_lowest_card(run)]})
	eq(run.phase, RunState.Phase.LOST, "lost cleanly")


func test_win_payout_and_interest() -> void:
	var run := RunState.create("WIN")
	run.zanni.append(ItemCard.make("z_huge", 1))
	run.apply({"a": "select_show"})
	run.apply({"a": "play", "cards": _hand_ids(run, 5)})
	eq(run.phase, RunState.Phase.CASH_OUT, "show won")
	eq(run.payout, [{"src": "show", "v": 3}, {"src": "hands", "v": 3}], "3 for the matinee + 1 per unused hand")
	run.apply({"a": "cash_out"})
	eq(run.ducats, 10, "4 + 6")
	eq(run.phase, RunState.Phase.SHOP, "in the shop")

	var rich := RunState.create("RICH")
	rich.zanni.append(ItemCard.make("z_huge", 1))
	rich.ducats = 100
	rich.apply({"a": "select_show"})
	rich.apply({"a": "play", "cards": _hand_ids(rich, 5)})
	eq(rich.payout[2], {"src": "interest", "v": 5}, "interest capped at 5")


func test_zanni_payout_and_stats() -> void:
	var run := RunState.create("PAY")
	run.zanni.append(ItemCard.make("z_huge", 1))
	run.zanni.append(ItemCard.make("z_payer", 4))
	run.zanni.append(ItemCard.make("z_big_hand", 5))
	run.apply({"a": "select_show"})
	eq(run.hand.size(), 9, "hand size stat raised by a zanni")
	run.apply({"a": "play", "cards": _hand_ids(run, 5)})
	eq(run.payout[2], {"src": "zanni:z_payer#1", "v": 2}, "zanni payout listed")


func test_skip_gives_favor() -> void:
	var run := RunState.create("SKIP")
	ok(run.apply({"a": "skip_show"})["ok"], "skip matinee")
	eq(run.favors.size(), 0, "an immediate favor isn't kept waiting")
	eq(run.ducats, 9, "favor paid 5")
	eq(run.show_index, Shows.EVENING, "now the evening show")
	run.apply({"a": "skip_show"})
	ok(not run.apply({"a": "skip_show"})["ok"], "patron can't be skipped")


func test_targets_and_patron() -> void:
	var run := RunState.create("TARGETS")
	run.zanni.append(ItemCard.make("z_huge", 1))
	_win_show(run)
	run.apply({"a": "leave_shop"})
	run.apply({"a": "select_show"})
	eq(run.show_target, 450, "evening x1.5")
	run.apply({"a": "play", "cards": _hand_ids(run, 5)})
	run.apply({"a": "cash_out"})
	run.apply({"a": "leave_shop"})
	run.apply({"a": "select_show"})
	eq(run.show_target, 600, "patron x2")
	var hearts := run.full_deck.filter(func(c: PlayingCard) -> bool: return c.suit == PlayingCard.Suit.HEARTS)
	ok(hearts.all(func(c: PlayingCard) -> bool: return c.debuffed), "patron debuffed every heart")


func test_shop_buy_sell_reroll() -> void:
	var run := RunState.create("SHOP")
	run.zanni.append(ItemCard.make("z_huge", 1))
	run.zanni.append(ItemCard.make("z_buyer", 5))
	_win_show(run)
	run.ducats = 40
	eq(run.shop.offers.size(), 2, "two card slots")
	var offer: Dictionary = run.shop.offers[0]
	ok(offer["id"] != "z_huge", "shop never offers out-of-shop cards")
	ok(run.apply({"a": "buy", "slot": 0})["ok"], "buy works")
	eq(run.ducats, 40 - int(offer["cost"]), "paid")
	ok(not run.apply({"a": "buy", "slot": 0})["ok"], "can't buy twice")
	eq(run.zanni[1].state.get("mult", 0), 1, "owned zanni reacted to the purchase")
	ok(run.apply({"a": "reroll"})["ok"], "reroll works")
	eq(run.shop.reroll_cost, 6, "reroll cost rises")
	var before := run.ducats
	ok(run.apply({"a": "sell", "zone": "zanni", "index": 1})["ok"], "sell works")
	eq(run.ducats, before + 2, "sold for half of 5")


func test_slots_are_limited() -> void:
	var run := RunState.create("SLOTS")
	for i in 5:
		run.zanni.append(ItemCard.make("z_huge", 1))
	_win_show(run)
	run.ducats = 100
	ok(not run.apply({"a": "buy", "slot": 0})["ok"] or run.shop.offers[0]["kind"] != "zanni",
		"no zanni bought with every slot full")


func test_consumables() -> void:
	var run := RunState.create("USE")
	run.consumables.append(ItemCard.make("s_pair", 3))
	run.consumables.append(ItemCard.make("t_thirty", 3))
	ok(run.apply({"a": "use", "index": 0})["ok"], "sign used")
	eq(run.hand_levels.level(HandTable.PAIR), 2, "pair levelled")
	run.apply({"a": "select_show"})
	ok(not run.apply({"a": "use", "index": 0})["ok"], "tarocchi needs one target")
	var target := run.hand[0]
	ok(run.apply({"a": "use", "index": 0, "cards": [target.id]})["ok"], "tarocchi used on a card")
	eq(target.bonus_points, 30, "card got +30 points")
	eq(run.consumables.size(), 0, "both used up")


func test_full_tour_and_endless() -> void:
	var run := RunState.create("TOUR")
	run.zanni.append(ItemCard.make("z_huge", 1))
	for town in range(1, 9):
		for show in 3:
			_win_show(run)
			if run.won:
				break
			run.apply({"a": "leave_shop"})
	ok(run.won, "beating the town 8 patron wins the run")
	eq(run.town, 8, "still in town 8 at the win")
	eq(run.town_patron, "patron_finale", "town 8 has a finale patron")
	run.apply({"a": "leave_shop"})
	eq(run.town, 9, "endless continues to town 9")
	ok(run.target_for_show(Shows.MATINEE) > 50000, "endless targets keep growing")
