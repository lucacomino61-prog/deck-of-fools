extends TestCase
## Card batch 7: every Jester does what cards/batch-07.md says.
## A plain pair of kings scores (10+10+10) x 2 = 60 without help.

const COMMONS := {
	"z_innamorati": 4, "z_rigattiere": 4, "z_spazzino": 3, "z_principe": 4, "z_garzone": 4,
	"z_lavandaia": 4, "z_postino": 3, "z_cuoco": 3, "z_calzolaio": 4, "z_fioraia": 4,
	"z_almanacchi": 4, "z_sbandieratore": 3, "z_sarta": 4, "z_specchiaio": 3,
}
const UNCOMMONS := {
	"z_gigante": 5, "z_mecenate": 6, "z_straniero": 6, "z_eco": 6, "z_sagrestano": 6,
	"z_usuraio": 4, "z_fattucchiere": 5, "z_becchino": 6,
}


func _run(zanni_ids := []) -> RunState:
	ContentPacks.register_all()
	TestContent.add_test_defs()
	var run := RunState.create("BATCH7")
	for z in zanni_ids:
		run.zanni.append(ItemCard.make(z, ContentDB.get_def(z).cost))
	return run


func _total(run: RunState, played: String, held := "") -> float:
	return Scorer.score(run, cards(played), cards(held)).total


func _sealed_kings(seal: String) -> Array[PlayingCard]:
	var list := cards("KH KS")
	list[0].seal = seal
	return list


func _to_shop(run: RunState) -> void:
	run.phase = RunState.Phase.CASH_OUT
	run.apply({"a": "cash_out"})


func test_batch_contents() -> void:
	ContentPacks.register_all()
	for id: String in COMMONS:
		var d := ContentDB.get_def(id)
		ok(d != null and d.rarity == 0 and d.cost == COMMONS[id], id + " is common at its price")
	for id: String in UNCOMMONS:
		var d := ContentDB.get_def(id)
		ok(d != null and d.rarity == 1 and d.cost == UNCOMMONS[id], id + " is uncommon at its price")


# --- commons ---

func test_hand_shape_commons() -> void:
	eq(_total(_run(["z_innamorati"]), "KH KS"), 360, "Innamorati, 2 cards: 30 x 12")
	eq(_total(_run(["z_innamorati"]), "KH KS 2C"), 60, "Innamorati, 3 cards: nothing")
	eq(_total(_run(["z_principe"]), "KH KS"), 360, "Principe, two kings: 60 x 6")
	eq(_total(_run(["z_garzone"]), "9H 9S"), 168, "Garzone, two nines: 28 x 6")
	eq(Scorer.score(_run(["z_calzolaio"]), _sealed_kings("seal_ducal"), cards("")).total, 210,
		"Calzolaio, one sealed card: 30 x 7")
	eq(_total(_run(["z_sbandieratore", "z_payer", "z_payer"]), "KH KS"), 140, "Sbandieratore, two to his right: 70 x 2")
	eq(_total(_run(["z_payer", "z_sbandieratore"]), "KH KS"), 60, "Sbandieratore last: nothing")


func test_hands_and_discards_left() -> void:
	var run := _run(["z_lavandaia"])
	run.discards_left = 3
	eq(_total(run, "KH KS"), 420, "Lavandaia, 3 discards left: 30 x 14")
	var post := _run(["z_postino"])
	post.hands_left = 4
	eq(_total(post, "KH KS"), 180, "Postino, 4 hands left: 90 x 2")


func test_almanacchi_counts_hand_types() -> void:
	var run := _run(["z_almanacchi"])
	eq(_total(run, "KH KS"), 90, "one hand type so far: 30 x 3")
	run.hand_levels.mark_played(HandTable.FLUSH)
	run.hand_levels.mark_played(HandTable.HIGH_CARD)
	eq(_total(run, "KH KS"), 150, "three types: 30 x 5")


func test_cuoco_counts_consumables() -> void:
	var run := _run(["z_cuoco"])
	run.consumables.append(ItemCard.make("t_diavolo", 3))
	run.consumables.append(ItemCard.make("s_gemini", 3))
	eq(_total(run, "KH KS"), 240, "two held: 30 x 8")


