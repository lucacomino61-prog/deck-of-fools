extends TestCase
## Card batch 8: every Jester does what cards/batch-08.md says, and the set is complete.
## A plain pair of kings scores (10+10+10) x 2 = 60 without help.

const COMMONS := {
	"z_orafo": 4, "z_rattoppatore": 4, "z_gonfaloniere": 4, "z_scultore": 4,
	"z_mendicante": 3, "z_merciaio": 4, "z_pescivendolo": 3,
}
const UNCOMMONS := {
	"z_smemorato": 6, "z_commedia": 6, "z_ritrattista": 5, "z_fabbro": 7, "z_gioielliere": 6,
	"z_asceta": 6, "z_tipografo": 6, "z_astronomo": 6, "z_copista": 6, "z_buttafuori": 5,
	"z_ruffiana": 6, "z_avvocato": 5, "z_nonna": 5,
}
const RARES := {"z_cometa": 8, "z_prima_donna": 8}


func _run(zanni_ids := []) -> RunState:
	ContentPacks.register_all()
	TestContent.add_test_defs()
	var run := RunState.create("BATCH8")
	for z in zanni_ids:
		run.zanni.append(ItemCard.make(z, ContentDB.get_def(z).cost))
	return run


func _total(run: RunState, played: String, held := "") -> float:
	return Scorer.score(run, cards(played), cards(held)).total


func _kings_with(field: String, value: String) -> Array[PlayingCard]:
	var list := cards("KH KS")
	list[0].set(field, value)
	return list


func test_batch_contents() -> void:
	ContentPacks.register_all()
	for table: Dictionary in [COMMONS, UNCOMMONS, RARES]:
		for id: String in table:
			var d := ContentDB.get_def(id)
			ok(d != null and d.cost == table[id], id + " registered at its price")
	for id: String in COMMONS:
		eq(ContentDB.get_def(id).rarity, 0, id + " common")
	for id: String in UNCOMMONS:
		eq(ContentDB.get_def(id).rarity, 1, id + " uncommon")
	for id: String in RARES:
		eq(ContentDB.get_def(id).rarity, 2, id + " rare")


## Batch 8 completes the set; this count is meant to stay fixed at launch.
func test_the_full_set_of_150() -> void:
	ContentPacks.register_all()
	var by_rarity := [0, 0, 0, 0]
	for d in ContentDB.pool("zanni"):
		by_rarity[d.rarity] += 1
	eq(by_rarity, [61, 62, 22, 5], "61 common, 62 uncommon, 22 rare, 5 legendary")


# --- commons ---

func test_enhancement_payoffs() -> void:
	var gilt := _run(["z_orafo"])
	Scorer.score(gilt, _kings_with("enhancement", "enh_gilt"), cards(""))
	eq(gilt.ducats, 7, "Orafo: scored Gilt card +3")
	eq(Scorer.score(_run(["z_rattoppatore"]), _kings_with("enhancement", "enh_motley"), cards("")).total, 300,
		"Rattoppatore: Motley card +8 Mult, 30 x 10")
	var marble := _run(["z_scultore"])
	marble.full_deck[0].enhancement = "enh_marble"
	marble.full_deck[1].enhancement = "enh_marble"
	eq(_total(marble, "KH KS"), 160, "Scultore: two Marble in deck, (30+50) x 2")


func test_gonfaloniere_after_patrons() -> void:
	var run := _run(["z_huge", "z_gonfaloniere"])
	run.show_index = Shows.PATRON
	run.apply({"a": "select_show"})
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})
	ok(run.payout.has({"src": "zanni:z_gonfaloniere#1", "v": 6}), "+6 after a Patron show")


func test_mendicante_when_broke() -> void:
	var run := _run(["z_mendicante"])
	eq(_total(run, "KH KS"), 60, "4 ducats: nothing")
	run.ducats = 0
	eq(_total(run, "KH KS"), 510, "broke: 30 x 17")


func test_merciaio_grows_on_rerolls() -> void:
	var run := _run(["z_merciaio"])
	run.phase = RunState.Phase.CASH_OUT
	run.apply({"a": "cash_out"})
	run.ducats = 50
	run.apply({"a": "reroll"})
	run.apply({"a": "reroll"})
	eq(_total(run, "KH KS"), 120, "two rerolls: 30 x 4")


func test_pescivendolo() -> void:
	eq(_total(_run(["z_pescivendolo"]), "6H 6S"), 176, "two sixes: 22 x 8")


# --- encores and face cards ---

func test_smemorato_low_cards() -> void:
	eq(_total(_run(["z_smemorato"]), "3H 3S"), 44, "each three twice: (10+3+3+3+3) x 2")
	eq(_total(_run(["z_smemorato"]), "9H 9S"), 56, "nines once: 28 x 2")


func test_commedia_and_ritrattista() -> void:
	eq(_total(_run(["z_commedia"]), "KH KS"), 100, "faces twice: 50 x 2")
	eq(_total(_run(["z_commedia"]), "9H 9S"), 56, "nines once: 28 x 2")
	eq(_total(_run(["z_commedia", "z_ritrattista"]), "9H 9S"), 92, "every card a face: nines twice, 46 x 2")
	var run := _run(["z_ritrattista"])
	ok(run.is_face(cards("2C")[0]), "a 2 counts as a face card")
	ok(not run.is_face(cards("2C:enh_marble")[0]), "a Marble card has no rank, so it isn't")
	eq(_total(_run(["z_ritrattista", "z_meneghino"]), "9H 9S"), 56, "Meneghino sees faces now: no bonus")


