extends TestCase
## Card batch 5: every rare and legendary Jester does what cards/batch-05.md says.
## A plain pair of kings scores (10+10+10) x 2 = 60 without help.

const RARES := {
	"z_burattinaio": 10, "z_mattacino": 10, "z_re_dei_folli": 9, "z_compagnia": 9,
	"z_capriccio": 8, "z_maschera_oro": 8, "z_orologio": 8, "z_notturno": 7, "z_gemelli": 8,
	"z_gioco_parti": 8, "z_pittore": 8, "z_gran_ballo": 9, "z_teatro_olimpico": 8,
	"z_nebbia": 7, "z_fenice": 6, "z_banditore": 8, "z_maestro_cappella": 7,
	"z_carnevale": 7, "z_prestigiatore": 9, "z_doge": 8,
}
const LEGENDS := ["z_martinelli", "z_andreini", "z_goldoni", "z_gozzi", "z_scala"]


func _run(zanni_ids := []) -> RunState:
	ContentPacks.register_all()
	TestContent.add_test_defs()
	var run := RunState.create("BATCH5")
	for z in zanni_ids:
		run.zanni.append(ItemCard.make(z, ContentDB.get_def(z).cost))
	return run


func _total(run: RunState, played: String, held := "") -> float:
	return Scorer.score(run, cards(played), cards(held)).total


func _win_show(run: RunState) -> void:
	if run.phase == RunState.Phase.CHOOSE_SHOW:
		run.apply({"a": "select_show"})
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})


func test_batch_contents() -> void:
	ContentPacks.register_all()
	for id: String in RARES:
		var d := ContentDB.get_def(id)
		ok(d != null and d.rarity == 2 and d.cost == RARES[id], id + " is rare at its price")
	for id: String in LEGENDS:
		var d := ContentDB.get_def(id)
		ok(d != null and d.rarity == 3 and d.cost == 20, id + " is legendary at 20")
	var run := RunState.create("NO-LEGENDS")
	ok(run._shop_pool("zanni").all(func(d: ContentDef) -> bool: return d.rarity < 3), "no legendary in the shop")


# --- copying ---

func test_burattinaio_copies_right() -> void:
	var ctx := Scorer.score(_run(["z_burattinaio", "z_zanni"]), cards("KH KS"), cards(""))
	eq(ctx.total, 300, "copies +4: 30 x 10")
	ok(ctx.events.any(func(e: Dictionary) -> bool: return e["src"] == "zanni:z_burattinaio#0"),
		"the copy is labelled as the Burattinaio")
	eq(_total(_run(["z_zanni", "z_burattinaio"]), "KH KS"), 180, "nobody to his right")


func test_mattacino_copies_leftmost() -> void:
	eq(_total(_run(["z_zanni", "z_mattacino"]), "KH KS"), 300, "copies the leftmost +4")
	eq(_total(_run(["z_mattacino"]), "KH KS"), 60, "alone, nothing to copy")


func test_copy_chains_and_loops() -> void:
	eq(_total(_run(["z_burattinaio", "z_burattinaio", "z_zanni"]), "KH KS"), 420, "two copies down a chain: 30 x 14")
	eq(_total(_run(["z_burattinaio", "z_mattacino"]), "KH KS"), 60, "copiers copying each other: nothing, no hang")


func test_copies_effects_not_growth() -> void:
	var run := _run(["z_burattinaio", "z_pantalone"])
	run.phase = RunState.Phase.CASH_OUT
	run.apply({"a": "cash_out"})
	run.ducats = 100
	run.apply({"a": "buy", "slot": 0})
	eq(run.zanni[1].state.get("mult"), 1, "Pantalone grew once")
	ok(run.zanni[0].state.is_empty(), "the copier didn't grow")
	run.zanni.resize(2)
	eq(_total(run, "KH KS"), 120, "both add Pantalone's +1: 30 x 4")


