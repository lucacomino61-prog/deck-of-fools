class_name ScenarioCards
extends RefCounted
## Card batch 12 (approved 2026-10-22): the 24 Scenarios, risky three-beat scripts a show
## can be performed to. Data: tier (1 for towns 1–3, 2 for 4–6, 3 after) and three beats.
## A beat is a Dictionary of tests the played hand must all pass:
##   hand: a type it contains · exact: the type it is · cards: exactly N cards
##   suit_any / suit_all: a played card of the suit / every played card of it
##   rank_any: a played card of the rank · faces: true (a face card) / false (none)
##   share: the hand alone scores at least that share of the show's target
## RunState moves the beats on and pays them (_crowd_reacts, _compute_payout); the two
## rules below give a hit beat its ×Mult, a Fiasco its halving, and an ovation its ×1.5.

const BEATS := 3
const BEAT_XMULT := [1.0, 2.0, 3.0]
const BEAT_DUCATS := [3, 0, 5]
const FIASCO_XMULT := 0.5
const RULE_SCENARIO := "rule_scenario"
const RULE_CROWD := "rule_crowd"


static func register() -> void:
	var pair := {"hand": HandTable.PAIR}
	var two_pair := {"hand": HandTable.TWO_PAIR}
	var three := {"hand": HandTable.THREE_KIND}
	var straight := {"hand": HandTable.STRAIGHT}
	var flush := {"hand": HandTable.FLUSH}
	var full_house := {"hand": HandTable.FULL_HOUSE}
	var four := {"hand": HandTable.FOUR_KIND}
	var single := {"cards": 1}
	var high := {"exact": HandTable.HIGH_CARD}
	var hearts_only := {"suit_all": PlayingCard.Suit.HEARTS}
	var third := {"cards": 5, "share": 1.0 / 3.0}

	_add("sc_servitore", 1, [pair, pair, two_pair])
	_add("sc_burle", 1, [single, pair, three])
	_add("sc_serenata", 1, [{"suit_any": PlayingCard.Suit.HEARTS}, {"rank_any": PlayingCard.QUEEN}, two_pair])
	_add("sc_dottore", 1, [{"cards": 5}, pair, straight])
	_add("sc_cena", 1, [{"faces": false}, pair, two_pair])
	_add("sc_spaccone", 1, [{"faces": true}, {"faces": true}, three])
	_add("sc_fiera", 1, [{"cards": 2}, {"cards": 3}, {"cards": 4}])
	_add("sc_ritorno", 1, [high, pair, three])

	_add("sc_pazzia", 2, [three, single, straight])
	_add("sc_finto_principe", 2, [{"rank_any": PlayingCard.KING}, two_pair, flush])
	_add("sc_locandiera", 2, [pair, flush, pair])
	_add("sc_marito", 2, [two_pair, straight, two_pair])
	_add("sc_pulcinella", 2, [{"suit_any": PlayingCard.Suit.SPADES}, flush, straight])
	_add("sc_ladro", 2, [{"suit_all": PlayingCard.Suit.DIAMONDS}, {"suit_all": PlayingCard.Suit.DIAMONDS}, flush])
	_add("sc_lelio", 2, [hearts_only, pair, flush])
	_add("sc_naufragio", 2, [straight, three, straight])

	_add("sc_melarance", 3, [three, three, full_house])
	_add("sc_re_cervo", 3, [flush, full_house, flush])
	_add("sc_turandot", 3, [straight, flush, full_house])
	_add("sc_maschere", 3, [full_house, two_pair, four])
	_add("sc_gran_commedia", 3, [third, third, third])
	_add("sc_rovescia", 3, [high, high, {"share": 0.25}])
	_add("sc_carnevale", 3, [flush, straight, full_house])
	_add("sc_finale", 3, [two_pair, full_house, four])

	# The rules that act inside scoring, as sources while a show is on (RunState._sources).
	var scenario_rule := func(ctx: ScoreContext, _item: ItemCard) -> void:
		var run := ctx.run
		var def := ContentDB.get_def(run.scenario)
		if def == null or not run.scenario_on:
			return
		var beat := run.scenario_beat
		var hit := beat_met(ctx, (def.data["beats"] as Array)[beat])
		ctx.flags["beat"] = hit
		if not hit:
			ctx.x_mult(FIASCO_XMULT, "fiasco")
		elif BEAT_XMULT[beat] != 1.0:
			ctx.x_mult(BEAT_XMULT[beat], "scenario")
	ContentDB.register(ContentDef.make(RULE_SCENARIO, "rule", 0, 0, {"before_total": scenario_rule}))

	var crowd_rule := func(ctx: ScoreContext, _item: ItemCard) -> void:
		if ctx.run.ovation:
			ctx.x_mult(RunState.OVATION_XMULT, "ovation")
	ContentDB.register(ContentDef.make(RULE_CROWD, "rule", 0, 0, {"before_total": crowd_rule}))


