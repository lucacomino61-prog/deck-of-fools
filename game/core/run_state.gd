class_name RunState
extends RefCounted
## One run: the whole game state and every rule that changes it.
##
## All randomness comes from named ZRng streams derived from the run seed, and every change
## goes through apply(action). So the seed plus the action log replays a run exactly, which
## is what cloud saves, the daily run and leaderboard checks rely on.
##
## Actions (Dictionaries, "a" = name):
##   select_show {perform} · skip_show · play {cards} · discard {cards} · cash_out
##   buy {slot} · buy_pack {slot} · buy_warrant · sell {zone, index} · reroll
##   use {index, cards} · reorder_zanni {order} · swap_patron · leave_shop
##   merge {index, other}                   (two Jesters of a duo become its Lazzo)
##   pick {index, cards} · skip_pack        (while a pack is open)
##   travel {index, slot}                   (on the map: the next city, and its choice if any)
##   encore · bow · play {cards}            (when the crowd demands an Encore)
##   swap_scenario                          (the prop Il Suggeritore: another Scenario)
##
## Batch 12 (the tour) only runs on a city deck, which gives the run a route: the Map of
## Italy, the city twists, Scenarios, the crowd's mood and the Encore. A run on any other
## deck (the rules tests' stand-in) plays the classic rules.
##
## Batch 13 (progression) comes in through `extras`, what the player's profile brings to a
## normal or campaign run: Maestri, the carried props, the nemesis, the campaign chapter and
## the Jester carried into it, and the rematch. Daily, seeded and challenge runs get none,
## so they play the same for everyone. Fame earned this run is counted here for the profile.

## PACK, MAP and ENCORE were added last so saved phase numbers keep their meaning.
enum Phase { CHOOSE_SHOW, IN_SHOW, CASH_OUT, SHOP, LOST, PACK, MAP, ENCORE }

const PATRON_SWAP_COST := 10
## Il Gemello: the Favor that doubles the next one you take.
const FAVOR_TWIN := "f_gemello"
## Stake stickers: a Perishable Jester lasts this many won shows; a Rented one costs 1 to
## buy and RENT at every cash-out.
const PERISH_SHOWS := 5
const RENT := 3

## The crowd (batch 12): mood runs 0–10 and starts each show at 5. At 10 the next hand
## gets ×1.5 Mult and the mood drops to 7; at 0 the show pays 3 ducats less. Winning with
## mood 8 or more brings an Encore: one more hand against half the target, which doubles
## the cash-out or loses the show's reward.
const MOOD_START := 5
const MOOD_MAX := 10
const OVATION_XMULT := 1.5
const OVATION_AFTER := 7
const WALKOUT_DUCATS := 3
const ENCORE_MOOD := 8
const ENCORE_SHARE := 0.5

## Patron rivalry (batch 13): in towns 5–7 a Patron beaten earlier in the run comes back,
## 1 in 5, at most once a run, with its target ×1.25 and its reward doubled. Beating your
## nemesis (the Patron that ended your last run) pays NEMESIS_DUCATS.
const REMATCH_CHANCE := 0.2
const REMATCH_TOWNS := [5, 6, 7]
const REMATCH_TARGET := 1.25
const REMATCH_REWARD := 2
const NEMESIS_DUCATS := 10

## 4: the Gala made the Patron the fourth show (2026-10-28); older saves are moved along.
const SAVE_VERSION := 4

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
	"reward_gala": 4,
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
	## City twists and shop leans (batch 12).
	## What a card sells for, in percent of normal.
	"sell_pct": 100,
	## Ducats off every booster pack, and off the Warrant.
	"pack_discount": 0,
	"warrant_discount": 0,
	## How often Jesters fill shop slots, and how often a shop Jester is rare, in percent.
	"zanni_rate_pct": 100,
	"rare_rate_pct": 100,
	## Shop weight of each kind of booster pack, in percent of normal.
	"pack_tarocchi_pct": 100,
	"pack_sign_pct": 100,
	"pack_card_pct": 100,
	"pack_zanni_pct": 100,
	"pack_omen_pct": 100,
	## Above 0, half the playing cards from packs and the shop are Hearts.
	"pack_hearts": 0,
	## Above 0, Jesters fire right to left.
	"reverse_jesters": 0,
	## Gilt cards' ducats are multiplied by this.
	"gilt_mult": 1,
	## Wagon props and campaign chapters (batch 13).
	## The crowd's mood when a show starts.
	"mood_start": MOOD_START,
	## Scenario swaps allowed per town.
	"scenario_swaps": 0,
	## Ducats off the first reroll in each shop.
	"first_reroll_discount": 0,
	## Extra Jesters offered in the run's first shop.
	"first_shop_jesters": 0,
	## Above 0, every booster pack also holds an enhanced playing card.
	"pack_enhanced_card": 0,
}

## Hooks a copying Jester (data "copies": "right" or "leftmost") borrows from its target.
## Growth hooks (buy, sell, skip…) and stat changes are never copied.
const COPYABLE := ["independent", "card_scored", "card_held", "retrigger_scored", "retrigger_held", "payout"]

const REWARD_STATS := ["reward_matinee", "reward_evening", "reward_gala", "reward_patron"]

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
var town_favors: Array[String] = ["", "", ""]
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
var town_favor_notes: Array[String] = ["", "", ""]
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

