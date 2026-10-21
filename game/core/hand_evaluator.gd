class_name HandEvaluator
extends RefCounted
## Finds the best poker hand in the played cards and which of them score.
##
## Options (from run stats): flush_min / straight_min (cards needed, default 5),
## straight_gap (a straight may skip one rank), all_score (every played card scores).


class Result:
	var type := HandTable.HIGH_CARD
	## Scoring cards, in the order they were played.
	var scoring: Array[PlayingCard] = []
	## Every hand type the played cards contain (a Full House also contains a Pair).
	var contains: Dictionary = {}


static func evaluate(cards: Array[PlayingCard], options := {}) -> Result:
	var result := Result.new()
	var flush_min := int(options.get("flush_min", 5))
	var straight_min := int(options.get("straight_min", 5))
	var gap := bool(options.get("straight_gap", false))

	var ranked: Array[PlayingCard] = []
	for card in cards:
		if card.has_rank():
			ranked.append(card)

	var groups := _rank_groups(ranked)
	var flush := _find_flush(ranked, flush_min)
	var straight := _find_straight(ranked, straight_min, gap)
	var top: int = groups[0].size() if groups.size() > 0 else 0
	var second: int = groups[1].size() if groups.size() > 1 else 0

	var has := result.contains
	has[HandTable.HIGH_CARD] = not cards.is_empty()
	has[HandTable.PAIR] = top >= 2
	has[HandTable.TWO_PAIR] = top >= 2 and second >= 2
	has[HandTable.THREE_KIND] = top >= 3
	has[HandTable.STRAIGHT] = not straight.is_empty()
	has[HandTable.FLUSH] = not flush.is_empty()
	has[HandTable.FULL_HOUSE] = top >= 3 and second >= 2
	has[HandTable.FOUR_KIND] = top >= 4
	has[HandTable.STRAIGHT_FLUSH] = has[HandTable.STRAIGHT] and has[HandTable.FLUSH]
	has[HandTable.FIVE_KIND] = top >= 5
	has[HandTable.FLUSH_HOUSE] = has[HandTable.FULL_HOUSE] and has[HandTable.FLUSH]
	has[HandTable.FLUSH_FIVE] = has[HandTable.FIVE_KIND] and has[HandTable.FLUSH]
	for hand_type in HandTable.ORDER:
		if has[hand_type]:
			result.type = hand_type

	var picked := {}
	var t := result.type
	if t == HandTable.FLUSH_FIVE or t == HandTable.FLUSH_HOUSE:
		_mark(picked, groups[0])
		_mark(picked, groups[1] if groups.size() > 1 else [])
		_mark(picked, flush)
	elif t == HandTable.FIVE_KIND or t == HandTable.FULL_HOUSE or t == HandTable.TWO_PAIR:
		_mark(picked, groups[0])
		_mark(picked, groups[1] if groups.size() > 1 else [])
	elif t == HandTable.STRAIGHT_FLUSH:
		_mark(picked, straight)
		_mark(picked, flush)
	elif t == HandTable.FOUR_KIND or t == HandTable.THREE_KIND or t == HandTable.PAIR:
		_mark(picked, groups[0])
	elif t == HandTable.FLUSH:
		_mark(picked, flush)
	elif t == HandTable.STRAIGHT:
		_mark(picked, straight)
	elif not ranked.is_empty():
		_mark(picked, [_highest(ranked)])

	var all_score := bool(options.get("all_score", false))
	for card in cards:
		if all_score or picked.has(card.id) or card.always_scores():
			result.scoring.append(card)
	return result


static func _mark(picked: Dictionary, cards: Array) -> void:
	for card in cards:
		picked[card.id] = true


## Groups of same-rank cards, biggest first, then highest rank first.
static func _rank_groups(cards: Array[PlayingCard]) -> Array:
	var by_rank := {}
	for card in cards:
		if not by_rank.has(card.rank):
			by_rank[card.rank] = []
		by_rank[card.rank].append(card)
	var groups: Array = by_rank.values()
	groups.sort_custom(func(a: Array, b: Array) -> bool:
		if a.size() != b.size():
			return a.size() > b.size()
		return a[0].rank > b[0].rank)
	return groups


static func _highest(cards: Array[PlayingCard]) -> PlayingCard:
	var best := cards[0]
	for card in cards:
		if card.rank > best.rank:
			best = card
	return best


static func _find_flush(cards: Array[PlayingCard], need: int) -> Array[PlayingCard]:
	var none: Array[PlayingCard] = []
	if cards.size() < need:
		return none
	for s in 4:
		var same: Array[PlayingCard] = []
		for card in cards:
			if card.has_suit(s):
				same.append(card)
		if same.size() >= need:
			return same
	return none


## Cards forming the longest straight of at least `need` ranks; Ace plays high or low.
static func _find_straight(cards: Array[PlayingCard], need: int, gap: bool) -> Array[PlayingCard]:
	var present := {}
	for card in cards:
		present[card.rank] = true
		if card.rank == PlayingCard.ACE:
			present[1] = true
	var best: Array = []
	for start in range(1, 15):
		if not present.has(start):
			continue
		var run := [start]
		var cur := start
		while cur < 14:
			if present.has(cur + 1):
				cur += 1
			elif gap and present.has(cur + 2):
				cur += 2
			else:
				break
			run.append(cur)
		if run.size() >= need and run.size() > best.size():
			best = run
	var out: Array[PlayingCard] = []
	if best.is_empty():
		return out
	for card in cards:
		if best.has(card.rank) or (card.rank == PlayingCard.ACE and best.has(1)):
			out.append(card)
	return out
