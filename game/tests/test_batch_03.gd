extends TestCase
## Card batch 3: every uncommon zanni does what cards/batch-03.md says.
## A plain pair of kings scores (10+10+10) x 2 = 60 without help.

const BATCH_3 := {
	"z_capocomico": 6, "z_maschera_nera": 7, "z_funambolo": 6, "z_lazzo": 6, "z_fracasso": 5,
	"z_rugantino": 6, "z_mangiafuoco": 6, "z_suggeritore": 6, "z_trombettiere": 6,
	"z_saltimbanco": 5, "z_carro_tespi": 5, "z_notaio": 6, "z_sipario": 5, "z_gobbo": 5,
	"z_ciarlatano": 6, "z_smeraldina": 6, "z_corallina": 6, "z_vetraio": 5,
	"z_cantastorie": 5, "z_bauta": 5,
}


func _run(zanni_ids := []) -> RunState:
	ContentPacks.register_all()
	TestContent.add_test_defs()
	var run := RunState.create("BATCH3")
	for z in zanni_ids:
		run.zanni.append(ItemCard.make(z, ContentDB.get_def(z).cost))
	return run


func _total(run: RunState, played: String, held := "") -> float:
	return Scorer.score(run, cards(played), cards(held)).total


func _win_first_show(run: RunState) -> void:
	run.apply({"a": "select_show"})
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})


## How many of 80 runs lose a Mirror card played alone.
func _mirror_losses(zanni_ids: Array) -> int:
	var lost := 0
	for i in 80:
		var run := _run(zanni_ids)
		run.seed_text = "SHATTER-%d" % i
		run.apply({"a": "select_show"})
		var card := run.hand[0]
		card.enhancement = "enh_mirror"
		run.apply({"a": "play", "cards": [card.id]})
		if not run.full_deck.has(card):
			lost += 1
	return lost


func test_batch_contents() -> void:
	ContentPacks.register_all()
	for id: String in BATCH_3:
		var d := ContentDB.get_def(id)
		ok(d != null, id + " registered")
		if d != null:
			eq(d.rarity, 1, id + " is uncommon")
			eq(d.cost, BATCH_3[id], id + " price")


func test_uncommons_appear_about_a_quarter_of_the_time() -> void:
	ContentPacks.register_all()
	var run := RunState.create("RARITY")
	run.phase = RunState.Phase.CASH_OUT
	run.apply({"a": "cash_out"})
	run.ducats = 100000
	var common := 0
	var uncommon := 0
	for i in 300:
		for o in run.shop.offers:
			if o["kind"] == "zanni":
				if ContentDB.get_def(o["id"]).rarity == 0:
					common += 1
				else:
					uncommon += 1
		run.apply({"a": "reroll"})
	var share := float(uncommon) / (common + uncommon)
	ok(share > 0.15 and share < 0.4, "uncommon share %.2f" % share)


# --- ×Mult ---

func test_capocomico_needs_full_slots() -> void:
	eq(_total(_run(["z_payer", "z_payer", "z_payer", "z_payer", "z_capocomico"]), "KH KS"), 90, "full: 60 x 1.5")
	eq(_total(_run(["z_payer", "z_capocomico"]), "KH KS"), 60, "not full: nothing")


func test_maschera_nera_costs_a_hand() -> void:
	var run := _run(["z_maschera_nera"])
	eq(_total(run, "KH KS"), 150, "60 x 2.5")
	run.apply({"a": "select_show"})
	eq(run.hands_left, 3, "3 hands instead of 4")


func test_funambolo_last_hand() -> void:
	var run := _run(["z_funambolo"])
	run.hands_left = 4
	eq(_total(run, "KH KS"), 60, "not the last hand")
	run.hands_left = 1
	eq(_total(run, "KH KS"), 120, "last hand: x2")


func test_lazzo_three_cards() -> void:
	eq(_total(_run(["z_lazzo"]), "KH KS 2C"), 120, "three cards: 60 x 2")
	eq(_total(_run(["z_lazzo"]), "KH KS"), 60, "two cards: nothing")


func test_fracasso_no_discards() -> void:
	var run := _run(["z_fracasso"])
	eq(_total(run, "KH KS"), 90, "no discards: 60 x 1.5")
	run.show_counters["discards_used"] = 1
	eq(_total(run, "KH KS"), 60, "after a discard: nothing")


