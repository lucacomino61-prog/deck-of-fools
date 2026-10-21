extends TestCase
## Card batch 2: every enhancement, edition, seal and Tarocchi does what cards/batch-02.md says.


func _real() -> void:
	ContentPacks.register_all()
	TestContent.add_test_defs()


func _run(zanni_ids := []) -> RunState:
	_real()
	var run := RunState.create("BATCH2")
	for z in zanni_ids:
		run.zanni.append(ItemCard.make(z, ContentDB.get_def(z).cost))
	return run


## A run in its first show, with a hand to target.
func _show(zanni_ids := []) -> RunState:
	var run := _run(zanni_ids)
	run.apply({"a": "select_show"})
	return run


func _total(run: RunState, played: Array[PlayingCard], held := "") -> float:
	return Scorer.score(run, played, cards(held)).total


## Cards from a spec, with `field` set to `value` on the first card.
func _first(spec: String, field: String, value: String) -> Array[PlayingCard]:
	var list := cards(spec)
	list[0].set(field, value)
	return list


## Adds a Tarocchi and uses it on `targets`; true if the use went through.
func _use(run: RunState, def_id: String, targets: Array = []) -> bool:
	run.consumables.append(ItemCard.make(def_id, 3))
	var ok_now: bool = run.apply({"a": "use", "index": run.consumables.size() - 1, "cards": ids(targets)})["ok"]
	if not ok_now:
		run.consumables.pop_back()
	return ok_now


func _win_first_show(run: RunState) -> void:
	run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})


# --- content and text ---

func test_batch_contents() -> void:
	ContentPacks.register_all()
	eq(ContentDB.pool("enhancement").size(), 8, "8 enhancements")
	eq(ContentDB.pool("edition").size(), 4, "4 editions")
	eq(ContentDB.pool("seal").size(), 4, "4 seals")
	var tarocchi := ContentDB.pool("tarocchi")
	eq(tarocchi.size(), 22, "22 tarocchi")
	ok(tarocchi.all(func(d: ContentDef) -> bool: return d.cost == 3), "tarocchi cost 3")
	eq(tarocchi[0].id, "t_matto", "arcana order starts with Il Matto")
	eq(tarocchi[21].id, "t_mondo", "and ends with Il Mondo")


func test_every_card_has_text() -> void:
	ContentPacks.register_all()
	var keys := {}
	var f := FileAccess.open("res://i18n/cards.csv", FileAccess.READ)
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() >= 2 and line[1] != "":
			keys[line[0]] = true
	for kind in ["enhancement", "edition", "seal", "tarocchi"]:
		for d in ContentDB.pool(kind):
			ok(keys.has(d.id + ".name"), d.id + " has a name")
			ok(keys.has(d.id + ".text"), d.id + " has text")
	for d in ContentDB.pool("tarocchi"):
		ok(keys.has(d.id + ".gloss"), d.id + " has an English gloss")


# --- enhancements ---

func test_scoring_enhancements() -> void:
	var run := _run()
	eq(_total(run, _first("KH KS", "enhancement", "enh_lacquered")), 120, "Lacquered: (30+30) x 2")
	eq(_total(run, _first("KH KS", "enhancement", "enh_masked")), 180, "Masked: 30 x 6")
	eq(_total(run, cards("2H 7H 9H JH KS:enh_motley")), 292, "Motley completes a flush")
	eq(_total(run, _first("KH KS", "enhancement", "enh_mirror")), 120, "Mirror: 30 x 4")
	eq(_total(run, cards("QH QS"), "KH:enh_iron"), 90, "Iron held: 30 x 2 x 1.5")
	eq(_total(run, cards("KH KS 5C:enh_marble")), 160, "Marble: +50, always scores")


func test_charmed_with_certain_luck() -> void:
	var run := _run(["z_lucky"])
	eq(_total(run, _first("KH KS", "enhancement", "enh_charmed")), 660, "both chances hit: 30 x 22")
	eq(run.ducats, 24, "+20 ducats")


func test_mirror_shatters_about_one_in_four() -> void:
	_real()
	var shattered := 0
	for i in 80:
		var run := RunState.create("MIRROR-%d" % i)
		run.apply({"a": "select_show"})
		var card := run.hand[0]
		card.enhancement = "enh_mirror"
		run.apply({"a": "play", "cards": [card.id]})
		if not run.full_deck.has(card):
			shattered += 1
			ok(not run.discard_pile.has(card), "a shattered card isn't discarded")
			eq(run.counters.get("cards_destroyed"), 1, "counted as destroyed")
	ok(shattered > 8 and shattered < 35, "shattered %d of 80" % shattered)


func test_gilt_pays_when_held() -> void:
	var run := _show(["z_huge"])
	var kept := run.hand[7]
	kept.enhancement = "enh_gilt"
	_win_first_show(run)
	ok(run.payout.has({"src": "card:%d" % kept.id, "v": 3}), "Gilt card held: +3")


