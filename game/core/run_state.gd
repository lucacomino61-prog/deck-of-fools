class_name RunState
extends RefCounted
## One run: the whole game state and every rule that changes it.
##
## All randomness comes from named ZRng streams derived from the run seed, and every change
## goes through apply(action). So the seed plus the action log replays a run exactly, which
## is what cloud saves, the daily run and leaderboard checks rely on.
##
## Actions (Dictionaries, "a" = name):
##   select_show · skip_show · play {cards} · discard {cards} · cash_out
##   buy {slot} · buy_pack {slot} · buy_warrant · sell {zone, index} · reroll
##   use {index, cards} · reorder_zanni {order} · swap_patron · leave_shop
##   pick {index, cards} · skip_pack        (while a pack is open)

## PACK was added last so saved phase numbers keep their meaning.
enum Phase { CHOOSE_SHOW, IN_SHOW, CASH_OUT, SHOP, LOST, PACK }

const PATRON_SWAP_COST := 10
## Il Gemello: the Favor that doubles the next one you take.
const FAVOR_TWIN := "f_gemello"
## Stake stickers: a Perishable Jester lasts this many won shows; a Rented one costs 1 to
## buy and RENT at every cash-out.
const PERISH_SHOWS := 5
const RENT := 3

const SAVE_VERSION := 1

const BASE_STATS := {
	"hands": 4,
	"discards": 3,
	"hand_size": 8,
	"max_play": 5,
	"zanni_slots": 5,
	"consumable_slots": 2,
	"start_ducats": 4,
	"reward_matinee": 3,
	"reward_evening": 4,
	"reward_patron": 5,
	"hand_reward": 1,
	"interest_per": 5,
	"interest_cap": 5,
	"shop_slots": 2,
	"reroll_base": 5,
	"debt_limit": 0,
	"target_scaling": 1,
	"flush_min": 5,
	"straight_min": 5,
	"straight_gap": 0,
	"all_score": 0,
	## Multiplies every "N in M" chance.
	"luck": 1,
	## Above 0, Mirror cards never shatter.
	"mirror_safe": 0,
	## Levels a Sign adds to its hand.
	"sign_levels": 1,
	## Multiplies interest at cash-out.
	"interest_mult": 1,
	## Above 0, the patron's whim is off.
	"patron_muted": 0,
	## Patron target, in percent of the patron's usual size.
	"patron_target_pct": 100,
	## Free rerolls at the start of each shop.
	"free_rerolls": 0,
	## Ducats off every card and pack in the shop.
	"shop_discount": 0,
	## Above 0, every card with a rank counts as a face card.
	"all_faces": 0,
	## Single-card discards per show that don't use up a discard.
	"free_single_discards": 0,
	## Booster packs on offer in each shop.
	"pack_slots": 2,
	## Percent off shop cards and packs (applied before shop_discount).
	"shop_discount_pct": 0,
	## Shop and pack edition odds, in percent of normal.
	"edition_rate_pct": 100,
	## Ducats off every paid reroll.
	"reroll_discount": 0,
	## Above 0, Omens can turn up in Tarocchi packs.
	"omens_in_tarocchi_packs": 0,
	## Above 0, a Sign pack's first card is your most played hand's Sign.
	"sign_pack_favourite": 0,
	## How often Tarocchi and Signs fill shop slots, in percent of normal.
	"tarocchi_rate_pct": 100,
	"sign_rate_pct": 100,
	## Shop weight of playing cards (0 = never offered).
	"card_rate": 0,
	## Above 0, cards from the shop always carry an enhancement, seal or edition.
	"card_quality": 0,
	## Patron swaps allowed per town.
	"patron_swaps": 0,
	## Above 0, after a play or discard you draw exactly this many cards, whatever your hand size.
	"draw_exact": 0,
	## Ducats per unused discard at cash-out.
	"discard_reward": 0,
	## Every show's target, in percent of normal.
	"target_pct": 100,
	## Shop weight of Omens (0 = never offered).
	"omen_rate": 0,
	## Mirror cards shatter 1 in this many.
	"mirror_odds": 4,
	## Above 0, Jesters (or Signs) never turn up in the shop or packs.
	"jesters_banned": 0,
	"signs_banned": 0,
	## Above 0, every show is a Patron show.
	"all_patrons": 0,
	## Stake stickers on shop Jesters: percent chances, and whether Perishable joins in.
	"eternal_pct": 0,
	"perishable_on": 0,
	"rented_pct": 0,
	## Above 0, every Jester that joins gets this sticker (challenges).
	"all_eternal": 0,
	"all_perishable": 0,
	"all_rented": 0,
}

## Hooks a copying Jester (data "copies": "right" or "leftmost") borrows from its target.
## Growth hooks (buy, sell, skip…) and stat changes are never copied.
const COPYABLE := ["independent", "card_scored", "card_held", "retrigger_scored", "retrigger_held", "payout"]

const REWARD_STATS := ["reward_matinee", "reward_evening", "reward_patron"]

## What a shop card slot holds, and how rare a zanni is (common, uncommon, rare).
## Legendary zanni never appear in the shop. Playing cards ("card") come from card_rate.
const SHOP_KIND_WEIGHTS := {"zanni": 20, "tarocchi": 4, "sign": 4}
const ZANNI_RARITY_WEIGHTS := [70, 25, 5]
## Shop price of a playing card: plain, or with an enhancement, seal or edition.
const CARD_PRICE := 2
const CARD_PRICE_UPGRADED := 3

var seed_text := ""
var deck_id := "standard"
var stake := 1
var phase: int = Phase.CHOOSE_SHOW
var town := 1
var show_index := Shows.MATINEE
var won := false
var ducats := 0
var hand_levels := HandLevels.new()
var full_deck: Array[PlayingCard] = []
var draw_pile: Array[PlayingCard] = []
var hand: Array[PlayingCard] = []
var discard_pile: Array[PlayingCard] = []
var zanni: Array[ItemCard] = []
var consumables: Array[ItemCard] = []
var warrants: Array[String] = []
var favors: Array[String] = []
var town_patron := ""
var town_favors: Array[String] = ["", ""]
## This town's Warrant on sale ("" when none is left to offer), and whether it was bought.
var town_warrant := ""
var warrant_bought := false
var town_swaps := 0
## The open booster pack: {id, items, picks, back}; empty when no pack is open. `back` is
## the phase to return to.
var pack: Dictionary = {}
## Packs waiting to open after the current one closes (e.g. two free packs at once).
var pack_queue: Array[String] = []
## Permanent changes to stats from one-off effects (e.g. an Omen's "−1 card in hand").
var stat_mods: Dictionary = {}
## What each of this town's Favors names when offered (e.g. L'Oroscopo's hand); "" if nothing.
var town_favor_notes: Array[String] = ["", ""]
## Ids of cards played so far this town (Il Siniscalco remembers them).
var town_played: Dictionary = {}
## The note of the Favor being taken, only while its "gain" hook runs.
var favor_note := ""
var hands_left := 0
var discards_left := 0
var show_score := 0.0
var show_target := 0.0
var shop: ShopState = null
var payout: Array[Dictionary] = []
## Run-wide counters for effects and the stats screen.
var counters: Dictionary = {}
## Reset at the start of every show.
var show_counters: Dictionary = {}
var action_log: Array[Dictionary] = []
var _rngs: Dictionary = {}
var _next_card_id := 1
## True on the copy preview() scores.
var previewing := false
## While a copier fires its target's hook, events are labelled with the copier.
var _copy_label := ""
## The challenge this run plays ("" for a normal run).
var challenge := ""
## Card ids the profile hasn't unlocked: never offered or created in this run.
var locked: Dictionary = {}
## Card ids the player has seen this run (shop, packs, owned), for the collection.
var seen: Dictionary = {}
## Unlock feats achieved this run, by name (see Unlocks).
var feats: Dictionary = {}


