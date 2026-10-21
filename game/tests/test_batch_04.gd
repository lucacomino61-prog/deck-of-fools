extends TestCase
## Card batch 4: every Jester does what cards/batch-04.md says.
## A plain pair of kings scores (10+10+10) x 2 = 60 without help.

const BATCH_4 := {
	"z_claque": 6, "z_loggione": 6, "z_prima": 7, "z_copione": 5, "z_canovaccio": 5,
	"z_teatrino": 6, "z_impresario": 5, "z_scaramuccia": 6, "z_beltrame": 5, "z_lucinda": 5,
	"z_mercante": 5, "z_moretta": 6, "z_pappagallo": 6, "z_cerusico": 5, "z_lelio": 6,
	"z_ottavio": 6, "z_volto": 5, "z_giangurgolo": 5, "z_pasquariello": 5, "z_chiromante": 5,
}


func _run(zanni_ids := []) -> RunState:
	ContentPacks.register_all()
	TestContent.add_test_defs()
	var run := RunState.create("BATCH4")
	for z in zanni_ids:
		run.zanni.append(ItemCard.make(z, ContentDB.get_def(z).cost))
	return run


func _total(run: RunState, played: String, held := "") -> float:
	return Scorer.score(run, cards(played), cards(held)).total


func test_batch_contents() -> void:
	ContentPacks.register_all()
	for id: String in BATCH_4:
		var d := ContentDB.get_def(id)
		ok(d != null, id + " registered")
		if d != null:
			eq(d.rarity, 1, id + " is uncommon")
			eq(d.cost, BATCH_4[id], id + " price")


# --- the stage and the audience ---

func test_claque_counts_ducats() -> void:
	var run := _run(["z_claque"])
	eq(_total(run, "KH KS"), 90, "4 ducats: +1 Mult, 30 x 3")
	run.ducats = 100
	eq(_total(run, "KH KS"), 510, "capped at +15: 30 x 17")


func test_loggione_most_played() -> void:
	var run := _run(["z_loggione"])
	eq(_total(run, "KH KS"), 90, "first pair is the most played: 60 x 1.5")
	for i in 3:
		run.hand_levels.mark_played(HandTable.FLUSH)
	eq(_total(run, "KH KS"), 60, "flush played more: nothing")


func test_prima_first_hand() -> void:
	var run := _run(["z_prima"])
	eq(_total(run, "KH KS"), 100, "first hand, each king twice: 50 x 2")
	run.show_counters["hands_played"] = 1
	eq(_total(run, "KH KS"), 60, "later hands: nothing")


func test_copione_same_hand() -> void:
	var run := _run(["z_copione"])
	eq(_total(run, "KH KS"), 60, "no previous hand")
	run.counters["last_hand"] = HandTable.PAIR
	eq(_total(run, "KH KS"), 360, "pair after pair: 30 x 12")
	run.counters["last_hand"] = HandTable.FLUSH
	eq(_total(run, "KH KS"), 60, "pair after flush: nothing")


func test_copione_in_a_real_show() -> void:
	var run := _run(["z_copione"])
	run.apply({"a": "select_show"})
	var first: Dictionary = run.apply({"a": "play", "cards": [run.hand[0].id]})
	var second: Dictionary = run.apply({"a": "play", "cards": [run.hand[0].id]})
	eq(first["total"] * 1.0, (first["points"] as float) * 1.0, "first high card: x1, no bonus")
	ok(second["mult"] >= 11, "second high card in a row: +10 Mult")


func test_canovaccio_counts_suits() -> void:
	eq(_total(_run(["z_canovaccio"]), "KH KS"), 240, "two suits: 30 x 8")
	eq(_total(_run(["z_canovaccio"]), "2H 7H 9H JH KH"), 511, "one suit: 73 x 7")
	eq(_total(_run(["z_canovaccio"]), "KH KS:enh_motley"), 420, "Motley counts as all four: 30 x 14")


func test_teatrino_extra_shop_slot() -> void:
	var run := _run(["z_teatrino"])
	eq(run.stat("shop_slots"), 3, "3 slots")
	run.phase = RunState.Phase.CASH_OUT
	run.apply({"a": "cash_out"})
	eq(run.shop.offers.size(), 3, "three offers")


func test_impresario_pays_per_jester() -> void:
	var run := _run(["z_huge", "z_impresario"])
	run.apply({"a": "select_show"})
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})
	ok(run.payout.has({"src": "zanni:z_impresario#1", "v": 2}), "two Jesters: +2")