## The tour (batch 12). On when the deck has a home city.
var tour := false
## How many towns the tour has before it's won: 8, or 16 on a Grand Tour (2026-10-28).
var towns := Shows.FINAL_TOWN
## The Map of Italy: one row per town, each a list of {city, to: [columns in the next row]}.
var route: Array = []
## Where the troupe is: its row on the route and column in it, the city, and the option
## chosen on arrival in a city that asks for one (Messina). The row only moves forward,
## even when a card sends the town number back (La Clessidra).
var route_row := 0
var route_col := 0
## The column the troupe took in each row so far (the first is home).
var path: Array[int] = []
var city := ""
var town_option := 0
## This show's Scenario, whether it's being performed, and the next beat (0–2).
var scenario := ""
var scenario_on := false
var scenario_beat := 0
## The crowd's mood (0–10) and a standing ovation waiting for the next hand.
var mood := MOOD_START
var ovation := false
## While a duo or a Maestro fires: how much its numbers grow; and whether a duo's parts are
## firing (a Maestro inside a duo grows by the duo's rule only).
var duo_scale := 1.0
var duo_item: ItemCard = null
var _in_duo := false

## Batch 13: what the profile brought ({maestri, props, nemesis, chapter, carry, rivalry}),
## and the parts of it the rules read often.
var extras: Dictionary = {}
var maestri: Dictionary = {}
var props: Array[String] = []
var chapter := ""
## Patrons beaten this run, and the rematch drawn for a later town ({town, patron}).
var beaten: Array[String] = []
var rematch: Dictionary = {}
## Fame each Jester earned this run (def id → fame), handed to the profile at the end.
var fame: Dictionary = {}
## Scenario swaps used in this town (Il Suggeritore).
var town_scenario_swaps := 0


## A new run. `challenge_id` sets up a challenge run; `locked_ids` are the cards the
## player's profile hasn't unlocked yet, which never turn up in this run; `run_extras` is
## what the profile brings (batch 13; Profile.extras_for).
static func create(seed_value: String, deck := "standard", stake_level := 1, challenge_id := "",
		locked_ids: Array = [], run_extras := {}, tour_towns := Shows.FINAL_TOWN) -> RunState:
	var run := RunState.new()
	run.seed_text = seed_value
	run.towns = tour_towns
	run.deck_id = deck
	run.stake = stake_level
	run.challenge = challenge_id
	for id in locked_ids:
		run.locked[str(id)] = true
	run._take_extras(run_extras)
	run._build_deck()
	run._plan_route()
	run.ducats = run.stat("start_ducats")
	run.fire_all("run_start", run)
	run._join_carried()
	run._start_town()
	run._update_feats()
	return run


## A fresh run with every logged action applied again.
static func replay(seed_value: String, deck: String, stake_level: int, actions: Array,
		challenge_id := "", locked_ids: Array = [], run_extras := {}, tour_towns := Shows.FINAL_TOWN) -> RunState:
	var run := create(seed_value, deck, stake_level, challenge_id, locked_ids, run_extras, tour_towns)
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
	return float(preview_detail(ids).get("total", -1.0))


## The preview's whole scoring summary (total, hand, events with their sources: what each
## card and Jester adds); empty when the cards can't be played.
func preview_detail(ids: Array) -> Dictionary:
	var encore_live: bool = phase == Phase.ENCORE and show_counters.get("encore", "") == "live"
	if not encore_live and (phase != Phase.IN_SHOW or hands_left <= 0 or not _forced_included(ids)):
		return {}
	var copy := _preview_copy()
	var played := copy._take_from_hand(ids)
	if played.is_empty():
		return {}
	var held: Array[PlayingCard] = copy.hand.duplicate()
	return Scorer.score(copy, played, held).summary()


## What the Jester at `index` adds on its own right now (its value from what it has grown
## or from the run: ducats, the deck, discards left…), as scoring events; it doesn't count
## anything that depends on the cards played.
func jester_now(index: int) -> Array:
	if index < 0 or index >= zanni.size() or zanni[index].debuffed:
		return []
	var copy := _preview_copy()
	var ctx := ScoreContext.new()
	ctx.run = copy
	ctx.held.assign(copy.hand)
	copy.fire_item(copy.zanni[index], "independent", ctx)
	return ctx.events


func _preview_copy() -> RunState:
	var copy := RunState.from_dict(to_dict(false))
	copy.previewing = true
	copy._rngs.clear()
	return copy


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
		return _fire(def, hook, [subject, item] + extra, item)
	if not COPYABLE.has(hook):
		return null
	var target := copy_target(item)
	if target == null:
		return null
	var outer := _copy_label
	if outer == "":
		_copy_label = item_source(item)
	var result: Variant = _fire(target.def(), hook, [subject, target] + extra, target)
	_copy_label = outer
	return result


## Fires a source's hook. While a Maestro Jester fires, its numbers grow by Fame.SCALE (the
## duo rule, through duo_scale), and so do the ducats it hands out directly and what it pays
## at cash-out. Inside a duo the duo's own rule applies instead.
func _fire(def: ContentDef, hook: String, args: Array, item: ItemCard) -> Variant:
	if _in_duo or def.kind != "zanni" or not is_maestro(item):
		return def.fire(hook, args)
	var outer := duo_scale
	var before := ducats
	duo_scale = Fame.SCALE
	var result: Variant = def.fire(hook, args)
	duo_scale = outer
	if args[0] is RunState and ducats != before:
		ducats += roundi((ducats - before) * (Fame.SCALE - 1.0))
	if hook == "payout" and result != null and int(result) != 0:
		result = roundi(int(result) * Fame.SCALE)
	return result