## A new run. `challenge_id` sets up a challenge run; `locked_ids` are the cards the
## player's profile hasn't unlocked yet, which never turn up in this run.
static func create(seed_value: String, deck := "standard", stake_level := 1, challenge_id := "",
		locked_ids: Array = []) -> RunState:
	var run := RunState.new()
	run.seed_text = seed_value
	run.deck_id = deck
	run.stake = stake_level
	run.challenge = challenge_id
	for id in locked_ids:
		run.locked[str(id)] = true
	run._build_deck()
	run.ducats = run.stat("start_ducats")
	run.fire_all("run_start", run)
	run._start_town()
	run._update_feats()
	return run


## A fresh run with every logged action applied again.
static func replay(seed_value: String, deck: String, stake_level: int, actions: Array,
		challenge_id := "", locked_ids: Array = []) -> RunState:
	var run := create(seed_value, deck, stake_level, challenge_id, locked_ids)
	for action in actions:
		var result := run.apply(action)
		if not result["ok"]:
			push_error("Replay stopped at %s: %s" % [action, result["error"]])
			break
	return run


# --- randomness, stats, hooks ---

## The named random stream, created from the seed on first use.
func rng(stream: String) -> ZRng:
	if not _rngs.has(stream):
		_rngs[stream] = ZRng.new(ZRng.hash_string(seed_text + ("/preview/" if previewing else "/") + stream))
	return _rngs[stream]


## What playing these cards would score right now, worked out on a copy of the run. Luck
## isn't counted (no chance comes up, and random amounts come from other streams), so a
## preview never gives away the run's rolls. -1 when the cards can't be played.
func preview(ids: Array) -> float:
	if phase != Phase.IN_SHOW or hands_left <= 0 or not _forced_included(ids):
		return -1.0
	var copy := RunState.from_dict(to_dict())
	copy.previewing = true
	copy._rngs.clear()
	var played := copy._take_from_hand(ids)
	if played.is_empty():
		return -1.0
	var held: Array[PlayingCard] = copy.hand.duplicate()
	return Scorer.score(copy, played, held).total


## A rule value after every deck, stake, warrant, zanni and patron has adjusted it.
func stat(name: String) -> int:
	return _stat_from(_sources(), name)


func _stat_from(sources: Array, name: String) -> int:
	var value := int(BASE_STATS.get(name, 0)) + int(stat_mods.get(name, 0))
	for src in sources:
		var def: ContentDef = src[0]
		if def.has_hook("modify_stat"):
			value = int(def.fire("modify_stat", [self, src[1], name, value]))
	return value


## Fires one owned Jester's hook as hook(subject, item, ...extra). A copier fires its
## target's hook instead (for COPYABLE hooks), with the target's state and its own label.
func fire_item(item: ItemCard, hook: String, subject: Object, extra := []) -> Variant:
	var def := item.def()
	if def == null:
		return null
	if not def.data.has("copies"):
		return def.fire(hook, [subject, item] + extra)
	if not COPYABLE.has(hook):
		return null
	var target := copy_target(item)
	if target == null:
		return null
	var outer := _copy_label
	if outer == "":
		_copy_label = item_source(item)
	var result: Variant = target.def().fire(hook, [subject, target] + extra)
	_copy_label = outer
	return result


## The Jester whose effect a copier borrows, following chains of copiers; null if none.
func copy_target(item: ItemCard) -> ItemCard:
	var current := item
	for step in zanni.size():
		var how := str(current.def().data.get("copies", ""))
		if how == "":
			return current if current != item else null
		var i := zanni.find(current)
		var j := i + 1 if how == "right" else 0
		if j < 0 or j >= zanni.size() or j == i:
			return null
		current = zanni[j]
		if current.debuffed or current == item:
			return null
	return null


## Calls `hook` on every source in firing order, as hook(subject, item, ...extra).
func fire_all(hook: String, subject: Object, extra := []) -> void:
	for src in _sources():
		var def: ContentDef = src[0]
		if def.has_hook(hook):
			def.fire(hook, [subject, src[1]] + extra)


## An "N in M" chance from the named stream, scaled by the luck stat (never, in a preview).
func roll(stream: String, numerator: int, denominator: int) -> bool:
	if previewing:
		return false
	return rng(stream).chance(minf(1.0, float(numerator * stat("luck")) / denominator))


## Fires `hook` on a playing card's enhancement, edition and seal, as hook(subject, null, card).
## Returns the sum of any integer results.
func fire_card_mods(hook: String, subject: Object, card: PlayingCard) -> int:
	var total := 0
	for mod_id in [card.enhancement, card.edition, card.seal]:
		var mod := ContentDB.get_def(mod_id)
		if mod != null and mod.has_hook(hook):
			var v: Variant = mod.fire(hook, [subject, null, card])
			if v is int:
				total += v
	return total


## Free consumable slots, counting `using` as already gone (a card frees its slot when used).
func free_consumable_slots(using: ItemCard = null) -> int:
	var taken := consumables.size()
	if using != null and consumables.has(using):
		taken -= 1
	return stat("consumable_slots") - taken


## Adds a Tarocchi, Sign or Omen if there's room; false when the slots are full.
func create_consumable(def_id: String) -> bool:
	var def := ContentDB.get_def(def_id)
	if def == null or free_consumable_slots() <= 0:
		return false
	consumables.append(ItemCard.make(def_id, def.cost))
	return true


## Adds a zanni if there's a free slot; false otherwise.
func add_zanni(def_id: String, edition := "") -> bool:
	var def := ContentDB.get_def(def_id)
	if def == null:
		return false
	var item := ItemCard.make(def_id, def.cost, edition)
	if zanni.size() >= stat("zanni_slots") and not _takes_no_slot(item):
		return false
	_join(item)
	return true


## A Jester joins the troupe: challenge stickers apply, and the collection sees it.
func _join(item: ItemCard) -> void:
	if stat("all_eternal") > 0:
		item.state["eternal"] = true
	if stat("all_perishable") > 0:
		item.state["perish"] = PERISH_SHOWS
	if stat("all_rented") > 0:
		item.state["rented"] = true
	zanni.append(item)
	see(item.def_id)