# --- editions ---

func test_card_editions() -> void:
	var run := _run()
	eq(_total(run, _first("KH KS", "edition", "ed_silvered")), 160, "Silvered card: (30+50) x 2")
	eq(_total(run, _first("KH KS", "edition", "ed_opaline")), 360, "Opaline card: 30 x 12")
	eq(_total(run, _first("KH KS", "edition", "ed_prismatic")), 90, "Prismatic card: 30 x 3")


func test_zanni_editions_wrap_the_effect() -> void:
	var run := _run()
	var z := ItemCard.make("z_zanni", 2)
	run.zanni.append(z)
	z.edition = "ed_silvered"
	eq(_total(run, cards("KH KS")), 480, "Silvered zanni: (30+50) x 6")
	z.edition = "ed_opaline"
	eq(_total(run, cards("KH KS")), 480, "Opaline zanni: 30 x (2+10+4)")
	z.edition = "ed_prismatic"
	eq(_total(run, cards("KH KS")), 270, "Prismatic after the zanni: 30 x (2+4) x 1.5")


func test_shadow_adds_a_slot() -> void:
	var run := _run(["z_zanni", "z_zanni", "z_zanni", "z_zanni", "z_zanni"])
	ok(run.add_zanni("z_isabella", "ed_shadow"), "a Shadow zanni fits when slots are full")
	eq(run.stat("zanni_slots"), 6, "6 zanni slots")
	ok(not run.add_zanni("z_flavio"), "but nothing else does")
	run.consumables.append(ItemCard.make("t_morte", 3, "ed_shadow"))
	eq(run.stat("consumable_slots"), 3, "a Shadow consumable adds a consumable slot")


func test_shop_editions() -> void:
	ContentPacks.register_all()
	var run := RunState.create("EDITIONS")
	run.phase = RunState.Phase.CASH_OUT
	run.apply({"a": "cash_out"})
	run.ducats = 100000
	var shiny := 0
	var zanni_offers := 0
	var wrong := 0
	for i in 300:
		for o in run.shop.offers:
			if o["kind"] == "zanni":
				zanni_offers += 1
			if o["edition"] != "":
				shiny += 1
				var extra := int(ContentDB.get_def(o["edition"]).data["extra_cost"])
				if o["kind"] != "zanni" or o["cost"] != ContentDB.get_def(o["id"]).cost + extra:
					wrong += 1
		run.apply({"a": "reroll"})
	eq(wrong, 0, "only zanni shine, and they cost the surcharge")
	ok(shiny > 2 and shiny < zanni_offers * 0.1, "%d shiny of %d zanni offers" % [shiny, zanni_offers])


# --- seals ---

func test_scoring_seals() -> void:
	var run := _run()
	_total(run, _first("KH KS", "seal", "seal_ducal"))
	eq(run.ducats, 7, "Ducal: +3 ducats")
	eq(_total(run, _first("KH KS", "seal", "seal_encore")), 80, "Encore: the king scores twice")


func test_astral_seal_creates_the_last_hands_sign() -> void:
	var run := _show(["z_huge"])
	run.hand[7].seal = "seal_astral"
	_win_first_show(run)
	eq(run.consumables.size(), 1, "one Sign created")
	eq(run.consumables[0].def_id, SignCards.for_hand(run.counters["last_hand"]), "for the hand just played")


func test_oracle_seal_on_discard() -> void:
	var run := _show()
	run.hand[0].seal = "seal_oracle"
	run.apply({"a": "discard", "cards": [run.hand[0].id]})
	eq(run.consumables.size(), 1, "a Tarocchi appears")
	eq(run.consumables[0].def().kind, "tarocchi", "of the right kind")
	run.consumables.append(ItemCard.make("t_morte", 3))
	run.hand[0].seal = "seal_oracle"
	run.apply({"a": "discard", "cards": [run.hand[0].id]})
	eq(run.consumables.size(), 2, "nothing when the slots are full")


# --- tarocchi ---

func test_enhancing_tarocchi() -> void:
	var table := [
		["t_bagatto", "enh_motley", 1], ["t_imperatrice", "enh_lacquered", 2],
		["t_imperatore", "enh_gilt", 1], ["t_amanti", "enh_masked", 2],
		["t_ruota", "enh_charmed", 2], ["t_forza", "enh_iron", 1],
		["t_temperanza", "enh_mirror", 1], ["t_torre", "enh_marble", 1],
	]
	for row in table:
		var run := _show()
		var most: int = row[2]
		ok(not _use(run, row[0], run.hand.slice(0, most + 1)), row[0] + " refuses too many cards")
		ok(_use(run, row[0], run.hand.slice(0, most)), row[0] + " used")
		ok(run.hand.slice(0, most).all(func(c: PlayingCard) -> bool: return c.enhancement == row[1]),
			row[0] + " applied " + row[1])