# --- suits and ranks ---

func test_suit_and_rank_jesters() -> void:
	eq(_total(_run(["z_scaramuccia"]), "JH JS"), 86, "two jacks: 60 x 1.2 x 1.2, floored")
	eq(_total(_run(["z_beltrame"]), "KH KD", "2S 3S 4C"), 240, "two spades held: 30 x 8")
	eq(_total(_run(["z_lucinda"]), "KH KS"), 250, "one heart: 50 x 5")
	eq(_total(_run(["z_moretta"]), "AS"), 48, "one card: 16 x 3")
	eq(_total(_run(["z_moretta"]), "KH KS"), 60, "two cards: nothing")


func test_mercante_with_certain_luck() -> void:
	var run := _run(["z_lucky", "z_mercante"])
	_total(run, "KD KS")
	eq(run.ducats, 7, "one diamond: +3 ducats")


func test_pappagallo_exact_pair() -> void:
	eq(_total(_run(["z_pappagallo"]), "KH KS"), 100, "pair, each king twice: 50 x 2")
	eq(_total(_run(["z_pappagallo"]), "KH KS 2C 2D"), 88, "two pair: nothing")
	eq(_total(_run(["z_pappagallo"]), "KH KS 2C"), 100, "the unpaired 2 doesn't score anyway")


# --- shaping the deck ---

func test_cerusico_destroys_discarded_faces() -> void:
	var run := _run(["z_cerusico"])
	run.apply({"a": "select_show"})
	var face := run.hand[0]
	var plain := run.hand[1]
	face.rank = PlayingCard.KING
	plain.rank = 5
	run.apply({"a": "discard", "cards": [face.id, plain.id]})
	eq(run.full_deck.size(), 51, "the king is gone")
	ok(not run.full_deck.has(face), "the face card was destroyed")
	ok(run.discard_pile.has(plain), "the 5 was only discarded")
	eq(run.ducats, 6, "+2 ducats")


func test_lelio_mirror_cards() -> void:
	var played := cards("KH KS")
	played[0].enhancement = "enh_mirror"
	eq(Scorer.score(_run(["z_lelio"]), played, cards("")).total, 180, "30 x 2 x 2 x 1.5")


func test_ottavio_counts_enhanced_deck_cards() -> void:
	var run := _run(["z_ottavio"])
	for i in 3:
		run.full_deck[i].enhancement = "enh_lacquered"
	eq(_total(run, "KH KS"), 240, "three enhanced: 30 x 8")


func test_volto_plain_cards() -> void:
	eq(_total(_run(["z_volto"]), "KH KS"), 240, "two plain cards: 30 x 8")
	var played := cards("KH KS")
	played[0].enhancement = "enh_lacquered"
	eq(Scorer.score(_run(["z_volto"]), played, cards("")).total, 300, "one plain: 60 x 5")


# --- growth ---

func test_giangurgolo_grows_on_sales() -> void:
	var run := _run(["z_payer", "z_payer", "z_giangurgolo"])
	run.apply({"a": "sell", "zone": "zanni", "index": 0})
	run.apply({"a": "sell", "zone": "zanni", "index": 0})
	eq(run.zanni[0].state.get("mult"), 4, "two sales: +4")
	eq(_total(run, "KH KS"), 180, "30 x 6")


func test_pasquariello_grows_on_skips() -> void:
	var run := _run(["z_pasquariello"])
	pin_town(run)
	run.apply({"a": "skip_show"})
	run.apply({"a": "skip_show"})
	eq(_total(run, "KH KS"), 300, "two skips: 30 x 10")


func test_chiromante_creates_signs() -> void:
	var run := _run(["z_lucky", "z_chiromante"])
	run.consumables.append(ItemCard.make("t_diavolo", 3))
	run.apply({"a": "use", "index": 0})
	eq(run.consumables.size(), 1, "a Sign appeared")
	eq(run.consumables[0].def().kind, "sign", "of the right kind")
	run.consumables.append(ItemCard.make("s_gemini", 3))
	run.apply({"a": "use", "index": 1})
	eq(run.consumables.size(), 1, "using a Sign doesn't trigger it")
	run.consumables.append(ItemCard.make("t_morte", 3))
	run.consumables.append(ItemCard.make("t_diavolo", 3))
	run.apply({"a": "use", "index": 2})
	eq(run.consumables.size(), 2, "no room, no Sign")