## Marks a card as seen this run (for the collection's discovery count).
func see(def_id: String) -> void:
	if def_id != "":
		seen[def_id] = true


## A random zanni the shop could offer (rarity-weighted), or null.
func random_zanni_def(stream: String) -> ContentDef:
	var pool := _shop_pool("zanni")
	if pool.is_empty():
		return null
	var r := rng(stream)
	var picked := _pick_rarity(pool, r)
	return picked[r.below(picked.size())]


## Removes a playing card from the run for good.
func destroy_card(card: PlayingCard) -> void:
	full_deck.erase(card)
	hand.erase(card)
	draw_pile.erase(card)
	discard_pile.erase(card)
	_count("cards_destroyed")
	fire_all("card_destroyed", self, [card])


func count_retriggers(ctx: ScoreContext, card: PlayingCard, hook: String) -> int:
	var total := 0
	var seal := ContentDB.get_def(card.seal)
	if seal != null and seal.has_hook(hook):
		total += int(seal.fire(hook, [ctx, null, card]))
	for item in zanni:
		if not item.debuffed:
			var extra: Variant = fire_item(item, hook, ctx, [card])
			if extra != null:
				total += int(extra)
	return total


## A face card by this run's rules: a printed J/Q/K, or any ranked card while all_faces is on.
func is_face(card: PlayingCard) -> bool:
	return card.is_face() or (card.has_rank() and stat("all_faces") > 0)


func eval_options() -> Dictionary:
	return {
		"flush_min": stat("flush_min"),
		"straight_min": stat("straight_min"),
		"straight_gap": stat("straight_gap") > 0,
		"all_score": stat("all_score") > 0,
	}


## Label used in score events, e.g. "zanni:z_arlecchino#2" (the copier's, while it copies).
func item_source(item: ItemCard) -> String:
	if _copy_label != "":
		return _copy_label
	return "zanni:%s#%d" % [item.def_id, zanni.find(item)]


func add_card(rank: int, suit: int) -> PlayingCard:
	var card := PlayingCard.make(_next_card_id, rank, suit)
	_next_card_id += 1
	full_deck.append(card)
	return card


## Adds a card described as {rank, suit, enh, ed, seal} (shop and pack cards).
func add_card_from(desc: Dictionary) -> PlayingCard:
	var card := add_card(int(desc["rank"]), int(desc["suit"]))
	card.enhancement = str(desc.get("enh", ""))
	card.edition = str(desc.get("ed", ""))
	card.seal = str(desc.get("seal", ""))
	return card


## Adds a copy of `original` to the deck (same rank, suit, enhancement, edition, seal, bonus).
func copy_card(original: PlayingCard) -> PlayingCard:
	var card := add_card(original.rank, original.suit)
	card.enhancement = original.enhancement
	card.edition = original.edition
	card.seal = original.seal
	card.bonus_points = original.bonus_points
	return card


func target_for_show(index: int) -> float:
	var factor: float = Shows.SIZE[index]
	if index == Shows.PATRON:
		var patron := ContentDB.get_def(town_patron)
		if patron != null:
			factor = float(patron.data.get("target_mult", factor))
		factor *= stat("patron_target_pct") / 100.0
	factor *= stat("target_pct") / 100.0
	return floorf(Shows.base_target(town, stat("target_scaling")) * factor)


## The Patron whose whim rules the current show: the town's on its third show, or the one
## drawn for this show when every show is a Patron show; "" for none.
func current_patron() -> String:
	if show_index == Shows.PATRON:
		return town_patron
	return str(show_counters.get("patron", ""))


## Everything that can react to the run, in firing order: deck, challenge, stakes, warrants,
## zanni (each followed by its edition), consumables' editions, pending favors, then the
## current patron while its show is on, unless the sources before it mute patrons.
func _sources() -> Array:
	var out := []
	var deck_def := ContentDB.get_def(deck_id)
	if deck_def != null:
		out.append([deck_def, null])
	var challenge_def := ContentDB.get_def(challenge)
	if challenge_def != null:
		out.append([challenge_def, null])
	for d in ContentDB.pool("stake"):
		if int(d.data.get("level", 0)) <= stake:
			out.append([d, null])
	for w in warrants:
		var d := ContentDB.get_def(w)
		if d != null:
			out.append([d, null])
	for item in zanni:
		if item.debuffed:
			continue
		var d := item.def()
		if d != null:
			out.append([d, item])
		var ed := ContentDB.get_def(item.edition)
		if ed != null:
			out.append([ed, item])
	for item in consumables:
		var ed := ContentDB.get_def(item.edition)
		if ed != null:
			out.append([ed, item])
	for f in favors:
		var d := ContentDB.get_def(f)
		if d != null:
			out.append([d, null])
	var muted := _stat_from(out, "patron_muted") > 0 or int(show_counters.get("patron_muted", 0)) > 0
	if phase == Phase.IN_SHOW and not muted:
		var p := ContentDB.get_def(current_patron())
		if p != null:
			out.append([p, null])
	return out


# --- actions ---

func apply(action: Dictionary) -> Dictionary:
	var a := _normalize(action)
	var result: Dictionary
	match a["a"]:
		"select_show":
			result = _select_show()
		"skip_show":
			result = _skip_show()
		"play":
			result = _play(a.get("cards", []))
		"discard":
			result = _discard(a.get("cards", []))
		"cash_out":
			result = _cash_out()
		"buy":
			result = _buy(int(a.get("slot", -1)))
		"sell":
			result = _sell(str(a.get("zone", "zanni")), int(a.get("index", -1)))
		"reroll":
			result = _reroll()
		"use":
			result = _use(int(a.get("index", -1)), a.get("cards", []))
		"reorder_zanni":
			result = _reorder_zanni(a.get("order", []))
		"leave_shop":
			result = _leave_shop()
		"buy_pack":
			result = _buy_pack(int(a.get("slot", -1)))
		"pick":
			result = _pick(int(a.get("index", -1)), a.get("cards", []))
		"skip_pack":
			result = _close_pack() if phase == Phase.PACK else _fail("no pack is open")
		"buy_warrant":
			result = _buy_warrant(int(a.get("index", 0)))
		"swap_patron":
			result = _swap_patron()
		_:
			result = _fail("unknown action")
	if result["ok"]:
		action_log.append(a)
		_update_feats()
	return result


