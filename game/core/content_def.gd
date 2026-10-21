class_name ContentDef
extends RefCounted
## One piece of game content: a zanni, sign, tarocchi, omen, warrant, patron, favor, deck,
## stake, enhancement, edition or seal. Its numbers live in `data`, its behaviour in `hooks`.
##
## Hooks are Callables called as hook(subject, item, ...extra). `subject` is the ScoreContext
## during scoring and the RunState otherwise; `item` is the owned ItemCard (a zanni or a
## consumable), or null for content the player doesn't hold as a card.
##
## Scoring hooks (subject = ScoreContext):
##   before_score(ctx, item)              after the hand is known, before base values
##   allows(ctx, item) -> bool            false: the hand isn't allowed and scores 0
##   after_base(ctx, item)                right after the base Points × Mult are set
##   scored(ctx, item)                    after every Jester, before the total
##   before_total(ctx, item)              the very last step (e.g. a deck evening out the score)
##   card_scored(ctx, item, card)         once per scoring card, per trigger
##   card_held(ctx, item, card)           once per card left in hand, per trigger
##   retrigger_scored(ctx, item, card)    -> int extra triggers for a scoring card
##   retrigger_held(ctx, item, card)      -> int extra triggers for a held card
##   independent(ctx, item)               a zanni's own effect, left to right
##   zanni_pre(ctx, item) / zanni_post(ctx, item)   editions on a zanni, around its effect
##   after_scored(ctx, null, card)        card mods, once per scoring card after the total
##   after_score(ctx, item)
## Run hooks (subject = RunState):
##   modify_stat(run, item, stat, value) -> int
##   run_start, show_start, show_end, cash_out, skip, reroll, shop_enter (run, item)
##   payout(run, item) -> int ducats added at cash-out
##   discard(run, item, cards)   buy(run, item, bought)   sell(run, item, sold)   use(run, item, used)
##   card_destroyed(run, item, card)
##   hand_played(run, item, cards)        after a hand is scored, before drawing
##   cards_drawn(run, item, cards, first_deal)
##   rescue(run, item) -> bool           a lost show passes instead; the Jester is used up
##   sold(run, item)                      on the card being sold itself, after it leaves
## A Jester with data "copies" ("right" or "leftmost") fires its target's COPYABLE hooks
## (see RunState.fire_item) instead of its own.
## Card mods on a playing card (enhancement, edition, seal), called with item = null:
##   payout_held(run, null, card) -> int  ducats if held in hand when a show is won
##   won_held(run, null, card)            held in hand when a show is won
##   discarded(run, null, card)
## Shop:
##   available(run, item) -> bool         may the shop offer this card right now
## Consumables:
##   can_use(run, item, cards) -> bool    on_use(run, item, cards)
## Favors:
##   gain(run, item)                      when taken (run.favor_note holds what it named);
##                                        data "pending": true keeps it in run.favors, where
##                                        its other hooks fire until it erases itself
## Decks:
##   build(run, item)   adds the starting cards with run.add_card()

var id := ""
var kind := ""
var cost := 0
var rarity := 0
var data: Dictionary = {}
var hooks: Dictionary = {}


static func make(def_id: String, def_kind: String, def_cost := 0, def_rarity := 0,
		def_hooks := {}, def_data := {}) -> ContentDef:
	var d := ContentDef.new()
	d.id = def_id
	d.kind = def_kind
	d.cost = def_cost
	d.rarity = def_rarity
	d.hooks = def_hooks
	d.data = def_data
	return d


func has_hook(hook: String) -> bool:
	return hooks.has(hook)


func fire(hook: String, args: Array) -> Variant:
	var cb: Variant = hooks.get(hook)
	if cb is Callable and (cb as Callable).is_valid():
		return (cb as Callable).callv(args)
	return null
