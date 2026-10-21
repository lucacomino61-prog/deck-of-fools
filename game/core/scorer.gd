class_name Scorer
extends RefCounted
## Scores one played hand, in the genre's order:
##   1. find the hand; before_score hooks; a hand an "allows" hook refuses scores 0
##   2. base Points × Mult from the hand's level; after_base hooks (e.g. a Patron halving it)
##   3. each scoring card, left to right (plus retriggers): its points, its enhancement /
##      edition / seal, then every zanni's card_scored
##   4. each card held in hand (plus retriggers): card mods and zanni card_held
##   5. each zanni, left to right: edition before, its own effect, edition after;
##      then "scored" hooks on everything else (e.g. a Warrant's ×Mult)
##   6. total = floor(points × mult); after_scored on each scoring card's mods (e.g. a
##      Mirror card shattering); after_score hooks


static func score(run: RunState, played: Array[PlayingCard], held: Array[PlayingCard]) -> ScoreContext:
	var result := HandEvaluator.evaluate(played, run.eval_options())
	var ctx := ScoreContext.new()
	ctx.run = run
	ctx.hand_type = result.type
	ctx.contains = result.contains
	ctx.played = played
	ctx.scoring = result.scoring
	ctx.held = held

	run.hand_levels.mark_played(result.type)
	run.fire_all("before_score", ctx)
	if not run.hand_allowed(ctx):
		ctx.note("not_allowed", result.type)
		return ctx

	ctx.points = run.hand_levels.points(result.type)
	ctx.mult = run.hand_levels.mult(result.type)
	ctx.note("base", result.type)
	run.fire_all("after_base", ctx)

	for card in ctx.scoring:
		if card.debuffed:
			ctx.note("debuffed", "card", card.id)
			continue
		var times := 1 + run.count_retriggers(ctx, card, "retrigger_scored")
		for i in times:
			_score_card(run, ctx, card)

	for card in held:
		if card.debuffed:
			continue
		var times := 1 + run.count_retriggers(ctx, card, "retrigger_held")
		for i in times:
			_hold_card(run, ctx, card)

	for item in run.zanni:
		if item.debuffed:
			continue
		var edition := ContentDB.get_def(item.edition)
		if edition != null:
			edition.fire("zanni_pre", [ctx, item])
		run.fire_item(item, "independent", ctx)
		if edition != null:
			edition.fire("zanni_post", [ctx, item])

	run.fire_all("scored", ctx)
	run.fire_all("before_total", ctx)
	ctx.total = floorf(ctx.points * ctx.mult)
	for card in ctx.scoring:
		if not card.debuffed:
			run.fire_card_mods("after_scored", ctx, card)
	run.fire_all("after_score", ctx)
	return ctx


static func _score_card(run: RunState, ctx: ScoreContext, card: PlayingCard) -> void:
	ctx.add_points(card.base_points() + card.bonus_points, "card", card.id)
	run.fire_card_mods("card_scored", ctx, card)
	for item in run.zanni:
		if not item.debuffed:
			run.fire_item(item, "card_scored", ctx, [card])


static func _hold_card(run: RunState, ctx: ScoreContext, card: PlayingCard) -> void:
	run.fire_card_mods("card_held", ctx, card)
	for item in run.zanni:
		if not item.debuffed:
			run.fire_item(item, "card_held", ctx, [card])