## Feats read from the run's state (the event feats are set where they happen). The
## profile turns feats into unlocks when the run ends (Unlocks).
func _update_feats() -> void:
	if zanni.size() >= 5:
		feats["jesters_5"] = true
	if zanni.size() >= 6:
		feats["jesters_6"] = true
	if ducats >= 50:
		feats["ducats_50"] = true
	if won:
		feats["won_run"] = true
	if int(counters.get("patrons_beaten", 0)) >= 8:
		feats["patrons_8"] = true
	if int(counters.get("used_sign", 0)) >= 20:
		feats["signs_20"] = true
	var every_hand := true
	for hand in HandTable.ORDER:
		if hand_levels.level(hand) >= 5:
			feats["level_5"] = true
		if not HandTable.SECRET.has(hand) and hand_levels.times_played(hand) == 0:
			every_hand = false
	if every_hand:
		feats["all_hands"] = true
	var enhanced := 0
	var shining := 0
	for card in full_deck:
		if card.enhancement != "":
			enhanced += 1
		if card.edition != "":
			shining += 1
	if enhanced >= 10:
		feats["enhanced_10"] = true
	if shining >= 3:
		feats["editions_3"] = true


func _select_show() -> Dictionary:
	if phase != Phase.CHOOSE_SHOW:
		return _fail("not choosing a show")
	phase = Phase.IN_SHOW
	show_score = 0.0
	show_counters = {"hands_played": 0, "discards_used": 0, "types": []}
	for card in full_deck:
		card.debuffed = false
		card.face_down = false
	for item in zanni:
		item.debuffed = bool(item.state.get("perished", false))
		item.face_down = false
	if show_index < Shows.PATRON and stat("all_patrons") > 0:
		var pool := _patron_pool().filter(func(d: ContentDef) -> bool: return not bool(d.data.get("finale", false)))
		if not pool.is_empty():
			show_counters["patron"] = pool[rng("patron").below(pool.size())].id
	show_target = target_for_show(show_index)
	hands_left = stat("hands")
	discards_left = stat("discards")
	draw_pile = full_deck.duplicate()
	hand.clear()
	discard_pile.clear()
	rng("deck").shuffle(draw_pile)
	fire_all("show_start", self)
	_draw_to_full()
	return _ok({"target": show_target})


func _skip_show() -> Dictionary:
	if phase != Phase.CHOOSE_SHOW:
		return _fail("not choosing a show")
	if show_index >= Shows.PATRON:
		return _fail("the patron's show can't be skipped")
	var favor := town_favors[show_index]
	var note := town_favor_notes[show_index]
	_count("skips")
	fire_all("skip", self)
	_advance_show()
	if favor != "":
		var times := 1
		if favor != FAVOR_TWIN and favors.has(FAVOR_TWIN):
			favors.erase(FAVOR_TWIN)
			times = 2
		for i in times:
			gain_favor(favor, note)
	return _ok({"favor": favor})


## Takes a Favor: its "gain" hook acts at once, and a Favor with data "pending" waits in
## `favors` until its own hooks use it up. `note` is what it named when offered (a hand).
func gain_favor(def_id: String, note := "") -> void:
	var def := ContentDB.get_def(def_id)
	if def == null:
		return
	if bool(def.data.get("pending", false)):
		favors.append(def_id)
	favor_note = note
	def.fire("gain", [self, null])
	favor_note = ""


func _play(ids: Array) -> Dictionary:
	if phase != Phase.IN_SHOW:
		return _fail("not in a show")
	if hands_left <= 0:
		return _fail("no hands left")
	if not _forced_included(ids):
		return _fail("the selected card must be played or discarded")
	var played := _take_from_hand(ids)
	if played.is_empty():
		return _fail("pick 1 to %d cards from your hand" % stat("max_play"))
	var held: Array[PlayingCard] = hand.duplicate()
	var ctx := Scorer.score(self, played, held)
	hands_left -= 1
	show_score += ctx.total
	show_counters["hands_played"] = int(show_counters["hands_played"]) + 1
	(show_counters["types"] as Array).append(ctx.hand_type)
	_count("hands_played")
	counters["best_hand"] = maxf(float(counters.get("best_hand", 0.0)), ctx.total)
	counters["last_hand"] = ctx.hand_type
	for card in played:
		town_played[card.id] = true
		card.face_down = false
	for card in ctx.destroyed:
		destroy_card(card)
	for card in played:
		if not ctx.destroyed.has(card):
			discard_pile.append(card)
	_hand_feats(ctx)
	fire_all("hand_played", self, [played])
	if show_score >= show_target:
		_win_show()
	elif hands_left == 0:
		_lose_or_rescue()
	else:
		_draw_to_full(true)
		if hand.is_empty():
			_lose_or_rescue()
	return _ok(ctx.summary())


## False when a card the run forces you to use (show_counters "forced") is in hand but
## not among `ids`.
func _forced_included(ids: Array) -> bool:
	var forced := int(show_counters.get("forced", -1))
	if forced < 0 or _hand_card(forced) == null:
		return true
	for raw in ids:
		if int(raw) == forced:
			return true
	return false


## False when a "allows" hook (e.g. a Patron's rule) refuses the hand being scored.
func hand_allowed(ctx: ScoreContext) -> bool:
	for src in _sources():
		var def: ContentDef = src[0]
		if def.has_hook("allows") and not bool(def.fire("allows", [ctx, src[1]])):
			return false
	return true


## The show is lost unless a Jester's "rescue" hook saves it (that Jester is used up);
## a rescued show passes without its show reward.
func _lose_or_rescue() -> void:
	for item in zanni:
		if item.debuffed:
			continue
		# Most Jesters have no rescue hook and answer null, which isn't a "yes".
		var saves: Variant = item.fire("rescue", [self, item])
		if saves is bool and saves:
			zanni.erase(item)
			_count("rescued")
			_win_show(true)
			return
	phase = Phase.LOST
	if show_index == Shows.PATRON:
		feats["lost_to_patron"] = true


func _hand_feats(ctx: ScoreContext) -> void:
	if ctx.points > 1000.0:
		feats["points_1000"] = true
	if ctx.has(HandTable.FLUSH):
		feats["played_flush"] = true
	if ctx.hand_type == HandTable.STRAIGHT_FLUSH:
		feats["played_straight_flush"] = true
	for i in ctx.played.size():
		var a := ctx.played[i]
		for j in range(i + 1, ctx.played.size()):
			var b := ctx.played[j]
			if a.has_rank() and b.has_rank() and a.rank == b.rank and a.suit == b.suit:
				feats["identical_cards"] = true


func _discard(ids: Array) -> Dictionary:
	if phase != Phase.IN_SHOW:
		return _fail("not in a show")
	var free := ids.size() == 1 and int(show_counters.get("free_singles", 0)) < stat("free_single_discards")
	if discards_left <= 0 and not free:
		return _fail("no discards left")
	if not _forced_included(ids):
		return _fail("the selected card must be played or discarded")
	var cards := _take_from_hand(ids)
	if cards.is_empty():
		return _fail("pick 1 to %d cards from your hand" % stat("max_play"))
	discard_pile.append_array(cards)
	if free:
		show_counters["free_singles"] = int(show_counters.get("free_singles", 0)) + 1
	else:
		discards_left -= 1
	show_counters["discards_used"] = int(show_counters["discards_used"]) + 1
	_count("discards_used")
	for card in cards:
		card.face_down = false
		fire_card_mods("discarded", self, card)
	fire_all("discard", self, [cards])
	_draw_to_full(true)
	return _ok({})


