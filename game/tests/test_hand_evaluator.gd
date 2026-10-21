extends TestCase


func _check(spec: String, hand: String, scoring: String, options := {}) -> void:
	var r := HandEvaluator.evaluate(cards(spec), options)
	eq(r.type, hand, spec + " type")
	eq(labels(r.scoring), Array(scoring.split(" ", false)), spec + " scoring")


func test_every_hand_type() -> void:
	_check("AS", HandTable.HIGH_CARD, "AS")
	_check("2H 9C KD 4S 7H", HandTable.HIGH_CARD, "KD")
	_check("KH KS 2C", HandTable.PAIR, "KH KS")
	_check("KH KS 2C 2D 9H", HandTable.TWO_PAIR, "KH KS 2C 2D")
	_check("7H 7S 7C 2D", HandTable.THREE_KIND, "7H 7S 7C")
	_check("5H 6S 7C 8D 9H", HandTable.STRAIGHT, "5H 6S 7C 8D 9H")
	_check("2H 7H 9H JH KH", HandTable.FLUSH, "2H 7H 9H JH KH")
	_check("3H 3S 3C 9D 9H", HandTable.FULL_HOUSE, "3H 3S 3C 9D 9H")
	_check("8H 8S 8C 8D 2H", HandTable.FOUR_KIND, "8H 8S 8C 8D")
	_check("5H 6H 7H 8H 9H", HandTable.STRAIGHT_FLUSH, "5H 6H 7H 8H 9H")
	_check("QH QS QC QD QH", HandTable.FIVE_KIND, "QH QS QC QD QH")
	_check("4H 4H 4H 9H 9H", HandTable.FLUSH_HOUSE, "4H 4H 4H 9H 9H")
	_check("AS AS AS AS AS", HandTable.FLUSH_FIVE, "AS AS AS AS AS")


func test_ace_plays_low_and_high_but_never_wraps() -> void:
	_check("AH 2S 3C 4D 5H", HandTable.STRAIGHT, "AH 2S 3C 4D 5H")
	_check("TH JS QC KD AH", HandTable.STRAIGHT, "TH JS QC KD AH")
	_check("QH KS AC 2D 3H", HandTable.HIGH_CARD, "AC")


func test_contains() -> void:
	var r := HandEvaluator.evaluate(cards("3H 3S 3C 9D 9H"))
	ok(r.contains[HandTable.PAIR], "full house contains a pair")
	ok(r.contains[HandTable.TWO_PAIR], "full house contains two pair")
	ok(r.contains[HandTable.THREE_KIND], "full house contains three of a kind")
	ok(not r.contains[HandTable.FLUSH], "no flush")
	var four := HandEvaluator.evaluate(cards("8H 8S 8C 8D 2H"))
	ok(not four.contains[HandTable.TWO_PAIR], "four of a kind is not two pair")


func test_wild_and_stone_cards() -> void:
	_check("2H 7H 9H JH KS:enh_wild", HandTable.FLUSH, "2H 7H 9H JH KS")
	_check("KH KS 5C:enh_stone", HandTable.PAIR, "KH KS 5C")
	_check("5C:enh_stone", HandTable.HIGH_CARD, "5C")


func test_rule_options() -> void:
	_check("2H 7H 9H JH KS", HandTable.FLUSH, "2H 7H 9H JH", {"flush_min": 4})
	_check("5H 6S 7C 8D KH", HandTable.STRAIGHT, "5H 6S 7C 8D", {"straight_min": 4})
	_check("3H 5S 7C 9D JH", HandTable.STRAIGHT, "3H 5S 7C 9D JH", {"straight_gap": true})
	_check("KH KS 2C", HandTable.PAIR, "KH KS 2C", {"all_score": true})