## Whether this Jester plays as its Maestro version in this run (a duo never is; its parts
## can be).
func is_maestro(item: ItemCard) -> bool:
	return item != null and item.parts.is_empty() and maestri.has(item.def_id)


## The Jester whose effect a copier borrows, following chains of copiers; null if none.
func copy_target(item: ItemCard) -> ItemCard:
	var current := item
	for step in zanni.size():
		var how := str(current.def().data.get("copies", ""))
		if how == "":
			return current if current != item else null
		var i := position_of(current)
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
			_fire(def, hook, [subject, src[1]] + extra, src[1])


## An "N in M" chance from the named stream, scaled by the luck stat (never, in a preview).
## A duo's Jesters get one step luckier (1 in 3 becomes 1 in 2).
func roll(stream: String, numerator: int, denominator: int) -> bool:
	if previewing:
		return false
	return rng(stream).chance(minf(1.0, float(numerator * stat("luck")) * duo_scale / denominator))


## A Jester's seat in the row; a duo's Jesters sit where the duo does. -1 if not owned.
func position_of(item: ItemCard) -> int:
	var i := zanni.find(item)
	if i >= 0:
		return i
	for j in zanni.size():
		if zanni[j].parts.has(item):
			return j
	return -1


## The owned Jesters in the order they fire: left to right, or right to left where a city
## turns them round (Palermo).
func firing_order() -> Array[ItemCard]:
	if stat("reverse_jesters") <= 0:
		return zanni
	var order: Array[ItemCard] = zanni.duplicate()
	order.reverse()
	return order


## An amount a duo's Jester adds, grown by duo_scale: rounded to `step` from 10 up (Points
## to 5s), else to whole numbers. Unchanged outside a duo.
func duo_amount(amount: float, step: float) -> float:
	if duo_scale == 1.0:
		return amount
	var grown := amount * duo_scale
	if step > 1.0 and absf(grown) >= 10.0:
		return roundf(grown / step) * step
	return roundf(grown)


## A ×Mult a duo's Jester gives grows by half its bonus (×1.5 → ×1.75).
func duo_factor(factor: float) -> float:
	if duo_scale == 1.0:
		return factor
	return snappedf(1.0 + (factor - 1.0) * duo_scale, 0.01)


## What the town's Warrant costs after a city's discount (never below 1).
func warrant_price(def_id: String) -> int:
	var def := ContentDB.get_def(def_id)
	return maxi(1, def.cost - stat("warrant_discount")) if def != null else 0


## The single-hand score an Encore has to reach.
func encore_target() -> float:
	return floorf(show_target * ENCORE_SHARE)


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
				if int(extra) > 0:
					_mark_fired(item)
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
	return "zanni:%s#%d" % [item.def_id, position_of(item)]


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
		if is_rematch():
			factor *= REMATCH_TARGET
	factor *= stat("target_pct") / 100.0
	return floorf(Shows.base_target(town, stat("target_scaling"), towns) * factor)


## The Patron whose whim rules the current show: the town's on its third show, or the one
## drawn for this show when every show is a Patron show; "" for none.
func current_patron() -> String:
	if show_index == Shows.PATRON:
		return town_patron
	return str(show_counters.get("patron", ""))


## Everything that can react to the run, in firing order: deck, challenge, stakes, the
## campaign chapter (and its rule city's twist), carried props, the city, warrants, zanni
## (each followed by its edition), consumables' editions, pending favors, then the current
## patron while its show is on, unless the sources before it mute patrons; last, during a
## show on tour, the Scenario's and the crowd's rules.
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
	var chapter_def := ContentDB.get_def(chapter)
	var rule_city := ""
	if chapter_def != null:
		out.append([chapter_def, null])
		rule_city = str(chapter_def.data.get("rule_city", ""))
		var rule_def := ContentDB.get_def(rule_city)
		if rule_def != null:
			out.append([rule_def, null])
	for p in props:
		var d := ContentDB.get_def(p)
		if d != null:
			out.append([d, null])
	var city_def := ContentDB.get_def(city)
	if city_def != null and city != rule_city:
		out.append([city_def, null])
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
	if phase == Phase.IN_SHOW and tour:
		for rule in [ScenarioCards.RULE_SCENARIO, ScenarioCards.RULE_CROWD]:
			var d := ContentDB.get_def(rule)
			if d != null:
				out.append([d, null])
	return out


# --- actions ---

func apply(action: Dictionary) -> Dictionary:
	var a := _normalize(action)
	var result: Dictionary
	match a["a"]:
		"select_show":
			result = _select_show(bool(a.get("perform", false)))
		"skip_show":
			result = _skip_show()
		"play":
			result = _encore_play(a.get("cards", [])) if phase == Phase.ENCORE else _play(a.get("cards", []))
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
		"merge":
			result = _merge(int(a.get("index", -1)), int(a.get("other", -1)))
		"travel":
			result = _travel(int(a.get("index", -1)), int(a.get("slot", 0)))
		"encore":
			result = _encore()
		"bow":
			result = _bow()
		"swap_scenario":
			result = _swap_scenario()
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