func _cash_out() -> Dictionary:
	if phase != Phase.CASH_OUT:
		return _fail("nothing to cash out")
	var total := 0
	for p in payout:
		total += int(p["v"])
	ducats += total
	payout.clear()
	fire_all("cash_out", self)
	phase = Phase.SHOP
	shop = ShopState.new()
	shop.reroll_cost = stat("reroll_base")
	_fill_shop()
	shop.packs = PackMaker.roll_shop_packs(self)
	fire_all("shop_enter", self)
	return _ok({"ducats": total})


func _buy(slot: int) -> Dictionary:
	if phase != Phase.SHOP:
		return _fail("the shop is closed")
	if slot < 0 or slot >= shop.offers.size():
		return _fail("no such offer")
	var offer := shop.offers[slot]
	if offer["sold"]:
		return _fail("already sold")
	var cost := offer_price(offer)
	if ducats - cost < -stat("debt_limit"):
		return _fail("not enough ducats")
	if offer["kind"] == "card":
		ducats -= cost
		offer["sold"] = true
		_count("purchases")
		fire_all("buy", self, [ItemCard.make("", cost)])
		add_card_from(offer["card"])
		return _ok({})
	var item := ItemCard.make(offer["id"], cost, offer["edition"])
	var is_zanni: bool = offer["kind"] == "zanni"
	if is_zanni and zanni.size() >= stat("zanni_slots") and not _takes_no_slot(item):
		return _fail("no free zanni slot")
	if not is_zanni and consumables.size() >= stat("consumable_slots") and not _takes_no_slot(item):
		return _fail("no free consumable slot")
	ducats -= cost
	offer["sold"] = true
	_count("purchases")
	# Owned cards react first, so a new card never reacts to its own purchase.
	fire_all("buy", self, [item])
	if offer.get("sticker", "") == "eternal":
		item.state["eternal"] = true
	elif offer.get("sticker", "") == "perishable":
		item.state["perish"] = PERISH_SHOWS
	if bool(offer.get("rented", false)):
		item.state["rented"] = true
	if is_zanni:
		_join(item)
	else:
		consumables.append(item)
		see(item.def_id)
	return _ok({})


func _sell(zone: String, index: int) -> Dictionary:
	if phase == Phase.CASH_OUT or phase == Phase.LOST:
		return _fail("can't sell now")
	var list: Array[ItemCard] = zanni if zone == "zanni" else consumables
	if index < 0 or index >= list.size():
		return _fail("no such card")
	var item := list[index]
	if bool(item.state.get("eternal", false)):
		return _fail("this card can't be sold")
	var value := item.sell_value()
	list.remove_at(index)
	ducats += value
	_count("sold")
	item.fire("sold", [self, item])
	fire_all("sell", self, [item])
	return _ok({"ducats": value})


## What an offer or pack costs right now: 0 if a Favor made it free, otherwise after shop
## discounts and never below 1.
func offer_price(offer: Dictionary) -> int:
	if bool(offer.get("free", false)):
		return 0
	var cost := int(offer["cost"]) * (100 - stat("shop_discount_pct")) / 100
	return maxi(1, cost - stat("shop_discount"))


## What the next reroll costs: free while free rerolls remain in this shop.
func reroll_price() -> int:
	if shop.rerolls < stat("free_rerolls"):
		return 0
	return maxi(0, shop.reroll_cost - stat("reroll_discount"))


## Changes a stat for the rest of the run, e.g. an Omen's "−1 card in hand".
func change_stat_for_run(name: String, amount: int) -> void:
	stat_mods[name] = int(stat_mods.get(name, 0)) + amount


func _reroll() -> Dictionary:
	if phase != Phase.SHOP:
		return _fail("the shop is closed")
	var cost := reroll_price()
	if ducats - cost < -stat("debt_limit"):
		return _fail("not enough ducats")
	# A free reroll leaves the price as it was; any other one raises it, even from 0.
	var was_free := shop.rerolls < stat("free_rerolls")
	ducats -= cost
	shop.rerolls += 1
	if not was_free:
		shop.reroll_cost += 1
	_count("rerolls")
	_fill_shop()
	fire_all("reroll", self)
	return _ok({})


func _use(index: int, ids: Array) -> Dictionary:
	if phase == Phase.CASH_OUT or phase == Phase.LOST:
		return _fail("can't use cards now")
	if index < 0 or index >= consumables.size():
		return _fail("no such card")
	var item := consumables[index]
	var def := item.def()
	if def == null:
		return _fail("unknown card")
	var targets: Array[PlayingCard] = []
	for raw in ids:
		var card := _hand_card(int(raw))
		if card == null:
			return _fail("targets must be cards in your hand")
		targets.append(card)
	if def.has_hook("can_use") and not bool(def.fire("can_use", [self, item, targets])):
		return _fail("can't use that here")
	consumables.remove_at(index)
	def.fire("on_use", [self, item, targets])
	_count("used_" + def.kind)
	fire_all("use", self, [item])
	return _ok({})


func _reorder_zanni(order: Array) -> Dictionary:
	if order.size() != zanni.size():
		return _fail("order must list every zanni")
	var seen := {}
	var next_list: Array[ItemCard] = []
	for raw in order:
		var i := int(raw)
		if i < 0 or i >= zanni.size() or seen.has(i):
			return _fail("bad order")
		seen[i] = true
		next_list.append(zanni[i])
	zanni = next_list
	return _ok({})


## Buying a pack opens it at once; Tarocchi and Omen packs deal a hand from the deck to
## use them on.
func _buy_pack(slot: int) -> Dictionary:
	if phase != Phase.SHOP:
		return _fail("the shop is closed")
	if slot < 0 or slot >= shop.packs.size() or shop.packs[slot]["sold"]:
		return _fail("no such pack")
	var offer := shop.packs[slot]
	var cost := offer_price(offer)
	if ducats - cost < -stat("debt_limit"):
		return _fail("not enough ducats")
	ducats -= cost
	offer["sold"] = true
	_count("purchases")
	fire_all("buy", self, [ItemCard.make(offer["id"], cost)])
	open_pack(offer["id"])
	return _ok({"items": pack["items"].duplicate(true)})


## Opens a pack from the shop or a Favor. Tarocchi and Omen packs deal a hand from the
## deck to use them on; closing the pack returns to the phase it was opened from.
func open_pack(def_id: String) -> void:
	if phase == Phase.PACK:
		pack_queue.append(def_id)
		return
	var def := ContentDB.get_def(def_id)
	_count("packs_opened")
	pack = {"id": def_id, "items": PackMaker.open(self, def), "picks": int(def.data["pick"]), "back": phase}
	hand.clear()
	if def.data["contents"] == "tarocchi" or def.data["contents"] == "omen":
		var deck := full_deck.duplicate()
		rng("pack_hand").shuffle(deck)
		hand.assign(deck.slice(0, stat("hand_size")))
	phase = Phase.PACK


