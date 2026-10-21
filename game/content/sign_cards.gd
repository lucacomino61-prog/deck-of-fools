class_name SignCards
extends RefCounted
## Card batch 1 (approved 2026-10-21): the 12 Signs, one zodiac sign per poker hand
## (called Stars until batch 2 renamed them, so they aren't confused with La Stella).
## Using a Sign levels up its hand. A secret hand's Sign stays out of the shop until that
## hand has been played once.

const COST := 3

const SIGNS := [
	["s_aries", HandTable.HIGH_CARD],
	["s_gemini", HandTable.PAIR],
	["s_pisces", HandTable.TWO_PAIR],
	["s_taurus", HandTable.THREE_KIND],
	["s_sagittarius", HandTable.STRAIGHT],
	["s_aquarius", HandTable.FLUSH],
	["s_cancer", HandTable.FULL_HOUSE],
	["s_leo", HandTable.FOUR_KIND],
	["s_scorpio", HandTable.STRAIGHT_FLUSH],
	["s_virgo", HandTable.FIVE_KIND],
	["s_capricorn", HandTable.FLUSH_HOUSE],
	["s_libra", HandTable.FLUSH_FIVE],
]


static func register() -> void:
	for row in SIGNS:
		var hand: String = row[1]
		var level_up := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
			run.hand_levels.level_up(hand, run.stat("sign_levels"))
		var hooks := {"on_use": level_up}
		if HandTable.SECRET.has(hand):
			var seen := func(run: RunState, _item: ItemCard) -> bool:
				return run.hand_levels.times_played(hand) > 0
			hooks["available"] = seen
		ContentDB.register(ContentDef.make(row[0], "sign", COST, 0, hooks, {"hand": hand}))


## The Sign that levels `hand`.
static func for_hand(hand: String) -> String:
	for row in SIGNS:
		if row[1] == hand:
			return row[0]
	return ""
