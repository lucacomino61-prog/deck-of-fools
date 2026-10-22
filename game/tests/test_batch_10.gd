extends TestCase
## Card batch 10: every Patron's whim and every Favor does what cards/batch-10.md says.

const MIN_TOWN := {
	"pt_censore": 1, "pt_badessa": 1, "pt_banchiere": 1, "pt_capitano_giustizia": 1,
	"pt_guardacaccia": 1, "pt_critico": 1, "pt_purista": 2, "pt_gabelliere": 2, "pt_avaro": 6,
	"pt_fortezza": 2, "pt_spione": 2, "pt_maschera_grigia": 2, "pt_gioco_buio": 2,
	"pt_ciambellano": 1, "pt_priore": 2, "pt_maggiordomo": 1, "pt_borsaiolo": 1, "pt_vescovo": 2,
	"pt_duca": 2, "pt_siniscalco": 1, "pt_impaziente": 3, "pt_marchese": 2, "pt_contessa": 2,
}
const FINALES := ["pt_granduca", "pt_granduchessa", "pt_inquisitore", "pt_cardinale", "pt_regina"]
const PENDING := ["f_raccomandazione", "f_lettera_principe", "f_velo_nero", "f_filo_argento",
	"f_perla", "f_caleidoscopio", "f_dote", "f_sigillo_reale", "f_buono", "f_gemello",
	"f_bagaglio", "f_rimpasto"]


func _run(zanni_ids := [], seed_text := "BATCH10") -> RunState:
	ContentPacks.register_all()
	TestContent.add_test_defs()
	var run := RunState.create(seed_text)
	for z in zanni_ids:
		run.zanni.append(ItemCard.make(z, ContentDB.get_def(z).cost))
	return run


## Starts this town's Patron show with `patron_id` as the Patron.
func _patron_show(run: RunState, patron_id: String) -> void:
	run.town_patron = patron_id
	run.show_index = Shows.PATRON
	run.phase = RunState.Phase.CHOOSE_SHOW
	run.apply({"a": "select_show"})


## Makes the first `count` cards in hand share `rank`, and returns their ids.
func _same_rank(run: RunState, count: int, rank: int) -> Array:
	for i in count:
		run.hand[i].rank = rank
		run.hand[i].enhancement = ""
	return ids(run.hand.slice(0, count))


func _to_shop(run: RunState) -> void:
	run.phase = RunState.Phase.CASH_OUT
	run.apply({"a": "cash_out"})


# --- content ---

func test_batch_contents() -> void:
	ContentPacks.register_all()
	var patrons := ContentDB.pool("patron", func(d: ContentDef) -> bool: return not d.data.get("campaign", false))
	eq(patrons.size(), 28, "28 Patrons (Messer Grifone is the campaign's own)")
	for id: String in MIN_TOWN:
		eq(ContentDB.get_def(id).data.get("min_town"), MIN_TOWN[id], id + " from town")
	for id: String in FINALES:
		ok(ContentDB.get_def(id).data.get("finale", false), id + " is a finale")
	var favors := ContentDB.pool("favor")
	eq(favors.size(), 24, "24 Favors")
	for d in favors:
		eq(bool(d.data.get("pending", false)), PENDING.has(d.id), d.id + " waits only if it should")


func test_every_card_has_text() -> void:
	ContentPacks.register_all()
	var keys := {}
	var f := FileAccess.open("res://i18n/cards.csv", FileAccess.READ)
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() >= 2 and line[1] != "":
			keys[line[0]] = true
	for kind in ["patron", "favor"]:
		for d in ContentDB.pool(kind):
			ok(keys.has(d.id + ".name") and keys.has(d.id + ".text"), d.id + " has a name and text")


func test_patrons_respect_their_towns() -> void:
	for i in 40:
		ContentPacks.register_all()
		var run := RunState.create("TOWN1-%d" % i)
		ok(int(ContentDB.get_def(run.town_patron).data["min_town"]) <= 1, "town 1 gets a town-1 Patron")
	ContentPacks.register_all()
	var late := RunState.create("FINALE")
	late.town = 8
	late._start_town()
	ok(FINALES.has(late.town_patron), "town 8 gets a finale Patron")


