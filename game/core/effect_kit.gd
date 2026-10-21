class_name EffectKit
extends RefCounted
## Builders for the common effect shapes, so most cards are one line of data.
## Each returns a hooks Dictionary for ContentDef.make().


## Always adds the bonus.
static func flat(points := 0.0, mult := 0.0, xmult := 1.0) -> Dictionary:
	var f := func(ctx: ScoreContext, item: ItemCard) -> void:
		ctx.bonus(points, mult, xmult, ctx.run.item_source(item))
	return {"independent": f}


## Adds the bonus when the played hand contains `hand` (a Full House contains a Pair).
static func if_hand(hand: String, points := 0.0, mult := 0.0, xmult := 1.0) -> Dictionary:
	var f := func(ctx: ScoreContext, item: ItemCard) -> void:
		if ctx.has(hand):
			ctx.bonus(points, mult, xmult, ctx.run.item_source(item))
	return {"independent": f}


## Each scoring card that passes `test` adds the bonus (and optional ducats).
static func per_card(test: Callable, points := 0.0, mult := 0.0, xmult := 1.0, ducats := 0) -> Dictionary:
	var f := func(ctx: ScoreContext, item: ItemCard, card: PlayingCard) -> void:
		if test.call(card):
			var src := ctx.run.item_source(item)
			ctx.bonus(points, mult, xmult, src, card.id)
			if ducats != 0:
				ctx.add_ducats(ducats, src, card.id)
	return {"card_scored": f}


static func rank_in(ranks: Array) -> Callable:
	return func(card: PlayingCard) -> bool: return card.has_rank() and ranks.has(card.rank)


static func suit_is(suit: int) -> Callable:
	return func(card: PlayingCard) -> bool: return card.has_suit(suit)