## Takes one card from the open pack. Tarocchi, Signs and Omens are used at once on the
## selected cards; Jesters join the troupe; playing cards join the deck.
func _pick(index: int, ids: Array) -> Dictionary:
	if phase != Phase.PACK:
		return _fail("no pack is open")
	var items: Array = pack["items"]
	if index < 0 or index >= items.size():
		return _fail("no such card in the pack")
	var entry: Dictionary = items[index]
	var kind := str(entry["kind"])
	if kind == "card":
		add_card_from(entry["card"])
	elif kind == "zanni":
		if not add_zanni(entry["id"], str(entry.get("edition", ""))):
			return _fail("no free Jester slot")
	else:
		var item := ItemCard.make(entry["id"], ContentDB.get_def(entry["id"]).cost)
		var targets: Array[PlayingCard] = []
		for raw in ids:
			var card := _hand_card(int(raw))
			if card == null:
				return _fail("targets must be cards in your hand")
			targets.append(card)
		var def := item.def()
		if def.has_hook("can_use") and not bool(def.fire("can_use", [self, item, targets])):
			return _fail("can't use that here")
		def.fire("on_use", [self, item, targets])
		_count("used_" + def.kind)
		fire_all("use", self, [item])
	items.remove_at(index)
	pack["picks"] = int(pack["picks"]) - 1
	if int(pack["picks"]) <= 0 or items.is_empty():
		return _close_pack()
	return _ok({})


func _close_pack() -> Dictionary:
	phase = int(pack.get("back", Phase.SHOP))
	pack = {}
	hand.clear()
	if not pack_queue.is_empty():
		open_pack(pack_queue.pop_front())
	return _ok({})


## Index 0 is the town's Warrant; index 1 the extra one a Favor can add to this shop.
func _buy_warrant(index: int) -> Dictionary:
	if phase != Phase.SHOP:
		return _fail("the shop is closed")
	var on_sale := town_warrant if index == 0 else shop.extra_warrant
	var sold := warrant_bought if index == 0 else shop.extra_bought
	if on_sale == "" or sold:
		return _fail("no Warrant on sale")
	var def := ContentDB.get_def(on_sale)
	if ducats - def.cost < -stat("debt_limit"):
		return _fail("not enough ducats")
	ducats -= def.cost
	if index == 0:
		warrant_bought = true
	else:
		shop.extra_bought = true
	_count("purchases")
	fire_all("buy", self, [ItemCard.make(def.id, def.cost)])
	warrants.append(def.id)
	def.fire("gain", [self, null])
	return _ok({})


## Pays to replace this town's Patron with another (Il Ricatto's Warrants).
func _swap_patron() -> Dictionary:
	if phase == Phase.IN_SHOW or phase == Phase.LOST:
		return _fail("can't swap the Patron now")
	if town_swaps >= stat("patron_swaps"):
		return _fail("no Patron swaps left this town")
	if ducats - PATRON_SWAP_COST < -stat("debt_limit"):
		return _fail("not enough ducats")
	var others := _patron_pool().filter(func(d: ContentDef) -> bool: return d.id != town_patron)
	if others.is_empty():
		return _fail("no other Patron to swap in")
	ducats -= PATRON_SWAP_COST
	town_swaps += 1
	town_patron = others[rng("patron").below(others.size())].id
	return _ok({"patron": town_patron})


func _patron_pool() -> Array[ContentDef]:
	var finale := town % Shows.FINAL_TOWN == 0
	return ContentDB.pool("patron", func(d: ContentDef) -> bool:
		return bool(d.data.get("finale", false)) == finale and int(d.data.get("min_town", 1)) <= town)


## The Warrant offered this town: one not owned yet whose base Warrant, if any, is owned.
func _roll_warrant(exclude := "") -> String:
	var choices := ContentDB.pool("warrant", func(d: ContentDef) -> bool:
		if warrants.has(d.id) or d.id == exclude:
			return false
		var base := str(d.data.get("requires", ""))
		return base == "" or warrants.has(base))
	if choices.is_empty():
		return ""
	return choices[rng("warrant").below(choices.size())].id


func _leave_shop() -> Dictionary:
	if phase != Phase.SHOP:
		return _fail("the shop is closed")
	shop = null
	_advance_show()
	return _ok({})


# --- flow ---

## The challenge's deck if it builds one, else the deck's, else the standard 52.
func _build_deck() -> void:
	full_deck.clear()
	for def_id in [challenge, deck_id]:
		var def := ContentDB.get_def(def_id)
		if def != null and def.has_hook("build"):
			def.fire("build", [self, null])
			return
	for s in 4:
		for r in range(2, 15):
			add_card(r, s)


func _start_town() -> void:
	show_index = Shows.MATINEE
	phase = Phase.CHOOSE_SHOW
	var patrons := _patron_pool()
	town_patron = patrons[rng("patron").below(patrons.size())].id if not patrons.is_empty() else ""
	var favor_pool := ContentDB.pool("favor")
	town_favors = ["", ""]
	town_favor_notes = ["", ""]
	if not favor_pool.is_empty():
		for i in 2:
			var favor: ContentDef = favor_pool[rng("favor").below(favor_pool.size())]
			town_favors[i] = favor.id
			if bool(favor.data.get("names_hand", false)):
				var hands: Array = HandTable.ORDER.filter(func(h: String) -> bool: return hand_levels.is_visible(h))
				town_favor_notes[i] = hands[rng("favor").below(hands.size())]
	town_warrant = _roll_warrant()
	warrant_bought = false
	town_swaps = 0
	town_played = {}


func _advance_show() -> void:
	show_index += 1
	if show_index > Shows.PATRON:
		town += 1
		_start_town()
	else:
		phase = Phase.CHOOSE_SHOW


func _win_show(rescued := false) -> void:
	phase = Phase.CASH_OUT
	if town == Shows.FINAL_TOWN and show_index == Shows.PATRON:
		won = true
	_count("shows_won")
	_count("discards_unused", discards_left)
	if show_index == Shows.PATRON:
		_count("patrons_beaten")
		if int(show_counters.get("hands_played", 0)) == 1:
			feats["patron_first_hand"] = true
	if hands_left == 0:
		feats["won_on_last_hand"] = true
	if zanni.size() == 1:
		feats["won_with_one_jester"] = true
	if zanni.any(func(z: ItemCard) -> bool: return z.def_id == "z_burattinaio"):
		feats["won_with_burattinaio"] = true
	for card in hand:
		fire_card_mods("won_held", self, card)
	fire_all("show_end", self)
	_age_perishables()
	payout = _compute_payout(rescued)


## Perishable Jesters count down one show each win; at 0 they stop working for good.
func _age_perishables() -> void:
	for z in zanni:
		if z.state.has("perish") and not bool(z.state.get("perished", false)):
			z.state["perish"] = int(z.state["perish"]) - 1
			if int(z.state["perish"]) <= 0:
				z.state["perished"] = true
				z.debuffed = true