# --- debuffs ---

func test_debuffing_patrons() -> void:
	var table := [
		["pt_badessa", PlayingCard.Suit.HEARTS], ["pt_banchiere", PlayingCard.Suit.DIAMONDS],
		["pt_capitano_giustizia", PlayingCard.Suit.SPADES], ["pt_guardacaccia", PlayingCard.Suit.CLUBS],
	]
	for row in table:
		var run := _run()
		_patron_show(run, row[0])
		ok(run.full_deck.all(func(c: PlayingCard) -> bool: return c.debuffed == (c.suit == row[1])), row[0] + " debuffs one suit")
	var faces := _run()
	_patron_show(faces, "pt_censore")
	ok(faces.full_deck.all(func(c: PlayingCard) -> bool: return c.debuffed == c.is_face()), "Censore debuffs face cards")


func test_siniscalco_remembers_the_town() -> void:
	var run := _run()
	var seen := run.full_deck[5]
	run.town_played[seen.id] = true
	_patron_show(run, "pt_siniscalco")
	ok(seen.debuffed, "a card played earlier this town is debuffed")
	eq(run.full_deck.filter(func(c: PlayingCard) -> bool: return c.debuffed).size(), 1, "only that one")


# --- rules about what you play ---

func test_critico_no_repeats() -> void:
	var run := _run()
	_patron_show(run, "pt_critico")
	ok(run.apply({"a": "play", "cards": _same_rank(run, 2, 13)})["total"] > 0, "first pair scores")
	var again: Dictionary = run.apply({"a": "play", "cards": _same_rank(run, 2, 12)})
	eq(again["total"], 0, "a second pair scores nothing")


func test_purista_one_kind() -> void:
	var run := _run()
	_patron_show(run, "pt_purista")
	run.apply({"a": "play", "cards": _same_rank(run, 2, 13)})
	run.hand[0].enhancement = ""
	eq(run.apply({"a": "play", "cards": [run.hand[0].id]})["total"], 0, "a high card after a pair scores nothing")


func test_ciambellano_five_cards() -> void:
	var run := _run()
	_patron_show(run, "pt_ciambellano")
	eq(run.apply({"a": "play", "cards": [run.hand[0].id]})["total"], 0, "one card: nothing")
	ok(run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})["total"] > 0, "five cards score")


func test_gabelliere_and_avaro() -> void:
	var run := _run()
	_patron_show(run, "pt_gabelliere")
	run.ducats = 10
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 3))})
	eq(run.ducats, 7, "Gabelliere: -1 per card played")

	var miser := _run()
	_patron_show(miser, "pt_avaro")
	miser.ducats = 30
	miser.apply({"a": "play", "cards": _same_rank(miser, 2, 13)})
	eq(miser.ducats, 0, "Avaro: the first pair is the most played hand, ducats gone")


func test_target_patrons() -> void:
	var run := _run()
	_patron_show(run, "pt_fortezza")
	eq(run.show_target, 1200, "Fortezza: x4")
	var countess := _run()
	_patron_show(countess, "pt_contessa")
	eq([countess.show_target, countess.hands_left], [300.0, 1], "Contessa: x1, one hand")
	var duke := _run()
	duke.town = 8
	_patron_show(duke, "pt_granduca")
	eq(duke.show_target, 300000, "Granduca: x6 of 50,000")


func test_finale_pays_more() -> void:
	var run := _run(["z_huge"])
	run.town = 8
	_patron_show(run, "pt_granduca")
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})
	ok(run.payout.has({"src": "show", "v": 8}), "a finale Patron pays 8")


# --- face down ---