func test_rugantino_streak() -> void:
	var run := _run(["z_rugantino"])
	eq(_total(run, "KH KS"), 69, "first pair: 60 x 1.15")
	eq(_total(run, "3H 3S 3C 9D 9H"), 348, "full house contains a pair: 67 x 4 x 1.3, floored")
	eq(_total(run, "AS"), 16, "high card resets")
	eq(_total(run, "KH KS"), 69, "back to x1.15")


func test_mangiafuoco_feeds_on_destroyed_cards() -> void:
	var run := _run(["z_mangiafuoco"])
	eq(_total(run, "KH KS"), 60, "nothing destroyed yet")
	run.destroy_card(run.full_deck[0])
	run.destroy_card(run.full_deck[0])
	eq(_total(run, "KH KS"), 90, "two destroyed: 60 x 1.5")


# --- encores ---

func test_suggeritore_last_card() -> void:
	eq(_total(_run(["z_suggeritore"]), "KH KS"), 80, "the second king scores twice: 40 x 2")


func test_trombettiere_aces() -> void:
	eq(_total(_run(["z_trombettiere"]), "AH AS"), 108, "each ace twice: (10+44) x 2")
	eq(_total(_run(["z_trombettiere"]), "KH KS"), 60, "no aces: nothing")


# --- slots, stats, money ---

func test_stat_zanni() -> void:
	eq(_run(["z_saltimbanco"]).stat("hand_size"), 9, "Saltimbanco: 9 cards")
	eq(_run(["z_carro_tespi"]).stat("consumable_slots"), 3, "Carro di Tespi: 3 slots")
	eq(_run(["z_notaio"]).stat("interest_cap"), 10, "Notaio: cap 10")
	eq(_run(["z_sipario"]).stat("hand_reward"), 2, "Sipario: 2 per unused hand")


func test_notaio_and_sipario_at_cash_out() -> void:
	var run := _run(["z_huge", "z_notaio", "z_sipario"])
	run.ducats = 100
	_win_first_show(run)
	ok(run.payout.has({"src": "hands", "v": 6}), "3 unused hands x 2")
	ok(run.payout.has({"src": "interest", "v": 10}), "interest up to 10")


func test_gobbo_pays_for_charmed_cards() -> void:
	var run := _run(["z_gobbo"])
	var played := cards("KH KS")
	played[0].enhancement = "enh_charmed"
	var ctx := Scorer.score(run, played, cards(""))
	var paid := ctx.events.filter(func(e: Dictionary) -> bool: return e["src"] == "zanni:z_gobbo#0")
	eq(paid.size(), 1, "one payment")
	eq(paid[0]["t"], "ducats", "in ducats")
	eq(paid[0]["v"], 2, "of 2")


func test_ciarlatano_doubles_chances() -> void:
	eq(_run(["z_ciarlatano"]).stat("luck"), 2, "luck x2")
	var plain := _mirror_losses([])
	var doubled := _mirror_losses(["z_ciarlatano"])
	ok(doubled > plain, "more shattering: %d vs %d of 80" % [doubled, plain])
	ok(doubled > 25 and doubled < 55, "about half: %d of 80" % doubled)


# --- built on batch 2 ---

func test_smeraldina_enhanced_cards() -> void:
	var run := _run(["z_smeraldina"])
	var played := cards("KH KS")
	played[0].enhancement = "enh_lacquered"
	played[1].enhancement = "enh_masked"
	eq(Scorer.score(run, played, cards("")).total, 1080, "(10+10+30+10) x (2+6+4+6)")


func test_corallina_iron_held() -> void:
	eq(_total(_run(["z_corallina"]), "QH QS", "KH:enh_iron KD:enh_iron"), 210, "60 x (1.5 x 1.25)^2, floored")


func test_vetraio_saves_mirrors() -> void:
	eq(_mirror_losses(["z_vetraio"]), 0, "no Mirror card shattered")


func test_cantastorie_counts_uses() -> void:
	var run := _run(["z_cantastorie"])
	run.consumables.append(ItemCard.make("t_diavolo", 3))
	run.consumables.append(ItemCard.make("t_morte", 3))
	run.apply({"a": "use", "index": 0})
	run.apply({"a": "use", "index": 0})
	eq(_total(run, "KH KS"), 120, "two Tarocchi used: 30 x 4")


func test_bauta_face_cards_held() -> void:
	eq(_total(_run(["z_bauta"]), "KH KS", "QH JD 2C"), 300, "two faces held: 30 x 10")