func test_rigattiere_free_reroll() -> void:
	var run := _run(["z_rigattiere"])
	_to_shop(run)
	run.ducats = 20
	eq(run.reroll_price(), 0, "first reroll free")
	run.apply({"a": "reroll"})
	eq(run.ducats, 20, "nothing paid")
	eq(run.reroll_price(), 5, "then the usual 5")


func test_spazzino_five_card_discard() -> void:
	var run := _run(["z_spazzino"])
	run.apply({"a": "select_show"})
	run.apply({"a": "discard", "cards": ids(run.hand.slice(0, 2))})
	eq(run.ducats, 4, "two cards: nothing")
	run.apply({"a": "discard", "cards": ids(run.hand.slice(0, 5))})
	eq(run.ducats, 7, "five cards: +3")


func test_fioraia_first_hand_win() -> void:
	var run := _run(["z_huge", "z_fioraia"])
	run.apply({"a": "select_show"})
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})
	ok(run.payout.has({"src": "zanni:z_fioraia#1", "v": 4}), "+4 for a first-hand win")


func test_sarta_lacquers_a_card() -> void:
	var run := _run(["z_sarta"])
	run.apply({"a": "select_show"})
	eq(run.full_deck.filter(func(c: PlayingCard) -> bool: return c.enhancement == "enh_lacquered").size(), 1,
		"one card became Lacquered")


func test_specchiaio_pays_for_mirrors() -> void:
	var run := _run(["z_specchiaio"])
	run.full_deck[0].enhancement = "enh_mirror"
	run.destroy_card(run.full_deck[0])
	eq(run.ducats, 8, "Mirror card destroyed: +4")
	run.destroy_card(run.full_deck[0])
	eq(run.ducats, 8, "plain card destroyed: nothing")


# --- uncommons ---

func test_gigante_and_usuraio_stats() -> void:
	var run := _run(["z_gigante"])
	eq([run.stat("hand_size"), run.stat("hands")], [10, 3], "+2 cards, 1 fewer hand")
	eq(_run(["z_usuraio"]).stat("debt_limit"), 20, "20 ducats of debt allowed")


func test_mecenate_discount() -> void:
	var run := _run(["z_mecenate"])
	_to_shop(run)
	run.ducats = 50
	var offer: Dictionary = run.shop.offers[0]
	run.apply({"a": "buy", "slot": 0})
	eq(run.ducats, 50 - maxi(1, int(offer["cost"]) - 1), "1 ducat off")


func test_usuraio_goes_into_debt() -> void:
	var run := _run(["z_usuraio"])
	_to_shop(run)
	run.ducats = 0
	ok(run.apply({"a": "buy", "slot": 0})["ok"], "bought with no ducats")
	ok(run.ducats < 0, "now in debt")


func test_straniero_first_time_only() -> void:
	var run := _run(["z_straniero"])
	eq(_total(run, "KH KS"), 120, "first pair: x2")
	eq(_total(run, "KH KS"), 60, "second pair: nothing")


func test_eco_held_effects_twice() -> void:
	eq(_total(_run(["z_eco"]), "QH QS", "KH:enh_iron"), 135, "Iron held twice: 60 x 1.5 x 1.5")


func test_sagrestano_sealed_cards_twice() -> void:
	var run := _run(["z_sagrestano"])
	eq(Scorer.score(run, _sealed_kings("seal_ducal"), cards("")).total, 80, "sealed king twice: 40 x 2")
	eq(run.ducats, 10, "Ducal seal paid twice")


func test_fattucchiere_on_skip() -> void:
	var run := _run(["z_fattucchiere"])
	pin_town(run)
	run.apply({"a": "skip_show"})
	eq(run.consumables.size(), 1, "a Tarocchi appeared")
	eq(run.consumables[0].def().kind, "tarocchi", "of the right kind")


func test_becchino_grows_on_jester_sales() -> void:
	var run := _run(["z_payer", "z_payer", "z_becchino"])
	run.consumables.append(ItemCard.make("t_diavolo", 3))
	run.apply({"a": "sell", "zone": "consumable", "index": 0})
	run.apply({"a": "sell", "zone": "zanni", "index": 0})
	run.apply({"a": "sell", "zone": "zanni", "index": 0})
	eq(_total(run, "KH KS"), 84, "two Jesters sold (the Tarocchi doesn't count): 60 x 1.4")