func _compute_payout(rescued := false) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	var reward := 0 if rescued else stat(REWARD_STATS[show_index])
	if reward > 0 and show_index == Shows.PATRON:
		var patron := ContentDB.get_def(town_patron)
		if patron != null:
			reward += int(patron.data.get("reward_bonus", 0))
	if reward > 0:
		items.append({"src": "show", "v": reward})
	var per_hand := stat("hand_reward")
	if hands_left > 0 and per_hand > 0:
		items.append({"src": "hands", "v": hands_left * per_hand})
	var per_discard := stat("discard_reward")
	if discards_left > 0 and per_discard > 0:
		items.append({"src": "discards", "v": discards_left * per_discard})
	for z in zanni:
		if bool(z.state.get("rented", false)):
			items.append({"src": item_source(z), "v": -RENT})
	var per := stat("interest_per")
	if per > 0 and ducats > 0:
		var interest := mini(floori(float(ducats) / per), stat("interest_cap")) * stat("interest_mult")
		if interest > 0:
			items.append({"src": "interest", "v": interest})
		if interest >= 10:
			feats["interest_10"] = true
	for card in hand:
		var held_pay := fire_card_mods("payout_held", self, card)
		if held_pay != 0:
			items.append({"src": "card:%d" % card.id, "v": held_pay})
	for item in zanni:
		if item.debuffed:
			continue
		var v: Variant = fire_item(item, "payout", self)
		if v != null and int(v) != 0:
			items.append({"src": item_source(item), "v": int(v)})
	return items


## Refills the hand to hand size, or after a play or discard (`after_action`) draws exactly
## draw_exact cards when that's set. "cards_drawn" hooks then see what was drawn.
func _draw_to_full(after_action := false) -> void:
	var drawn: Array[PlayingCard] = []
	var exact := stat("draw_exact")
	if after_action and exact > 0:
		for i in exact:
			if draw_pile.is_empty():
				break
			drawn.append(draw_pile.pop_back())
	else:
		var size := stat("hand_size")
		while hand.size() + drawn.size() < size and not draw_pile.is_empty():
			drawn.append(draw_pile.pop_back())
	hand.append_array(drawn)
	if phase == Phase.IN_SHOW:
		fire_all("cards_drawn", self, [drawn, not after_action])


func _fill_shop() -> void:
	shop.offers.clear()
	for i in stat("shop_slots"):
		var offer := _roll_offer()
		if not offer.is_empty():
			shop.offers.append(offer)


func _roll_offer() -> Dictionary:
	var r := rng("shop")
	var kinds: Array[String] = []
	var weights := []
	for kind: String in SHOP_KIND_WEIGHTS:
		if not _shop_pool(kind).is_empty():
			kinds.append(kind)
			weights.append(_kind_weight(kind))
	if stat("card_rate") > 0:
		kinds.append("card")
		weights.append(stat("card_rate"))
	if stat("omen_rate") > 0 and not _shop_pool("omen").is_empty():
		kinds.append("omen")
		weights.append(stat("omen_rate"))
	var k := r.pick_weighted(weights)
	if k < 0:
		return {}
	var kind := kinds[k]
	if kind == "card":
		var card := PackMaker.random_card(self, r, stat("card_quality") > 0)
		var upgraded: bool = card["enh"] != "" or card["ed"] != "" or card["seal"] != ""
		var price := CARD_PRICE_UPGRADED if upgraded else CARD_PRICE
		return {"kind": "card", "id": "", "card": card, "cost": price, "edition": "", "sold": false}
	var pool := _shop_pool(kind)
	if kind == "zanni":
		pool = _pick_rarity(pool, r)
	var def := pool[r.below(pool.size())]
	var edition: ContentDef = roll_shop_edition() if kind == "zanni" else null
	var cost := def.cost + (int(edition.data.get("extra_cost", 0)) if edition != null else 0)
	var offer := {"kind": kind, "id": def.id, "cost": cost, "edition": edition.id if edition != null else "", "sold": false}
	if kind == "zanni":
		_roll_stickers(offer)
	see(def.id)
	return offer


## Stake stickers on a shop Jester: Eternal (or, once Perishable joins, Eternal or
## Perishable half each) at eternal_pct, and separately Rented at rented_pct (price 1).
func _roll_stickers(offer: Dictionary) -> void:
	var r := rng("sticker")
	var roll := r.next_float() * 100.0
	if roll < stat("eternal_pct"):
		var perishable := stat("perishable_on") > 0 and roll < stat("eternal_pct") / 2.0
		offer["sticker"] = "perishable" if perishable else "eternal"
	if r.next_float() * 100.0 < stat("rented_pct"):
		offer["rented"] = true
		offer["cost"] = 1


func _kind_weight(kind: String) -> float:
	var base := float(SHOP_KIND_WEIGHTS[kind])
	if (kind == "zanni" and stat("jesters_banned") > 0) or (kind == "sign" and stat("signs_banned") > 0):
		return 0.0
	if kind == "tarocchi":
		return base * stat("tarocchi_rate_pct") / 100.0
	if kind == "sign":
		return base * stat("sign_rate_pct") / 100.0
	return base


## Each edition's "shop_chance" (scaled by edition_rate_pct) of shining a zanni; null for a
## plain one.
func roll_shop_edition() -> ContentDef:
	var rate := stat("edition_rate_pct") / 100.0
	var roll := rng("edition").next_float()
	for ed in ContentDB.pool("edition"):
		roll -= float(ed.data.get("shop_chance", 0.0)) * rate
		if roll < 0.0:
			return ed
	return null


## Cards of one kind the shop may offer now: not legendary, available (e.g. a secret hand's
## Sign only once that hand was played), and not already owned or on offer unless the card
## has data "duplicates": true.
func _shop_pool(kind: String) -> Array[ContentDef]:
	var taken := {}
	for item in zanni:
		taken[item.def_id] = true
	if shop != null:
		for offer in shop.offers:
			taken[offer["id"]] = true
	return ContentDB.pool(kind, func(d: ContentDef) -> bool:
		if d.rarity >= 3 or not bool(d.data.get("in_shop", true)) or locked.has(d.id):
			return false
		if bool(d.data.get("rare_omen", false)):
			return false
		if d.has_hook("available") and not bool(d.fire("available", [self, null])):
			return false
		return not taken.has(d.id) or bool(d.data.get("duplicates", false)))


func _pick_rarity(pool: Array[ContentDef], r: ZRng) -> Array[ContentDef]:
	var by_rarity: Array = [[], [], []]
	for d in pool:
		by_rarity[clampi(d.rarity, 0, 2)].append(d)
	var weights := []
	for i in 3:
		weights.append(ZANNI_RARITY_WEIGHTS[i] if not by_rarity[i].is_empty() else 0)
	var picked: Array[ContentDef] = []
	picked.assign(by_rarity[r.pick_weighted(weights)])
	return picked


func _takes_no_slot(item: ItemCard) -> bool:
	var ed := ContentDB.get_def(item.edition)
	return ed != null and bool(ed.data.get("adds_slot", false))