func test_copies_cash_out_money() -> void:
	var run := _run(["z_burattinaio", "z_payer", "z_huge"])
	_win_show(run)
	ok(run.payout.has({"src": "zanni:z_burattinaio#0", "v": 2}), "copied payout")
	ok(run.payout.has({"src": "zanni:z_payer#1", "v": 2}), "original payout")


# --- the troupe and big Mult ---

func test_re_dei_folli() -> void:
	eq(_total(_run(["z_re_dei_folli", "z_payer", "z_payer"]), "KH KS"), 86, "two others: 60 x 1.44, floored")


func test_compagnia_slots() -> void:
	eq(_run(["z_compagnia"]).stat("zanni_slots"), 7, "5 + 2")


func test_capriccio() -> void:
	var run := _run(["z_capriccio"])
	run.apply({"a": "select_show"})
	var named := str(run.zanni[0].state.get("hand", ""))
	ok(HandTable.ORDER.has(named) and not HandTable.SECRET.has(named), "names a visible hand")
	run.zanni[0].state["hand"] = HandTable.PAIR
	eq(_total(run, "KH KS"), 180, "named hand: x3")
	run.zanni[0].state["hand"] = HandTable.FLUSH
	eq(_total(run, "KH KS"), 60, "other hands: nothing")


func test_maschera_oro() -> void:
	var run := _run(["z_maschera_oro"])
	eq(_total(run, "KH KS"), 60, "4 ducats: nothing")
	run.ducats = 25
	eq(_total(run, "KH KS"), 90, "25 ducats: x1.5")


func test_orologio_counts_patrons() -> void:
	var run := _run(["z_orologio", "z_huge"])
	for show in Shows.PATRON + 1:
		_win_show(run)
		run.apply({"a": "cash_out"})
		run.apply({"a": "leave_shop"})
	eq(run.zanni[0].state.get("ticks"), 1, "one patron beaten")
	run.zanni.resize(1)
	eq(_total(run, "KH KS"), 75, "60 x 1.25")


func test_notturno_patron_shows() -> void:
	var run := _run(["z_notturno"])
	eq(_total(run, "KH KS"), 60, "matinee: nothing")
	run.show_index = Shows.PATRON
	eq(_total(run, "KH KS"), 120, "patron show: x2")


func test_gemelli_twins() -> void:
	eq(_total(_run(["z_gemelli"]), "KH KH"), 180, "two king of hearts: x3")
	eq(_total(_run(["z_gemelli"]), "KH KS"), 60, "different suits: nothing")


func test_gioco_delle_parti_swaps() -> void:
	var ctx := Scorer.score(_run(["z_gioco_parti", "z_zanni"]), cards("KH KS"), cards(""))
	eq(ctx.total, 68, "30 x 2 swapped to 2 x 30, then +4 Mult: 2 x 34")
	ok(ctx.events.any(func(e: Dictionary) -> bool: return e["t"] == "swap"), "the swap is logged")


# --- rules that bend ---

func test_pittore_four_card_hands() -> void:
	eq(_total(_run(["z_pittore"]), "2H 7H 9H JH KS"), 252, "4-card flush: 63 x 4")
	eq(_total(_run(["z_pittore"]), "5H 6S 7C 8D KH"), 224, "4-card straight: 56 x 4")


func test_gran_ballo() -> void:
	eq(_total(_run(["z_gran_ballo"]), "2H 7H 9H JH KH"), 444, "flush, every card twice: 111 x 4")
	eq(_total(_run(["z_gran_ballo"]), "KH KS"), 60, "pair: nothing")


func test_teatro_olimpico() -> void:
	var run := _run(["z_teatro_olimpico"])
	eq([run.stat("hands"), run.stat("discards")], [5, 4], "+1 hand, +1 discard")