## Starts the show; `perform` takes on its Scenario (on tour), otherwise the troupe improvises.
func _select_show(perform := false) -> Dictionary:
	if phase != Phase.CHOOSE_SHOW:
		return _fail("not choosing a show")
	phase = Phase.IN_SHOW
	show_score = 0.0
	show_counters = {"hands_played": 0, "discards_used": 0, "types": [], "fired": []}
	scenario_on = perform and tour and scenario != ""
	scenario_beat = 0
	mood = clampi(stat("mood_start"), 0, MOOD_MAX)
	ovation = false
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
	# Penalties can stack past zero (a stake, a city, an Omen...): a show still gets a hand,
	# and never fewer than no discards.
	hands_left = maxi(1, stat("hands"))
	discards_left = maxi(0, stat("discards"))
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
	for id in _fired_in(ctx.events):
		_mark_fired_id(id)
	fire_all("hand_played", self, [played])
	if tour:
		_crowd_reacts(ctx)
	if show_score >= show_target:
		_win_show()
	elif hands_left == 0:
		_lose_or_rescue()
	else:
		_draw_to_full(true)
		if hand.is_empty():
			_lose_or_rescue()
	return _ok(ctx.summary())


## After a hand on tour: the Scenario moves on a beat or collapses (a Fiasco), and the
## crowd's mood follows the hand's share of the target. A standing ovation spends itself on
## the hand it boosted; a mood of 0 means the crowd walked out (3 ducats less at cash-out).
func _crowd_reacts(ctx: ScoreContext) -> void:
	var share := ctx.total / maxf(show_target, 1.0)
	var delta := -2
	if share >= 0.5:
		delta = 3
	elif share >= 0.25:
		delta = 2
	elif share >= 0.1:
		delta = 1
	if scenario_on:
		if bool(ctx.flags.get("beat", false)):
			delta += 1
			scenario_beat += 1
			show_counters["beats"] = scenario_beat
			if scenario_beat >= ScenarioCards.BEATS:
				scenario_on = false
				show_counters["scenario"] = "done"
				_count("scenarios_done")
		else:
			delta -= 3
			scenario_on = false
			show_counters["scenario"] = "fiasco"
			_count("fiascos")
	if ovation:
		ovation = false
		mood = OVATION_AFTER
	mood = clampi(mood + delta, 0, MOOD_MAX)
	if mood >= MOOD_MAX:
		ovation = true
		_count("ovations")
	if mood <= 0:
		show_counters["walkout"] = true


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
	if int(counters.get("shops", 0)) == 0:
		for i in stat("first_shop_jesters"):
			var offer := _roll_offer("zanni")
			if not offer.is_empty():
				shop.offers.append(offer)
	_count("shops")
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
	var value := item.sell_value() * stat("sell_pct") / 100
	list.remove_at(index)
	# A Jester that holds a one-use slot (Il Carro di Tespi) can't leave a card without one.
	if zone == "zanni" and consumables.filter(func(c: ItemCard) -> bool: return not _takes_no_slot(c)).size() > stat("consumable_slots"):
		list.insert(index, item)
		return _fail("use or sell a one-use card first: this Jester holds one of their slots")
	ducats += value
	_count("sold")
	item.fire("sold", [self, item])
	fire_all("sell", self, [item])
	return _ok({"ducats": value})


## What an offer or pack costs right now: 0 if a Favor made it free, otherwise after shop
## discounts (and a city's pack discount; packs are the offers without a "kind") and never
## below 1.
func offer_price(offer: Dictionary) -> int:
	if bool(offer.get("free", false)):
		return 0
	var cost := int(offer["cost"]) * (100 - stat("shop_discount_pct")) / 100
	if not offer.has("kind"):
		cost -= stat("pack_discount")
	return maxi(1, cost - stat("shop_discount"))


## What the next reroll costs: free while free rerolls remain in this shop; the first one
## in each shop can be cheaper (the prop Il Mulo Testardo).
func reroll_price() -> int:
	if shop.rerolls < stat("free_rerolls"):
		return 0
	var first_off := stat("first_reroll_discount") if shop.rerolls == 0 else 0
	return maxi(0, shop.reroll_cost - stat("reroll_discount") - first_off)


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
	var price := warrant_price(on_sale)
	if ducats - price < -stat("debt_limit"):
		return _fail("not enough ducats")
	ducats -= price
	if index == 0:
		warrant_bought = true
	else:
		shop.extra_bought = true
	_count("purchases")
	fire_all("buy", self, [ItemCard.make(def.id, price)])
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


## The Patrons a town can draw (never the campaign's own, Messer Grifone).
func _patron_pool(for_town := -1) -> Array[ContentDef]:
	var t := town if for_town < 0 else for_town
	var finale := t % Shows.FINAL_TOWN == 0
	return ContentDB.pool("patron", func(d: ContentDef) -> bool:
		return bool(d.data.get("finale", false)) == finale and int(d.data.get("min_town", 1)) <= t \
			and not bool(d.data.get("campaign", false)))


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
	var waiting := patron_waiting(route_row, route_col)
	if waiting != "":
		town_patron = waiting
	town_scenario_swaps = 0
	var favor_pool := ContentDB.pool("favor")
	town_favors = ["", "", ""]
	town_favor_notes = ["", "", ""]
	if not favor_pool.is_empty():
		for i in Shows.PATRON:
			var favor: ContentDef = favor_pool[rng("favor").below(favor_pool.size())]
			town_favors[i] = favor.id
			if bool(favor.data.get("names_hand", false)):
				var hands: Array = HandTable.ORDER.filter(func(h: String) -> bool: return hand_levels.is_visible(h))
				town_favor_notes[i] = hands[rng("favor").below(hands.size())]
	town_warrant = _roll_warrant()
	warrant_bought = false
	town_swaps = 0
	town_played = {}
	_roll_scenario()