static func _add(id: String, tier: int, beats: Array) -> void:
	ContentDB.register(ContentDef.make(id, "scenario", 0, tier - 1, {}, {"tier": tier, "beats": beats}))


## Whether the hand being scored passes every test of `beat` (checked before the beat's
## own ×Mult, so "share" means the hand without it).
static func beat_met(ctx: ScoreContext, beat: Dictionary) -> bool:
	if beat.has("hand") and not ctx.has(str(beat["hand"])):
		return false
	if beat.has("exact") and ctx.hand_type != str(beat["exact"]):
		return false
	if beat.has("cards") and ctx.played.size() != int(beat["cards"]):
		return false
	if beat.has("suit_any") and not ctx.played.any(func(c: PlayingCard) -> bool: return c.has_suit(int(beat["suit_any"]))):
		return false
	if beat.has("suit_all") and not ctx.played.all(func(c: PlayingCard) -> bool: return c.has_suit(int(beat["suit_all"]))):
		return false
	if beat.has("rank_any") and not ctx.played.any(func(c: PlayingCard) -> bool: return c.has_rank() and c.rank == int(beat["rank_any"])):
		return false
	if beat.has("faces"):
		var any_face := ctx.played.any(func(c: PlayingCard) -> bool: return ctx.run.is_face(c))
		if any_face != bool(beat["faces"]):
			return false
	if beat.has("share") and floorf(ctx.points * ctx.mult) < ctx.run.show_target * float(beat["share"]):
		return false
	return true


## A Scenario for the show about to be chosen, from the tier of the current town.
static func pick(run: RunState, r: ZRng, exclude := "") -> String:
	var tier := 1 if run.town <= 3 else (2 if run.town <= 6 else 3)
	if run.scenario_tier() > 0:
		tier = run.scenario_tier()
	var pool := ContentDB.pool("scenario", func(d: ContentDef) -> bool: return int(d.data["tier"]) == tier and d.id != exclude)
	if pool.is_empty():
		return ""
	return pool[r.below(pool.size())].id


## A beat in words, e.g. "a Pair", "exactly 5 cards", "only Diamonds".
static func beat_text(beat: Dictionary) -> String:
	var suits := ["Spades", "Hearts", "Clubs", "Diamonds"]
	var ranks := {PlayingCard.JACK: "Jack", PlayingCard.QUEEN: "Queen", PlayingCard.KING: "King", PlayingCard.ACE: "Ace"}
	var parts: Array[String] = []
	if beat.has("exact"):
		parts.append(TranslationServer.translate("hand." + str(beat["exact"])))
	if beat.has("hand"):
		parts.append(_with_article(TranslationServer.translate("hand." + str(beat["hand"]))))
	if beat.has("cards"):
		var n := int(beat["cards"])
		parts.append("a single card" if n == 1 else "exactly %d cards" % n)
	if beat.has("suit_any"):
		parts.append("a " + str(suits[int(beat["suit_any"])]).trim_suffix("s"))
	if beat.has("suit_all"):
		parts.append("only " + str(suits[int(beat["suit_all"])]))
	if beat.has("rank_any"):
		parts.append("a " + str(ranks.get(int(beat["rank_any"]), str(beat["rank_any"]))))
	if beat.has("faces"):
		parts.append("a face card" if bool(beat["faces"]) else "no face cards")
	if beat.has("share"):
		var share := float(beat["share"])
		parts.append("worth %s of the target" % ("a third" if is_equal_approx(share, 1.0 / 3.0) else "a quarter"))
	return ", ".join(parts)


static func _with_article(hand_name: String) -> String:
	if hand_name.begins_with("Two") or hand_name.begins_with("Three") or hand_name.begins_with("Four") or hand_name.begins_with("Five"):
		return hand_name
	return "a " + hand_name
