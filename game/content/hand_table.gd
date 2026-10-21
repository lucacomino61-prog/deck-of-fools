class_name HandTable
extends RefCounted
## The 12 poker hands: base Points and Mult, and what one Sign level adds.
## Values are the card batch 1 proposal (cards/batch-01.md); change them there first.

const HIGH_CARD := "high_card"
const PAIR := "pair"
const TWO_PAIR := "two_pair"
const THREE_KIND := "three_kind"
const STRAIGHT := "straight"
const FLUSH := "flush"
const FULL_HOUSE := "full_house"
const FOUR_KIND := "four_kind"
const STRAIGHT_FLUSH := "straight_flush"
const FIVE_KIND := "five_kind"
const FLUSH_HOUSE := "flush_house"
const FLUSH_FIVE := "flush_five"

## Weakest to strongest.
const ORDER := [
	HIGH_CARD, PAIR, TWO_PAIR, THREE_KIND, STRAIGHT, FLUSH,
	FULL_HOUSE, FOUR_KIND, STRAIGHT_FLUSH, FIVE_KIND, FLUSH_HOUSE, FLUSH_FIVE,
]

## Hidden in the hand list until played once.
const SECRET := [FIVE_KIND, FLUSH_HOUSE, FLUSH_FIVE]

## [base points, base mult, points per level, mult per level]
const BASE := {
	HIGH_CARD: [5, 1, 10, 1],
	PAIR: [10, 2, 15, 1],
	TWO_PAIR: [20, 2, 20, 1],
	THREE_KIND: [30, 3, 20, 2],
	STRAIGHT: [30, 4, 30, 3],
	FLUSH: [35, 4, 15, 2],
	FULL_HOUSE: [40, 4, 25, 2],
	FOUR_KIND: [60, 7, 30, 3],
	STRAIGHT_FLUSH: [100, 8, 40, 4],
	FIVE_KIND: [120, 12, 35, 3],
	FLUSH_HOUSE: [140, 14, 40, 4],
	FLUSH_FIVE: [160, 16, 50, 3],
}