# --- the tour (batch 12) ---

## The deck's home city starts the route; without one the run plays the classic rules. A
## campaign chapter runs from where the last chapter ended to its own city instead.
func _plan_route() -> void:
	var home := CityCards.home_of(deck_id, self)
	var goal := CityCards.VENEZIA
	# A Grand Tour sets out from Palermo, whatever the deck's home.
	if towns > Shows.FINAL_TOWN and home != "":
		home = Shows.GRAND_START
	var chapter_def := ContentDB.get_def(chapter)
	if chapter_def != null:
		home = str(chapter_def.data["start"])
		goal = str(chapter_def.data["city"])
	if home == "":
		return
	tour = true
	route = RouteMap.plan(self, home, goal, towns)
	route_row = 0
	route_col = 0
	path.assign([0])
	city = home
	_light_lantern(1)


## Makes sure the route has a row after the troupe's (endless play grows it).
func _extend_route() -> void:
	while route.size() < route_row + 2:
		RouteMap.extend(self, route)
		_light_lantern(route.size() - 1)


## La Lanterna: the Patron of every city from row `from` on is drawn with the map, so the map
## can show it (row r is town r + 1).
func _light_lantern(from: int) -> void:
	if not props.any(func(p: String) -> bool: return ContentDB.get_def(p) != null and ContentDB.get_def(p).data.get("lantern", false)):
		return
	var r := rng("lantern")
	for row in range(from, route.size()):
		var pool := _patron_pool(row + 1)
		if pool.is_empty():
			continue
		for node in route[row]:
			if not (node as Dictionary).has("patron"):
				node["patron"] = pool[r.below(pool.size())].id


## The Patron already settled for a town (row and column on the map): the chapter's story
## Patron in town 8, the nemesis, a rematch, or the one La Lanterna drew; "" when the town
## draws its own on arrival.
func patron_waiting(row: int, col: int, for_town := -1) -> String:
	var t := town if for_town < 0 else for_town
	var chapter_def := ContentDB.get_def(chapter)
	if chapter_def != null and t == Shows.FINAL_TOWN:
		return str(chapter_def.data["patron"])
	if t == nemesis_town():
		return nemesis_patron()
	if int(rematch.get("town", -1)) == t:
		return str(rematch["patron"])
	if row >= 0 and row < route.size() and col >= 0 and col < (route[row] as Array).size():
		return str(((route[row] as Array)[col] as Dictionary).get("patron", ""))
	return ""


## The nemesis this run brings, if it can appear in it ("" otherwise): Messer Grifone only in
## the campaign's last chapter.
func nemesis_patron() -> String:
	var n: Dictionary = extras.get("nemesis", {})
	var d := ContentDB.get_def(str(n.get("patron", "")))
	if d == null or d.kind != "patron":
		return ""
	if bool(d.data.get("campaign", false)) and chapter != CampaignCards.id_of(CampaignCards.COUNT):
		return ""
	return d.id


## The town where the nemesis waits: where it beat you, within the towns it may appear in
## (a finale Patron in town 8); -1 for none.
func nemesis_town() -> int:
	var id := nemesis_patron()
	if id == "":
		return -1
	var d := ContentDB.get_def(id)
	if bool(d.data.get("finale", false)):
		return Shows.FINAL_TOWN
	return clampi(int((extras["nemesis"] as Dictionary).get("town", 1)), int(d.data.get("min_town", 1)), Shows.FINAL_TOWN - 1)


## This town's Patron is the nemesis (and the troupe is on its third show or before it).
func is_nemesis() -> bool:
	return town_patron != "" and town == nemesis_town() and town_patron == nemesis_patron()


func is_rematch() -> bool:
	return int(rematch.get("town", -1)) == town and town_patron == str(rematch.get("patron", ""))


## On the way to a new town (5–7): 1 in 5, a Patron beaten earlier this run comes back for
## it, once a run (never the nemesis, never where the nemesis or a story Patron waits).
func _roll_rematch() -> void:
	if not bool(extras.get("rivalry", false)) or not rematch.is_empty() or not REMATCH_TOWNS.has(town):
		return
	if town == nemesis_town() or (chapter != "" and town == Shows.FINAL_TOWN):
		return
	var pool := beaten.filter(func(id: String) -> bool:
		var d := ContentDB.get_def(id)
		return d != null and id != nemesis_patron() and not bool(d.data.get("finale", false)) \
			and not bool(d.data.get("campaign", false)))
	if pool.is_empty():
		return
	var r := rng("rematch")
	if r.chance(REMATCH_CHANCE):
		rematch = {"town": town, "patron": pool[r.below(pool.size())]}


## Il Suggeritore: the next show's Scenario swapped for another of its tier.
func _swap_scenario() -> Dictionary:
	if phase != Phase.CHOOSE_SHOW or not tour or scenario == "":
		return _fail("no Scenario to swap")
	if town_scenario_swaps >= stat("scenario_swaps"):
		return _fail("no Scenario swaps left this town")
	town_scenario_swaps += 1
	scenario = ScenarioCards.pick(self, rng("scenario"), scenario)
	return _ok({"scenario": scenario})


