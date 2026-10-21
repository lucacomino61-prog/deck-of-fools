extends TestCase
## Card batch 6: every Jester does what cards/batch-06.md says.
## A plain pair of kings scores (10+10+10) x 2 = 60 without help.

const BATCH_6 := {
	"z_lampionaio": 2, "z_pagliaccio": 4, "z_fritellino": 4, "z_trivellino": 4, "z_silvia": 3,
	"z_graziano": 3, "z_cassandro": 4, "z_rosaura": 4, "z_florindo": 4, "z_mirandolina": 4,
	"z_bigliettaio": 3, "z_peppe_nappa": 3, "z_macchinista": 4, "z_trovarobe": 3,
	"z_comparsa": 3, "z_mimo": 3, "z_tamburino": 3, "z_ballerina": 4, "z_burattino": 3,
	"z_menestrello": 3,
}


func _run(zanni_ids := []) -> RunState:
	ContentPacks.register_all()
	TestContent.add_test_defs()
	var run := RunState.create("BATCH6")
	for z in zanni_ids:
		run.zanni.append(ItemCard.make(z, ContentDB.get_def(z).cost))
	return run


func _total(run: RunState, played: String, held := "") -> float:
	return Scorer.score(run, cards(played), cards(held)).total


func _win_show(run: RunState) -> void:
	run.apply({"a": "select_show"})
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})


func test_batch_contents() -> void:
	ContentPacks.register_all()
	for id: String in BATCH_6:
		var d := ContentDB.get_def(id)
		ok(d != null and d.rarity == 0 and d.cost == BATCH_6[id], id + " is common at its price")
	var tab := ContentDB.get_def("z_tabarrino")
	ok(tab != null and tab.rarity == 1 and tab.cost == 5, "Tabarrino is uncommon at 5")


func test_simple_jesters() -> void:
	eq(_total(_run(["z_lampionaio"]), "KH KS"), 100, "Lampionaio: (30+20) x 2")
	eq(_total(_run(["z_pagliaccio"]), "KH KS 2C"), 330, "Pagliaccio, 3 played: 30 x 11")
	eq(_total(_run(["z_cassandro"]), "KH KS", "2C 3C 4D"), 240, "Cassandro, 3 held: 30 x 8")
	eq(_total(_run(["z_mimo"]), "AS"), 66, "Mimo high card: (16+50) x 1")
	eq(_total(_run(["z_mimo"]), "KH KS"), 60, "Mimo pair: nothing")
	eq(_total(_run(["z_burattino", "z_payer"]), "KH KS"), 100, "Burattino, 2 Jesters: (30+20) x 2")


func test_suit_jesters() -> void:
	eq(_total(_run(["z_fritellino"]), "KC KS"), 180, "Fritellino one club: 30 x 6")
	eq(_total(_run(["z_trivellino"]), "KD KS"), 110, "Trivellino one diamond: 55 x 2")
	eq(_total(_run(["z_silvia"]), "KC KS", "2H 3H 4S"), 180, "Silvia two hearts held: 30 x 6")
	eq(_total(_run(["z_graziano"]), "KS KC"), 126, "Graziano one spade: 42 x 3")


func test_big_hands() -> void:
	eq(_total(_run(["z_rosaura"]), "3H 3S 3C 9D 9H"), 1404, "Rosaura full house: 117 x 12")
	eq(_total(_run(["z_florindo"]), "8H 8S 8C 8D 2H"), 2584, "Florindo four of a kind: 152 x 17")


func test_comparsa_empty_slots() -> void:
	eq(_total(_run(["z_comparsa"]), "KH KS"), 540, "4 empty slots: 30 x 18")
	eq(_total(_run(["z_comparsa", "z_payer", "z_payer", "z_payer", "z_payer"]), "KH KS"), 60, "full: nothing")


func test_peppe_nappa_last_hand() -> void:
	var run := _run(["z_peppe_nappa"])
	run.hands_left = 4
	eq(_total(run, "KH KS"), 60, "not the last hand")
	run.hands_left = 1
	eq(_total(run, "KH KS"), 360, "last hand: 30 x 12")


func test_tamburino_draw_pile() -> void:
	var run := _run(["z_tamburino"])
	run.apply({"a": "select_show"})
	eq(run.draw_pile.size(), 44, "44 cards left to draw")
	eq(_total(run, "KH KS"), 300, "8 beats: 30 x 10")


func test_ballerina_one_colour() -> void:
	eq(_total(_run(["z_ballerina"]), "KH KD"), 300, "both red: 30 x 10")
	eq(_total(_run(["z_ballerina"]), "KH KS"), 60, "mixed colours: nothing")
	eq(_total(_run(["z_ballerina"]), "KH KS:enh_motley"), 300, "Motley fits red")


func test_money_jesters() -> void:
	var run := _run(["z_huge", "z_mirandolina"])
	_win_show(run)
	ok(run.payout.has({"src": "zanni:z_mirandolina#1", "v": 3}), "Mirandolina: +3 at cash-out")

	var tickets := _run(["z_huge", "z_bigliettaio"])
	_win_show(tickets)
	tickets.apply({"a": "cash_out"})
	eq(tickets.zanni[1].sell_value(), 3, "Bigliettaio sells for 1 + 2")

	var props := _run(["z_trovarobe"])
	props.consumables.append(ItemCard.make("t_diavolo", 3))
	props.consumables.append(ItemCard.make("s_gemini", 3))
	props.apply({"a": "select_show"})
	eq(props.ducats, 6, "Trovarobe: +1 per consumable held")

	var minstrel := _run(["z_menestrello"])
	minstrel.consumables.append(ItemCard.make("s_aries", 3))
	minstrel.apply({"a": "use", "index": 0})
	eq(minstrel.ducats, 6, "Menestrello: +2 for a Sign")


func test_macchinista_discard() -> void:
	eq(_run(["z_macchinista"]).stat("discards"), 4, "+1 discard")


func test_tabarrino_grows_on_clubs() -> void:
	var run := _run(["z_tabarrino"])
	eq(_total(run, "KC KS"), 90, "first club: 30 x 3")
	eq(_total(run, "KC KS"), 120, "second club: 30 x 4")


func test_tabarrino_copied_grows_once() -> void:
	var run := _run(["z_burattinaio", "z_tabarrino"])
	eq(_total(run, "KC KS"), 120, "both add Tabarrino's +1: 30 x 4")
	eq(run.zanni[1].state.get("mult"), 1, "grew once, not twice")