# --- card types in your deck ---

func test_fabbro_counts_iron() -> void:
	var run := _run(["z_fabbro"])
	for i in 3:
		run.full_deck[i].enhancement = "enh_iron"
	eq(_total(run, "KH KS"), 96, "three Iron cards: 60 x 1.6")


func test_gioielliere_editions() -> void:
	eq(Scorer.score(_run(["z_gioielliere"]), _kings_with("edition", "ed_silvered"), cards("")).total, 200,
		"Silvered king: (30+50) x 2 x 1.25")


func test_asceta_thin_deck() -> void:
	var run := _run(["z_asceta"])
	eq(_total(run, "KH KS"), 60, "52 cards: nothing")
	for i in 10:
		run.destroy_card(run.full_deck[0])
	eq(_total(run, "KH KS"), 90, "42 cards: 60 x 1.5")


func test_tipografo_copies_a_card() -> void:
	var run := _run(["z_tipografo"])
	run.apply({"a": "select_show"})
	eq(run.full_deck.size(), 53, "one card added")
	var copy := run.full_deck[52]
	ok(run.full_deck.slice(0, 52).any(func(c: PlayingCard) -> bool: return c.rank == copy.rank and c.suit == copy.suit),
		"it matches a card already in the deck")


# --- Signs and Tarocchi ---

func test_astronomo_counts_levels() -> void:
	var run := _run(["z_astronomo"])
	run.hand_levels.level_up(HandTable.FLUSH, 2)
	run.hand_levels.level_up(HandTable.STRAIGHT)
	eq(_total(run, "KH KS"), 240, "three extra levels: 30 x 8")


func test_copista_once_per_show() -> void:
	var run := _run(["z_copista"])
	run.apply({"a": "select_show"})
	run.consumables.append(ItemCard.make("t_diavolo", 3))
	run.apply({"a": "use", "index": 0})
	eq(run.consumables.size(), 1, "the first Tarocchi was copied")
	eq(run.consumables[0].def_id, "t_diavolo", "an exact copy")
	run.apply({"a": "use", "index": 0})
	eq(run.consumables.size(), 0, "the second one wasn't")


# --- tricks ---

func test_buttafuori_mutes_the_patron() -> void:
	var run := _run(["z_buttafuori"])
	pin_town(run)
	run.apply({"a": "skip_show"})
	run.apply({"a": "skip_show"})
	run.apply({"a": "select_show"})
	ok(run.full_deck.any(func(c: PlayingCard) -> bool: return c.debuffed), "the patron debuffed hearts")
	run.apply({"a": "sell", "zone": "zanni", "index": 0})
	ok(run.full_deck.all(func(c: PlayingCard) -> bool: return not c.debuffed), "selling him lifted the whim")
	ok(run.show_counters.get("patron_muted") == 1, "muted for this show")


func test_ruffiana_matches_suits() -> void:
	var run := _run(["z_ruffiana"])
	var played := cards("KH KS 2C")
	Scorer.score(run, played, cards(""))
	eq([played[0].suit, played[1].suit], [PlayingCard.Suit.HEARTS, PlayingCard.Suit.HEARTS], "the pair took hearts")
	eq(played[2].suit, PlayingCard.Suit.CLUBS, "the unpaired card kept its suit")


func test_avvocato_free_single_discard() -> void:
	var run := _run(["z_avvocato"])
	run.apply({"a": "select_show"})
	run.apply({"a": "discard", "cards": [run.hand[0].id]})
	eq(run.discards_left, 3, "the first single discard was free")
	run.apply({"a": "discard", "cards": [run.hand[0].id]})
	eq(run.discards_left, 2, "the second one wasn't")


func test_nonna_grows_at_cash_out() -> void:
	var run := _run(["z_huge", "z_nonna"])
	run.apply({"a": "select_show"})
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})
	run.apply({"a": "cash_out"})
	run.zanni.remove_at(0)
	eq(_total(run, "KH KS"), 120, "one cash-out: 30 x 4")


# --- rares ---

func test_cometa_levels_the_runner_up() -> void:
	var run := _run(["z_cometa"])
	for i in 3:
		run.hand_levels.mark_played(HandTable.PAIR)
	run.hand_levels.mark_played(HandTable.FLUSH)
	run.consumables.append(ItemCard.make("s_aries", 3))
	run.apply({"a": "use", "index": 0})
	eq(run.hand_levels.level(HandTable.FLUSH), 2, "the second most played hand gained a level")
	eq(run.hand_levels.level(HandTable.HIGH_CARD), 2, "and the Sign still did its own job")


func test_prima_donna() -> void:
	eq(_total(_run(["z_prima_donna"]), "KH KS"), 240, "alone: x4")
	eq(_total(_run(["z_prima_donna", "z_payer"]), "KH KS"), 120, "with company: x2")