## The Scenario tier a campaign chapter fixes (0: by town).
func scenario_tier() -> int:
	var chapter_def := ContentDB.get_def(chapter)
	return int(chapter_def.data.get("scenario_tier", 0)) if chapter_def != null else 0


# --- batch 13: extras and fame ---

## Takes what the profile brings: {maestri: [ids], props: [ids], nemesis: {patron, town},
## chapter, carry: {id, parts}, rivalry}.
func _take_extras(run_extras: Dictionary) -> void:
	extras = run_extras.duplicate(true)
	maestri.clear()
	for id in extras.get("maestri", []):
		maestri[str(id)] = true
	props.clear()
	for id in extras.get("props", []):
		if ContentDB.get_def(str(id)) != null:
			props.append(str(id))
	chapter = str(extras.get("chapter", ""))


## The Jester carried in from the last campaign chapter joins first (a duo with its parts).
func _join_carried() -> void:
	var carry: Dictionary = extras.get("carry", {})
	var id := str(carry.get("id", ""))
	var def := ContentDB.get_def(id)
	if def == null:
		return
	var parts: Array = carry.get("parts", [])
	if def.kind == "lazzo" and parts.size() == 2:
		var duo := ItemCard.make(id, 0)
		for p in parts:
			var pd := ContentDB.get_def(str(p))
			if pd == null:
				return
			duo.parts.append(ItemCard.make(pd.id, pd.cost))
			duo.cost += pd.cost
		_join(duo)
	elif def.kind == "zanni":
		_join(ItemCard.make(id, def.cost))


## Whether the profile brought anything that changes play (Maestri in use, props, a
## campaign chapter or a carried Jester), or the run is a Grand Tour: such runs stay off the
## leaderboards.
func assisted() -> bool:
	return not maestri.is_empty() or not props.is_empty() or chapter != "" or not (extras.get("carry", {}) as Dictionary).is_empty() \
		or towns != Shows.FINAL_TOWN


## The def ids of every Jester in the troupe, a duo counted as its two Jesters.
func troupe_ids() -> Array[String]:
	var out: Array[String] = []
	for z in zanni:
		if z.parts.is_empty():
			out.append(z.def_id)
		else:
			for p in z.parts:
				out.append(p.def_id)
	return out


func _add_fame(ids: Array, amount: int) -> void:
	for id in ids:
		fame[id] = int(fame.get(id, 0)) + amount


## The Jesters that fired in a scored hand, from its events ("zanni:<id>#<seat>").
func _fired_in(events: Array) -> Array[String]:
	var out: Array[String] = []
	for e in events:
		var src := str(e.get("src", ""))
		if not src.begins_with("zanni:"):
			continue
		var seat := int(src.get_slice("#", 1))
		if seat < 0 or seat >= zanni.size():
			continue
		var item := zanni[seat]
		var ids: Array = [item.def_id] if item.parts.is_empty() else item.parts.map(func(p: ItemCard) -> String: return p.def_id)
		for id in ids:
			if not out.has(id):
				out.append(id)
	return out


## Notes that a Jester (both, for a duo) did something this show, for its fame.
func _mark_fired(item: ItemCard) -> void:
	if item.parts.is_empty():
		_mark_fired_id(item.def_id)
	else:
		for p in item.parts:
			_mark_fired_id(p.def_id)


func _mark_fired_id(id: String) -> void:
	if previewing or not (phase == Phase.IN_SHOW or phase == Phase.ENCORE or phase == Phase.CASH_OUT):
		return
	var fired: Array = show_counters.get("fired", [])
	if not fired.has(id):
		fired.append(id)
	show_counters["fired"] = fired


## The roads out of the troupe's city: columns in the next row.
func roads() -> Array:
	if route_row >= route.size():
		return []
	return ((route[route_row] as Array)[route_col] as Dictionary)["to"]


## The next show's Scenario, drawn from the tier for this town.
func _roll_scenario() -> void:
	scenario = ""
	if tour:
		scenario = ScenarioCards.pick(self, rng("scenario"))


## Moves to a city in the next row that the current one has a road to. `option` answers a
## city that asks on arrival (Messina).
func _travel(col: int, option: int) -> Dictionary:
	if phase != Phase.MAP:
		return _fail("not on the map")
	var row: Array = route[route_row + 1]
	if col < 0 or col >= row.size() or not roads().has(col):
		return _fail("no road to that city")
	var dest := str((row[col] as Dictionary)["city"])
	var options: Array = ContentDB.get_def(dest).data.get("options", [])
	if not options.is_empty() and (option < 0 or option >= options.size()):
		return _fail("choose one of the city's options")
	route_row += 1
	route_col = col
	path.append(col)
	city = dest
	town_option = option if not options.is_empty() else 0
	_count("cities")
	_start_town()
	return _ok({"city": city})


## The crowd demands an Encore: refill the hand and play one more hand.
func _encore() -> Dictionary:
	if phase != Phase.ENCORE or show_counters.get("encore", "") != "offered":
		return _fail("no Encore on offer")
	show_counters["encore"] = "live"
	_draw_to_full()
	return _ok({"target": encore_target()})