func test_face_down_patrons() -> void:
	var grey := _run()
	_patron_show(grey, "pt_maschera_grigia")
	ok(grey.hand.all(func(c: PlayingCard) -> bool: return c.face_down), "Maschera Grigia: the first hand is face down")
	grey.apply({"a": "discard", "cards": ids(grey.hand.slice(0, 3))})
	eq(grey.hand.filter(func(c: PlayingCard) -> bool: return not c.face_down).size(), 3, "later draws are face up")

	var dark := _run()
	_patron_show(dark, "pt_gioco_buio")
	ok(dark.hand.all(func(c: PlayingCard) -> bool: return not c.face_down), "Gioco al Buio: the first hand is face up")
	dark.apply({"a": "discard", "cards": ids(dark.hand.slice(0, 3))})
	eq(dark.hand.filter(func(c: PlayingCard) -> bool: return c.face_down).size(), 3, "the cards drawn after are face down")

	var marquis := _run()
	_patron_show(marquis, "pt_marchese")
	ok(marquis.hand.all(func(c: PlayingCard) -> bool: return c.face_down == c.is_face()), "Marchese: face cards face down")

	var down := 0
	for i in 30:
		var spy := _run([], "SPY-%d" % i)
		_patron_show(spy, "pt_spione")
		down += spy.hand.filter(func(c: PlayingCard) -> bool: return c.face_down).size()
	ok(down > 15 and down < 60, "Spione: about 1 in 7 face down (%d of 240)" % down)


# --- hand, discards and draws ---

func test_hand_and_draw_patrons() -> void:
	var prior := _run()
	_patron_show(prior, "pt_priore")
	eq(prior.discards_left, 0, "Priore: no discards")
	var butler := _run()
	_patron_show(butler, "pt_maggiordomo")
	eq(butler.hand.size(), 7, "Maggiordomo: 7 cards")
	var hurry := _run()
	_patron_show(hurry, "pt_impaziente")
	hurry.apply({"a": "discard", "cards": ids(hurry.hand.slice(0, 5))})
	eq(hurry.hand.size(), 6, "Impaziente: 3 drawn after discarding 5")


func test_borsaiolo_steals_two() -> void:
	var run := _run()
	_patron_show(run, "pt_borsaiolo")
	run.apply({"a": "play", "cards": [run.hand[0].id]})
	eq(run.discard_pile.size(), 3, "the played card and 2 stolen ones")
	eq(run.hand.size(), 8, "then the hand refills")


func test_vescovo_and_duca() -> void:
	var run := _run()
	run.hand_levels.level_up(HandTable.PAIR, 2)
	_patron_show(run, "pt_vescovo")
	run.apply({"a": "play", "cards": _same_rank(run, 2, 13)})
	eq(run.hand_levels.level(HandTable.PAIR), 2, "Vescovo: the pair lost a level")

	var duke := _run()
	_patron_show(duke, "pt_duca")
	eq(Scorer.score(duke, cards("KH KS"), cards("")).total, 25, "Duca: (5 + 20) x 1")


# --- finales ---

func test_granduchessa_disables_one_jester() -> void:
	var run := _run(["z_zanni", "z_payer", "z_colombina"])
	run.town = 8
	_patron_show(run, "pt_granduchessa")
	eq(run.zanni.filter(func(z: ItemCard) -> bool: return z.debuffed).size(), 1, "one Jester stopped")
	run.apply({"a": "play", "cards": [run.hand[0].id]})
	eq(run.zanni.filter(func(z: ItemCard) -> bool: return z.debuffed).size(), 1, "still exactly one after a hand")


func test_inquisitore_until_a_sale() -> void:
	var run := _run(["z_payer"])
	run.town = 8
	_patron_show(run, "pt_inquisitore")
	ok(run.full_deck.all(func(c: PlayingCard) -> bool: return c.debuffed), "every card debuffed")
	run.apply({"a": "sell", "zone": "zanni", "index": 0})
	ok(run.full_deck.all(func(c: PlayingCard) -> bool: return not c.debuffed), "selling a Jester lifts it")