func test_nebbia_mutes_patrons() -> void:
	var run := _run(["z_nebbia"])
	pin_town(run)
	for i in Shows.PATRON:
		run.apply({"a": "skip_show"})
	run.apply({"a": "select_show"})
	eq(run.show_target, 1000, "patron target x2.5")
	var hearts := run.full_deck.filter(func(c: PlayingCard) -> bool: return c.suit == PlayingCard.Suit.HEARTS)
	ok(hearts.all(func(c: PlayingCard) -> bool: return not c.debuffed), "the patron's whim didn't fire")


func test_fenice_rescues_once() -> void:
	var run := _run(["z_fenice"])
	run.apply({"a": "select_show"})
	run.show_score = 100
	run.hands_left = 1
	run.apply({"a": "play", "cards": [run.hand[0].id]})
	eq(run.phase, RunState.Phase.CASH_OUT, "passed instead of lost")
	eq(run.zanni.size(), 0, "La Fenice burned")
	ok(not run.payout.any(func(p: Dictionary) -> bool: return p["src"] == "show"), "no show reward")

	var short := _run(["z_fenice"])
	short.apply({"a": "select_show"})
	short.show_score = 10
	short.hands_left = 1
	short.apply({"a": "play", "cards": [short.hand[0].id]})
	eq(short.phase, RunState.Phase.LOST, "under a quarter: lost")


# --- growth, Signs and money ---

func test_banditore_double_levels() -> void:
	var run := _run(["z_banditore"])
	run.consumables.append(ItemCard.make("s_gemini", 3))
	run.apply({"a": "use", "index": 0})
	eq(run.hand_levels.level(HandTable.PAIR), 3, "two levels from one Sign")


func test_maestro_di_cappella() -> void:
	var run := _run(["z_maestro_cappella"])
	eq(_total(run, "KH KS"), 150, "level 1: 30 x 5")
	run.hand_levels.level_up(HandTable.PAIR, 2)
	eq(_total(run, "KH KS"), 780, "level 3: 60 x (4+9)")


func test_carnevale_masks_faces() -> void:
	var run := _run(["z_carnevale"])
	var played := cards("KH KS 2C")
	played[1].enhancement = "enh_lacquered"
	eq(Scorer.score(run, played, cards("")).total, 120, "this hand scores as usual: (30+30) x 2")
	eq(played[0].enhancement, "enh_masked", "plain king became Masked")
	eq(played[1].enhancement, "enh_lacquered", "enhanced king kept its enhancement")


func test_prestigiatore_shines_a_card() -> void:
	var run := _run(["z_prestigiatore"])
	run.apply({"a": "select_show"})
	var shining := run.full_deck.filter(func(c: PlayingCard) -> bool: return c.edition != "")
	eq(shining.size(), 1, "one card gained an edition")
	ok(shining[0].edition in ["ed_silvered", "ed_opaline", "ed_prismatic"], "never Shadow")


func test_doge_double_interest() -> void:
	var run := _run(["z_doge", "z_huge"])
	run.ducats = 100
	_win_show(run)
	ok(run.payout.has({"src": "interest", "v": 10}), "5 interest doubled")


# --- legendaries ---

func test_martinelli() -> void:
	eq(_total(_run(["z_payer", "z_payer", "z_martinelli"]), "KH KS"), 135, "two to his left: 60 x 2.25")


func test_andreini() -> void:
	eq(_total(_run(["z_andreini"]), "QH QS"), 375, "two queens: 60 x 2.5 x 2.5")


func test_goldoni() -> void:
	eq(_total(_run(["z_goldoni"]), "KH KS"), 100, "every card twice: 50 x 2")


func test_gozzi_grows_on_signs() -> void:
	var run := _run(["z_gozzi"])
	for i in 2:
		run.consumables.append(ItemCard.make("s_aries", 3))
		run.apply({"a": "use", "index": 0})
	eq(_total(run, "KH KS"), 120, "two Signs: 60 x 2")


func test_scala_levels_the_most_played_hand() -> void:
	var run := _run(["z_scala", "z_huge"])
	_win_show(run)
	eq(run.hand_levels.level(run.counters["last_hand"]), 2, "the hand just played gained a level")