## Takes a bow instead of an Encore: the cash-out as it stands.
func _bow() -> Dictionary:
	if phase != Phase.ENCORE or show_counters.get("encore", "") == "live":
		return _fail("no Encore to turn down")
	show_counters["encore"] = "bowed"
	phase = Phase.CASH_OUT
	return _ok({})


## The Encore's hand: reach half the show's target in one hand to double the cash-out;
## miss and the show's own reward is lost.
func _encore_play(ids: Array) -> Dictionary:
	if show_counters.get("encore", "") != "live":
		return _fail("no Encore on")
	var played := _take_from_hand(ids)
	if played.is_empty():
		return _fail("pick 1 to %d cards from your hand" % stat("max_play"))
	var held: Array[PlayingCard] = hand.duplicate()
	var ctx := Scorer.score(self, played, held)
	_count("hands_played")
	counters["best_hand"] = maxf(float(counters.get("best_hand", 0.0)), ctx.total)
	for card in ctx.destroyed:
		destroy_card(card)
	for card in played:
		if not ctx.destroyed.has(card):
			discard_pile.append(card)
	var hit := ctx.total >= encore_target()
	if hit:
		var total := 0
		for p in payout:
			total += int(p["v"])
		if total > 0:
			payout.append({"src": "encore", "v": total})
		_count("encores")
		_add_fame(_fired_in(ctx.events), Fame.ENCORE)
	else:
		payout = payout.filter(func(p: Dictionary) -> bool: return p["src"] != "show")
	show_counters["encore"] = "hit" if hit else "missed"
	phase = Phase.CASH_OUT
	var out := ctx.summary()
	out["encore"] = hit
	return _ok(out)


## Merges the two Jesters of a duo into its Lazzo card: one slot, both effects stronger.
## The duo takes the first edition either had, and any sticker either had.
func _merge(a: int, b: int) -> Dictionary:
	if phase != Phase.SHOP:
		return _fail("merge in the shop")
	if a < 0 or b < 0 or a >= zanni.size() or b >= zanni.size() or a == b:
		return _fail("pick two of your Jesters")
	var duo_id := LazziCards.duo_of(zanni[a].def_id, zanni[b].def_id)
	if duo_id == "":
		return _fail("these two have no routine together")
	var first := zanni[a]
	var second := zanni[b]
	var duo := ItemCard.make(duo_id, first.cost + second.cost, first.edition if first.edition != "" else second.edition)
	var order: Array = ContentDB.get_def(duo_id).data["parts"]
	duo.parts.assign([first, second] if order[0] == first.def_id else [second, first])
	for part in duo.parts:
		for key in ["eternal", "rented"]:
			if bool(part.state.get(key, false)):
				duo.state[key] = true
		if part.state.has("perish"):
			duo.state["perish"] = mini(int(duo.state.get("perish", PERISH_SHOWS)), int(part.state["perish"]))
		for key in ["eternal", "rented", "perish", "perished"]:
			part.state.erase(key)
		part.edition = ""
		part.debuffed = false
	zanni[mini(a, b)] = duo
	zanni.remove_at(maxi(a, b))
	see(duo_id)
	_count("merges")
	return _ok({"duo": duo_id})


## On to the next show; after the Patron, the next town (on tour, by way of the map).
func _advance_show() -> void:
	show_index += 1
	if show_index > Shows.PATRON:
		town += 1
		_roll_rematch()
		if tour:
			_extend_route()
			show_index = Shows.MATINEE
			phase = Phase.MAP
		else:
			_start_town()
	else:
		phase = Phase.CHOOSE_SHOW
		_roll_scenario()


func _win_show(rescued := false) -> void:
	phase = Phase.CASH_OUT
	if town == towns and show_index == Shows.PATRON:
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
	_show_fame()
	if show_index == Shows.PATRON:
		beaten.append(town_patron)
		if is_nemesis():
			_count("nemesis_beaten")
			feats["vendetta"] = true
			_add_fame(troupe_ids(), Fame.NEMESIS)
	if town == towns and show_index == Shows.PATRON:
		_add_fame(troupe_ids(), Fame.RUN_WON)
	if tour and not rescued and mood >= ENCORE_MOOD:
		phase = Phase.ENCORE
		show_counters["encore"] = "offered"


## A won show: fame for every Jester still in the troupe that fired in it; one that always
## works (a slot, a rule; Fame.is_active) counts as firing while it's working.
func _show_fame() -> void:
	for z in zanni:
		if z.debuffed:
			continue
		var members: Array[ItemCard] = [z]
		if not z.parts.is_empty():
			members = z.parts
		for item in members:
			var d: ContentDef = item.def()
			if d != null and not Fame.is_active(d) and not d.data.has("copies"):
				_mark_fired_id(item.def_id)
	var troupe := troupe_ids()
	var fired: Array = show_counters.get("fired", [])
	_add_fame(fired.filter(func(id: String) -> bool: return troupe.has(id)), Fame.SHOW)


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
		if is_rematch():
			reward *= REMATCH_REWARD
	if reward > 0:
		items.append({"src": "show", "v": reward})
	if show_index == Shows.PATRON and is_nemesis():
		items.append({"src": "nemesis", "v": NEMESIS_DUCATS})
	var per_hand := stat("hand_reward")
	if hands_left > 0 and per_hand > 0:
		items.append({"src": "hands", "v": hands_left * per_hand})
	var per_discard := stat("discard_reward")
	if discards_left > 0 and per_discard > 0:
		items.append({"src": "discards", "v": discards_left * per_discard})
	var beats := int(show_counters.get("beats", 0))
	var scenario_pay := 0
	for b in beats:
		scenario_pay += ScenarioCards.BEAT_DUCATS[b]
	if scenario_pay > 0:
		items.append({"src": "scenario", "v": scenario_pay})
	if bool(show_counters.get("walkout", false)):
		items.append({"src": "crowd", "v": -WALKOUT_DUCATS})
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
			_mark_fired(item)
		if is_maestro(item) and Fame.FLAT.has(item.def_id):
			items.append({"src": item_source(item), "v": Fame.FLAT_DUCATS})
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