func test_cardinale_hides_jesters() -> void:
	var run := _run(["z_zanni", "z_payer", "z_colombina"])
	run.town = 8
	_patron_show(run, "pt_cardinale")
	ok(run.zanni.all(func(z: ItemCard) -> bool: return z.face_down), "every Jester face down")
	eq(run.zanni.size(), 3, "none lost")


func test_regina_forces_a_card() -> void:
	var run := _run()
	run.town = 8
	_patron_show(run, "pt_regina")
	var forced := int(run.show_counters.get("forced", -1))
	ok(run._hand_card(forced) != null, "a card in hand is selected")
	var others := run.hand.filter(func(c: PlayingCard) -> bool: return c.id != forced)
	ok(not run.apply({"a": "play", "cards": [others[0].id]})["ok"], "playing without it is refused")
	ok(run.apply({"a": "discard", "cards": [forced]})["ok"], "discarding it is fine")
	ok(run._hand_card(int(run.show_counters["forced"])) != null, "a new card is selected")


# --- favors ---

func test_free_jester_favors() -> void:
	var run := _run()
	run.gain_favor("f_raccomandazione")
	run.gain_favor("f_lettera_principe")
	eq(run.favors.size(), 2, "both wait for the shop")
	_to_shop(run)
	var free := run.shop.offers.filter(func(o: Dictionary) -> bool: return o.get("free", false))
	eq(free.map(func(o: Dictionary) -> int: return ContentDB.get_def(o["id"]).rarity), [1, 2], "a free uncommon and a free rare")
	ok(free.all(func(o: Dictionary) -> bool: return run.offer_price(o) == 0), "both cost 0")
	eq(run.favors.size(), 0, "used up")


func test_shine_favors_wait_for_a_plain_jester() -> void:
	var table := [["f_velo_nero", "ed_shadow"], ["f_filo_argento", "ed_silvered"], ["f_perla", "ed_opaline"], ["f_caleidoscopio", "ed_prismatic"]]
	for row in table:
		var run := _run()
		_to_shop(run)
		run.gain_favor(row[0])
		run.shop.offers.assign([{"kind": "sign", "id": "s_gemini", "cost": 3, "edition": "", "sold": false}])
		run.fire_all("reroll", run)
		ok(run.favors.has(row[0]), row[0] + " waits while no Jester is on offer")
		run.shop.offers.assign([{"kind": "zanni", "id": "z_zanni", "cost": 2, "edition": "", "sold": false}])
		run.fire_all("reroll", run)
		eq(run.shop.offers[0]["edition"], row[1], row[0] + " shines the Jester")
		eq(run.offer_price(run.shop.offers[0]), 0, row[0] + " makes it free")


func test_dote_after_the_patron() -> void:
	var run := _run(["z_huge"])
	run.gain_favor("f_dote")
	run.apply({"a": "select_show"})
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})
	ok(run.favors.has("f_dote"), "a matinee isn't a Patron")
	run.apply({"a": "cash_out"})
	var before := run.ducats
	run.phase = RunState.Phase.CHOOSE_SHOW
	_patron_show(run, "patron_hearts")
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})
	eq(run.ducats, before + 25, "+25 after beating the Patron")


func test_sigillo_extra_warrant() -> void:
	var run := _run()
	run.gain_favor("f_sigillo_reale")
	_to_shop(run)
	run.ducats = 30
	ok(run.shop.extra_warrant != "" and run.shop.extra_warrant != run.town_warrant, "a second, different Warrant")
	ok(run.apply({"a": "buy_warrant", "index": 1})["ok"], "the extra one can be bought")
	ok(run.apply({"a": "buy_warrant", "index": 0})["ok"], "and the town's own too")


func test_lasciapassare_swaps_the_patron() -> void:
	var run := _run()
	var before := run.town_patron
	run.gain_favor("f_lasciapassare")
	ok(run.town_patron != before, "a different Patron, for free")
	eq(run.ducats, 4, "nothing paid")