func _take_from_hand(ids: Array) -> Array[PlayingCard]:
	var picked: Array[PlayingCard] = []
	if ids.is_empty() or ids.size() > stat("max_play"):
		return picked
	for raw in ids:
		var card := _hand_card(int(raw))
		if card == null or picked.has(card):
			picked.clear()
			return picked
		picked.append(card)
	for card in picked:
		hand.erase(card)
	return picked


func _hand_card(card_id: int) -> PlayingCard:
	for card in hand:
		if card.id == card_id:
			return card
	return null


func _count(key: String, amount := 1) -> void:
	counters[key] = int(counters.get(key, 0)) + amount


func _ok(extra: Dictionary) -> Dictionary:
	var out := {"ok": true}
	out.merge(extra)
	return out


func _fail(message: String) -> Dictionary:
	return {"ok": false, "error": message}


## Canonical form of an action, so logs survive JSON (where every number becomes a float).
static func _normalize(action: Dictionary) -> Dictionary:
	var a := {"a": str(action.get("a", ""))}
	for key in ["cards", "order"]:
		if action.has(key):
			var ints: Array[int] = []
			for x in action[key]:
				ints.append(int(x))
			a[key] = ints
	for key in ["slot", "index"]:
		if action.has(key):
			a[key] = int(action[key])
	if action.has("zone"):
		a["zone"] = str(action["zone"])
	return a


# --- saving ---

func to_dict() -> Dictionary:
	var rng_states := {}
	for stream in _rngs:
		rng_states[stream] = (_rngs[stream] as ZRng).state
	return clean({
		"v": SAVE_VERSION,
		"seed": seed_text, "deck": deck_id, "stake": stake,
		"phase": phase, "town": town, "show": show_index, "won": won,
		"ducats": ducats,
		"hands": hand_levels.to_dict(),
		"cards": full_deck.map(func(c: PlayingCard) -> Dictionary: return c.to_dict()),
		"draw": _ids(draw_pile), "hand": _ids(hand), "discarded": _ids(discard_pile),
		"zanni": zanni.map(func(i: ItemCard) -> Dictionary: return i.to_dict()),
		"consumables": consumables.map(func(i: ItemCard) -> Dictionary: return i.to_dict()),
		"warrants": warrants.duplicate(), "favors": favors.duplicate(),
		"patron": town_patron, "town_favors": town_favors.duplicate(),
		"warrant": town_warrant, "warrant_bought": warrant_bought, "swaps": town_swaps,
		"pack": pack.duplicate(true), "pack_queue": pack_queue.duplicate(), "stat_mods": stat_mods.duplicate(),
		"favor_notes": town_favor_notes.duplicate(), "town_played": town_played.keys(),
		"challenge": challenge, "locked": locked.keys(), "seen": seen.keys(), "feats": feats.keys(),
		"hands_left": hands_left, "discards_left": discards_left,
		"score": show_score, "target": show_target,
		"shop": shop.to_dict() if shop != null else null,
		"payout": payout.duplicate(true),
		"counters": counters.duplicate(true), "show_counters": show_counters.duplicate(true),
		"rng": rng_states, "next_id": _next_card_id,
		"log": action_log.duplicate(true),
	})


static func from_dict(d: Dictionary) -> RunState:
	var run := RunState.new()
	run.seed_text = str(d["seed"])
	run.deck_id = str(d["deck"])
	run.stake = int(d["stake"])
	run.phase = int(d["phase"])
	run.town = int(d["town"])
	run.show_index = int(d["show"])
	run.won = bool(d["won"])
	run.ducats = int(d["ducats"])
	run.hand_levels = HandLevels.from_dict(d["hands"])
	var by_id := {}
	for cd in d["cards"]:
		var card := PlayingCard.from_dict(cd)
		run.full_deck.append(card)
		by_id[card.id] = card
	for cid in d["draw"]:
		run.draw_pile.append(by_id[int(cid)])
	for cid in d["hand"]:
		run.hand.append(by_id[int(cid)])
	for cid in d["discarded"]:
		run.discard_pile.append(by_id[int(cid)])
	for z in d["zanni"]:
		run.zanni.append(ItemCard.from_dict(z))
	for c in d["consumables"]:
		run.consumables.append(ItemCard.from_dict(c))
	for w in d["warrants"]:
		run.warrants.append(str(w))
	for f in d["favors"]:
		run.favors.append(str(f))
	run.town_patron = str(d["patron"])
	run.town_favors = [str(d["town_favors"][0]), str(d["town_favors"][1])]
	run.town_warrant = str(d.get("warrant", ""))
	run.warrant_bought = bool(d.get("warrant_bought", false))
	run.town_swaps = int(d.get("swaps", 0))
	run.pack = (d.get("pack", {}) as Dictionary).duplicate(true)
	for queued in d.get("pack_queue", []):
		run.pack_queue.append(str(queued))
	for key in d.get("stat_mods", {}):
		run.stat_mods[str(key)] = int(d["stat_mods"][key])
	var notes: Array = d.get("favor_notes", ["", ""])
	run.town_favor_notes = [str(notes[0]), str(notes[1])]
	for cid in d.get("town_played", []):
		run.town_played[int(cid)] = true
	run.challenge = str(d.get("challenge", ""))
	for key in d.get("locked", []):
		run.locked[str(key)] = true
	for key in d.get("seen", []):
		run.seen[str(key)] = true
	for key in d.get("feats", []):
		run.feats[str(key)] = true
	run.hands_left = int(d["hands_left"])
	run.discards_left = int(d["discards_left"])
	run.show_score = float(d["score"])
	run.show_target = float(d["target"])
	run.shop = ShopState.from_dict(d["shop"]) if d["shop"] != null else null
	for p in d["payout"]:
		run.payout.append({"src": str(p["src"]), "v": int(p["v"])})
	run.counters = (d["counters"] as Dictionary).duplicate(true)
	run.show_counters = (d["show_counters"] as Dictionary).duplicate(true)
	for stream in d["rng"]:
		run._rngs[stream] = ZRng.new(int(d["rng"][stream]))
	run._next_card_id = int(d["next_id"])
	for a in d["log"]:
		run.action_log.append(_normalize(a))
	return run


static func _ids(cards: Array[PlayingCard]) -> Array:
	return cards.map(func(c: PlayingCard) -> int: return c.id)


## JSON-safe copy with whole-number floats turned into ints, so a save survives
## JSON.stringify → JSON.parse_string → from_dict → to_dict unchanged.
static func clean(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			var out := {}
			for k in value:
				out[str(k)] = clean(value[k])
			return out
		TYPE_ARRAY:
			var arr := []
			for x in value:
				arr.append(clean(x))
			return arr
		TYPE_FLOAT:
			var f: float = value
			if is_finite(f) and f == floorf(f) and absf(f) < 9007199254740992.0:
				return int(f)
			return f
		TYPE_STRING_NAME:
			return str(value)
	return value
