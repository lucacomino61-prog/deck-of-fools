extends TestCase
## Card batch 1: every Sign and every zanni does what cards/batch-01.md says.

const ZANNI_BATCH_1 := [
	"z_zanni", "z_arlecchino", "z_capitano", "z_pedrolino", "z_scapino",
	"z_isabella", "z_flavio", "z_gianduja", "z_coviello", "z_stenterello",
	"z_dottore", "z_tartaglia", "z_colombina", "z_pulcinella", "z_sandrone",
	"z_meneghino", "z_brighella", "z_pantalone", "z_truffaldino", "z_mezzetino",
]


func _real() -> void:
	ContentPacks.register_all()
	TestContent.add_test_defs()


func _run(zanni_ids: Array) -> RunState:
	_real()
	var run := RunState.create("BATCH1")
	for z in zanni_ids:
		run.zanni.append(ItemCard.make(z, ContentDB.get_def(z).cost))
	return run


func _total(run: RunState, played: String, held := "") -> float:
	return Scorer.score(run, cards(played), cards(held)).total


# --- content and text ---

func test_batch_contents() -> void:
	ContentPacks.register_all()
	var signs := ContentDB.pool("sign")
	var zanni := ContentDB.pool("zanni").filter(func(d: ContentDef) -> bool: return d.id in ZANNI_BATCH_1)
	eq(signs.size(), 12, "12 signs")
	eq(zanni.size(), 20, "20 zanni")
	ok(zanni.all(func(d: ContentDef) -> bool: return d.rarity == 0), "all common")
	ok(signs.all(func(d: ContentDef) -> bool: return d.cost == 3), "signs cost 3")
	for hand in HandTable.ORDER:
		eq(signs.filter(func(d: ContentDef) -> bool: return d.data["hand"] == hand).size(), 1, "one sign for " + hand)
	var costs := {}
	for d in zanni:
		costs[d.id] = d.cost
	eq(costs, {
		"z_zanni": 2, "z_arlecchino": 4, "z_capitano": 4, "z_pedrolino": 4, "z_scapino": 4,
		"z_isabella": 3, "z_flavio": 4, "z_gianduja": 4, "z_coviello": 4, "z_stenterello": 4,
		"z_dottore": 4, "z_tartaglia": 4, "z_colombina": 5, "z_pulcinella": 5, "z_sandrone": 3,
		"z_meneghino": 3, "z_brighella": 5, "z_pantalone": 5, "z_truffaldino": 4, "z_mezzetino": 4,
	}, "prices match the batch")


func test_every_card_has_text() -> void:
	ContentPacks.register_all()
	var keys := {}
	var f := FileAccess.open("res://i18n/cards.csv", FileAccess.READ)
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() >= 2 and line[1] != "":
			keys[line[0]] = true
	for kind in ["sign", "zanni"]:
		for d in ContentDB.pool(kind):
			ok(keys.has(d.id + ".name"), d.id + " has a name")
			ok(keys.has(d.id + ".text"), d.id + " has text")


# --- signs ---

func test_signs_level_their_hand() -> void:
	_real()
	var run := RunState.create("SIGNS")
	for row in SignCards.SIGNS:
		run.consumables.append(ItemCard.make(row[0], 3))
		run.apply({"a": "use", "index": 0})
		eq(run.hand_levels.level(row[1]), 2, row[0] + " levels " + row[1])
	eq(_total(run, "KH KS"), 135, "Gemini: pair at level 2 is (25+20) x 3")


func test_secret_signs_wait_until_played() -> void:
	ContentPacks.register_all()
	var run := RunState.create("SECRET")
	var ids_now := run._shop_pool("sign").map(func(d: ContentDef) -> String: return d.id)
	ok(not ids_now.has("s_virgo"), "Virgo hidden before Five of a Kind")
	ok(not ids_now.has("s_libra"), "Libra hidden before Flush Five")
	ok(ids_now.has("s_gemini"), "ordinary signs offered")
	run.hand_levels.mark_played(HandTable.FIVE_KIND)
	ok(run._shop_pool("sign").any(func(d: ContentDef) -> bool: return d.id == "s_virgo"), "Virgo after Five of a Kind")


# --- plain and positional ---

func test_zanni_plain() -> void:
	eq(_total(_run(["z_zanni"]), "KH KS"), 180, "+4 Mult: 30 x 6")


func test_arlecchino_counts_zanni_to_his_left() -> void:
	eq(_total(_run(["z_arlecchino"]), "KH KS"), 60, "nobody to his left")
	eq(_total(_run(["z_zanni", "z_zanni", "z_arlecchino"]), "KH KS"), 420, "two to his left: 30 x (2+4+4+4)")


func test_capitano_first_hand_only() -> void:
	var run := _run(["z_capitano"])
	eq(_total(run, "KH KS"), 420, "first hand: 30 x 14")
	run.show_counters["hands_played"] = 1
	eq(_total(run, "KH KS"), 60, "later hands: nothing")


func test_pedrolino_grows_through_the_show() -> void:
	var run := _run(["z_pedrolino"])
	eq(_total(run, "KH KS"), 60, "first hand: +0")
	run.show_counters["hands_played"] = 3
	eq(_total(run, "KH KS"), 330, "after 3 hands: 30 x 11")


func test_scapino_counts_discards() -> void:
	var run := _run(["z_scapino"])
	run.show_counters["discards_used"] = 3
	eq(_total(run, "KH KS"), 420, "3 discards: 30 x 14")