func test_free_pack_favor_from_a_skip() -> void:
	var run := _run()
	run.town_favors.assign(["f_mazzo_incantato", "favor_cash"])
	run.apply({"a": "skip_show"})
	eq(run.phase, RunState.Phase.PACK, "the free pack opened")
	eq(run.pack["id"], "pk_tarocchi_grand", "a Grand Tarocchi Pack")
	eq(run.hand.size(), 8, "with a hand to target")
	run.apply({"a": "skip_pack"})
	eq(run.phase, RunState.Phase.CHOOSE_SHOW, "back to choosing the next show")
	eq(run.show_index, Shows.EVENING, "the evening show")


func test_gemello_doubles_the_next_favor() -> void:
	var run := _run()
	run.gain_favor("f_gemello")
	run.town_favors.assign(["f_invito", "favor_cash"])
	run.apply({"a": "skip_show"})
	eq(run.pack["id"], "pk_zanni_grand", "the first Jester pack")
	eq(run.pack_queue, ["pk_zanni_grand"] as Array[String], "a second one queued")
	run.apply({"a": "skip_pack"})
	eq(run.phase, RunState.Phase.PACK, "the copy opens next")
	run.apply({"a": "skip_pack"})
	eq(run.phase, RunState.Phase.CHOOSE_SHOW, "then back to the shows")
	ok(not run.favors.has("f_gemello"), "Il Gemello was used up")


func test_money_favors() -> void:
	var run := _run()
	run.counters["hands_played"] = 7
	run.counters["discards_unused"] = 5
	run.counters["skips"] = 3
	run.gain_favor("f_mancia")
	eq(run.ducats, 11, "Mancia: +7")
	run.gain_favor("f_straccio")
	eq(run.ducats, 16, "Straccio: +5")
	run.gain_favor("f_fretta")
	eq(run.ducats, 31, "Fretta: +15")
	run.gain_favor("f_raddoppio")
	eq(run.ducats, 62, "Raddoppio: doubled")
	run.gain_favor("f_raddoppio")
	eq(run.ducats, 102, "but at most +40")


func test_unused_discards_are_counted() -> void:
	var run := _run(["z_huge"])
	run.apply({"a": "select_show"})
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})
	eq(run.counters.get("discards_unused"), 3, "3 unused discards counted at the win")


func test_shop_favors() -> void:
	var run := _run()
	run.gain_favor("f_buono")
	run.gain_favor("f_rimpasto")
	_to_shop(run)
	ok(run.shop.offers.all(func(o: Dictionary) -> bool: return run.offer_price(o) == 0), "Buono: cards free")
	ok(run.shop.packs.all(func(p: Dictionary) -> bool: return run.offer_price(p) == 0), "and packs free")
	eq(run.reroll_price(), 0, "Rimpasto: the first reroll costs 0")
	run.apply({"a": "reroll"})
	eq(run.reroll_price(), 1, "then 1")


func test_bagaglio_next_show_only() -> void:
	var run := _run(["z_huge"])
	run.gain_favor("f_bagaglio")
	run.apply({"a": "select_show"})
	eq(run.hand.size(), 11, "+3 cards for this show")
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})
	ok(not run.favors.has("f_bagaglio"), "gone after the show")


func test_rinforzo_and_oroscopo() -> void:
	var run := _run()
	run.gain_favor("f_rinforzo")
	eq(run.zanni.size(), 2, "two Jesters created")
	ok(run.zanni.all(func(z: ItemCard) -> bool: return z.def().rarity == 0), "both common")
	run.gain_favor("f_oroscopo", HandTable.FLUSH)
	eq(run.hand_levels.level(HandTable.FLUSH), 4, "Oroscopo: +3 levels to the named hand")


func test_oroscopo_names_its_hand_when_offered() -> void:
	var found := false
	for i in 80:
		var run := _run([], "OROSCOPO-%d" % i)
		for slot in 2:
			if run.town_favors[slot] == "f_oroscopo":
				found = true
				ok(HandTable.ORDER.has(run.town_favor_notes[slot]), "it names a real hand")
	ok(found, "L'Oroscopo turned up in 80 towns")