## One shop offer of a random kind, or of `force_kind` (a prop's extra Jester).
func _roll_offer(force_kind := "") -> Dictionary:
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
	var kind := force_kind
	if kind == "":
		var k := r.pick_weighted(weights)
		if k < 0:
			return {}
		kind = kinds[k]
	elif _shop_pool(kind).is_empty():
		return {}
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
	if kind == "zanni":
		return base * stat("zanni_rate_pct") / 100.0
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
	var rare_pct := stat("rare_rate_pct")
	for i in 3:
		var w: float = ZANNI_RARITY_WEIGHTS[i] if not by_rarity[i].is_empty() else 0
		weights.append(w * rare_pct / 100.0 if i == 2 and rare_pct != 100 else w)
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
	for key in ["slot", "index", "other"]:
		if action.has(key):
			a[key] = int(action[key])
	if action.has("zone"):
		a["zone"] = str(action["zone"])
	if bool(action.get("perform", false)):
		a["perform"] = true
	return a


# --- saving ---

## The whole run as plain data. A save (for_save) is JSON-safe (see clean) and keeps the
## action log; the quick in-memory copy preview() makes skips both, which matters on phones
## (it runs on every tap).
func to_dict(for_save := true) -> Dictionary:
	var rng_states := {}
	for stream in _rngs:
		rng_states[stream] = (_rngs[stream] as ZRng).state
	var data := {
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
		"log": action_log.duplicate(true) if for_save else [],
		"tour": tour, "towns": towns, "route": route.duplicate(true), "route_row": route_row, "route_col": route_col, "path": path.duplicate(), "city": city,
		"town_option": town_option, "scenario": scenario, "scenario_on": scenario_on,
		"scenario_beat": scenario_beat, "mood": mood, "ovation": ovation,
		"extras": extras.duplicate(true), "beaten": beaten.duplicate(), "rematch": rematch.duplicate(),
		"fame": fame.duplicate(), "scenario_swaps": town_scenario_swaps,
	}
	return clean(data) if for_save else data


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
	var favors_saved: Array = d["town_favors"]
	run.town_favors = ["", "", ""]
	for i in mini(favors_saved.size(), 3):
		run.town_favors[i] = str(favors_saved[i])
	run.town_warrant = str(d.get("warrant", ""))
	run.warrant_bought = bool(d.get("warrant_bought", false))
	run.town_swaps = int(d.get("swaps", 0))
	run.pack = (d.get("pack", {}) as Dictionary).duplicate(true)
	for queued in d.get("pack_queue", []):
		run.pack_queue.append(str(queued))
	for key in d.get("stat_mods", {}):
		run.stat_mods[str(key)] = int(d["stat_mods"][key])
	var notes: Array = d.get("favor_notes", [])
	run.town_favor_notes = ["", "", ""]
	for i in mini(notes.size(), 3):
		run.town_favor_notes[i] = str(notes[i])
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
	# Saves from before the tour (version 1) have none of these and play the classic rules.
	run.tour = bool(d.get("tour", false))
	run.towns = int(d.get("towns", Shows.FINAL_TOWN))
	# Before the Gala (version 3 and older) the Patron was the third show.
	if int(d.get("v", 1)) < 4 and run.show_index == 2:
		run.show_index = Shows.PATRON
	for row in d.get("route", []):
		var nodes: Array = []
		for node in row:
			var to: Array[int] = []
			for c in node["to"]:
				to.append(int(c))
			var copy := {"city": str(node["city"]), "to": to}
			if node.has("patron"):
				copy["patron"] = str(node["patron"])
			nodes.append(copy)
		run.route.append(nodes)
	run.route_row = int(d.get("route_row", 0))
	run.route_col = int(d.get("route_col", 0))
	for col in d.get("path", []):
		run.path.append(int(col))
	run.city = str(d.get("city", ""))
	run.town_option = int(d.get("town_option", 0))
	run.scenario = str(d.get("scenario", ""))
	run.scenario_on = bool(d.get("scenario_on", false))
	run.scenario_beat = int(d.get("scenario_beat", 0))
	run.mood = int(d.get("mood", MOOD_START))
	run.ovation = bool(d.get("ovation", false))
	# Saves from before batch 13 (version 2) have none of these: a run with no extras.
	run._take_extras(d.get("extras", {}))
	for id in d.get("beaten", []):
		run.beaten.append(str(id))
	var re: Dictionary = d.get("rematch", {})
	if not re.is_empty():
		run.rematch = {"town": int(re["town"]), "patron": str(re["patron"])}
	for id in d.get("fame", {}):
		run.fame[str(id)] = int(d["fame"][id])
	run.town_scenario_swaps = int(d.get("scenario_swaps", 0))
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