func test_scapino_and_pedrolino_in_a_real_show() -> void:
	var run := _run(["z_scapino"])
	run.apply({"a": "select_show"})
	run.apply({"a": "discard", "cards": ids(run.hand.slice(0, 1))})
	var result := run.apply({"a": "play", "cards": ids(run.hand.slice(0, 1))})
	var src := (result["events"] as Array).filter(func(e: Dictionary) -> bool: return e["src"] == "zanni:z_scapino#0")
	eq(src.size(), 1, "Scapino fired once")
	eq(src[0]["v"], 4, "one discard used: +4")


# --- hand shapes ---

func test_hand_shape_zanni() -> void:
	eq(_total(_run(["z_isabella"]), "KH KS"), 315, "Isabella pair: 45 x 7")
	eq(_total(_run(["z_isabella"]), "3H 3S 3C 9D 9H"), 738, "Isabella on a full house: 82 x 9")
	eq(_total(_run(["z_isabella"]), "AS"), 16, "Isabella no pair: nothing")
	eq(_total(_run(["z_flavio"]), "KH KS 2C 2D 9H"), 512, "Flavio two pair: 64 x 8")
	eq(_total(_run(["z_gianduja"]), "7H 7S 7C"), 819, "Gianduja three of a kind: 91 x 9")
	eq(_total(_run(["z_coviello"]), "5H 6S 7C 8D 9H"), 1000, "Coviello straight: 125 x 8")
	eq(_total(_run(["z_stenterello"]), "2H 7H 9H JH KH"), 1017, "Stenterello flush: 113 x 9")


func test_dottore_needs_five_cards() -> void:
	eq(_total(_run(["z_dottore"]), "2H 9C KD 4S 7H"), 60, "five cards: (15+45) x 1")
	eq(_total(_run(["z_dottore"]), "2H 9C KD 4S"), 15, "four cards: nothing")


# --- cards that score ---

func test_card_trigger_zanni() -> void:
	eq(_total(_run(["z_tartaglia"]), "2H 2S 3C 3D 9H"), 420, "Tartaglia four low cards: 30 x 14")
	eq(_total(_run(["z_colombina"]), "QH QS"), 480, "Colombina two queens: 60 x 8")
	eq(_total(_run(["z_sandrone"]), "9H 9S"), 104, "Sandrone two nines: 52 x 2")


func test_pulcinella_follows_the_first_suit() -> void:
	eq(_total(_run(["z_pulcinella"]), "2H 7H 9H JH KH"), 1022, "flush: 73 x 14")
	eq(_total(_run(["z_pulcinella"]), "KH KS"), 120, "only the first heart matches: 30 x 4")
	eq(_total(_run(["z_pulcinella"]), "KH KS:enh_wild"), 180, "a wild card matches too: 30 x 6")
	eq(_total(_run(["z_pulcinella"]), "KC:enh_stone KH KS"), 160, "a suitless first card matches nothing")


func test_meneghino_no_face_cards() -> void:
	eq(_total(_run(["z_meneghino"]), "9H 9S"), 126, "no faces: (28+35) x 2")
	eq(_total(_run(["z_meneghino"]), "KH KS"), 60, "faces: nothing")


# --- money and growth ---

func test_brighella_pays_unused_discards() -> void:
	var run := _run(["z_huge", "z_brighella"])
	run.apply({"a": "select_show"})
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})
	ok(run.payout.has({"src": "zanni:z_brighella#1", "v": 3}), "3 unused discards: 3 ducats")


func test_pantalone_grows_with_purchases() -> void:
	var run := _run(["z_huge", "z_pantalone"])
	run.apply({"a": "select_show"})
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})
	run.apply({"a": "cash_out"})
	run.ducats = 100
	run.apply({"a": "buy", "slot": 0})
	run.apply({"a": "buy", "slot": 1})
	var pantalone := run.zanni[1]
	eq(pantalone.state.get("mult"), 2, "two purchases")
	# Score with Pantalone alone; the purchases may be zanni with bonuses of their own.
	run.zanni.clear()
	run.zanni.append(pantalone)
	eq(_total(run, "KH KS"), 120, "+2 Mult: 30 x 4")


func test_truffaldino_pays_on_skip() -> void:
	var run := _run(["z_truffaldino"])
	pin_town(run)
	run.apply({"a": "skip_show"})
	eq(run.ducats, 13, "4 start + 5 favor + 4 Truffaldino")


func test_mezzetino_pays_per_seven() -> void:
	var run := _run(["z_mezzetino"])
	_total(run, "7H 7S")
	eq(run.ducats, 6, "two sevens: +2 ducats")


func test_real_shop_offers_batch_cards() -> void:
	ContentPacks.register_all()
	var run := RunState.create("REALSHOP")
	run.zanni.append(ItemCard.make("z_zanni", 2))
	run.phase = RunState.Phase.CASH_OUT
	run.apply({"a": "cash_out"})
	run.ducats = 1000
	var seen := {}
	for i in 40:
		for offer in run.shop.offers:
			seen[offer["id"]] = true
		run.apply({"a": "reroll"})
	ok(not seen.has("z_zanni"), "owned zanni not offered again")
	ok(not seen.has("s_libra"), "secret sign not offered")
	ok(seen.size() > 15, "a wide spread of cards")