func test_suit_tarocchi() -> void:
	var table := [["t_stella", 1], ["t_luna", 0], ["t_sole", 3], ["t_mondo", 2]]
	for row in table:
		var run := _show()
		ok(not _use(run, row[0], run.hand.slice(0, 4)), row[0] + " refuses 4 cards")
		ok(_use(run, row[0], run.hand.slice(0, 3)), row[0] + " used on 3")
		ok(run.hand.slice(0, 3).all(func(c: PlayingCard) -> bool: return c.suit == row[1]), row[0] + " changed the suit")


func test_matto_randomises() -> void:
	var run := _show()
	var targets := run.hand.slice(0, 2)
	ok(_use(run, "t_matto", targets), "used")
	for card: PlayingCard in targets:
		ok(ContentDB.get_def(card.enhancement).kind == "enhancement", "random enhancement")
		ok(card.rank >= 2 and card.rank <= 14, "valid rank")


func test_papessa_needs_a_played_hand() -> void:
	var run := _show()
	ok(not _use(run, "t_papessa"), "nothing played yet")
	run.hand_levels.mark_played(HandTable.PAIR)
	run.hand_levels.mark_played(HandTable.PAIR)
	run.hand_levels.mark_played(HandTable.FLUSH)
	ok(_use(run, "t_papessa"), "used")
	eq(run.consumables.size(), 1, "one Sign")
	eq(run.consumables[0].def_id, "s_gemini", "for the most played hand")


func test_papa_creates_tarocchi() -> void:
	var run := _show()
	ok(_use(run, "t_papa"), "used")
	eq(run.consumables.size(), 2, "two created")
	ok(run.consumables.all(func(i: ItemCard) -> bool: return i.def().kind == "tarocchi" and i.def_id != "t_papa"),
		"Tarocchi, never Il Papa")
	var one_slot := _show()
	one_slot.consumables.append(ItemCard.make("t_morte", 3))
	ok(_use(one_slot, "t_papa"), "used with one slot left")
	eq(one_slot.consumables.size(), 2, "only one created")


func test_carro_giustizia_eremita() -> void:
	var run := _show()
	run.hand[0].rank = PlayingCard.KING
	run.hand[1].rank = PlayingCard.ACE
	ok(_use(run, "t_carro", run.hand.slice(0, 2)), "Carro used")
	eq([run.hand[0].rank, run.hand[1].rank], [PlayingCard.ACE, 2], "King to Ace, Ace to 2")

	var left := run.hand[2]
	var right := run.hand[3]
	right.enhancement = "enh_masked"
	right.seal = "seal_ducal"
	ok(_use(run, "t_giustizia", [left, right]), "Giustizia used")
	eq([left.rank, left.suit, left.enhancement, left.seal], [right.rank, right.suit, "enh_masked", "seal_ducal"],
		"left became a copy")
	ok(left.id != right.id, "still two cards")

	var doomed := run.hand.slice(4, 6)
	ok(_use(run, "t_eremita", doomed), "Eremita used")
	eq(run.full_deck.size(), 50, "two cards gone from the deck")
	ok(not run.hand.has(doomed[0]) and not run.hand.has(doomed[1]), "and from the hand")


func test_appeso() -> void:
	var run := _show(["z_lucky", "z_zanni"])
	ok(_use(run, "t_appeso"), "used")
	var shining := run.zanni.filter(func(i: ItemCard) -> bool: return i.edition != "")
	eq(shining.size(), 1, "one zanni gained an edition")
	ok(shining[0].edition in ["ed_silvered", "ed_opaline", "ed_prismatic"], "never Shadow")
	var none := _show()
	ok(not _use(none, "t_appeso"), "refused with no plain zanni")


func test_money_tarocchi() -> void:
	var run := _run(["z_zanni", "z_colombina"])
	ok(_use(run, "t_morte"), "Morte used")
	eq(run.ducats, 7, "4 + sell values 1 + 2")
	for i in 20:
		run.zanni.append(ItemCard.make("z_flavio", 10))
	run.ducats = 0
	_use(run, "t_morte")
	eq(run.ducats, 50, "Morte caps at 50")
	run.ducats = 4
	_use(run, "t_diavolo")
	eq(run.ducats, 8, "Diavolo doubles")
	run.ducats = 30
	_use(run, "t_diavolo")
	eq(run.ducats, 50, "Diavolo adds at most 20")


func test_giudizio() -> void:
	var run := _run()
	ok(_use(run, "t_giudizio"), "used")
	eq(run.zanni.size(), 1, "a zanni appeared")
	ok(run.zanni[0].def().kind == "zanni", "a real zanni")
	var full := _run(["z_zanni", "z_zanni", "z_zanni", "z_zanni", "z_zanni"])
	ok(not _use(full, "t_giudizio"), "refused with no free slot")
