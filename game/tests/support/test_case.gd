class_name TestCase
extends RefCounted
## Base for rules tests: checks record failures instead of stopping, plus card helpers.

const RANKS := {"2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9,
	"T": 10, "J": 11, "Q": 12, "K": 13, "A": 14}
const SUITS := {"S": 0, "H": 1, "C": 2, "D": 3}

var failures: Array[String] = []
var checks := 0
var _next_id := 1000


func eq(actual: Variant, expected: Variant, what := "") -> void:
	checks += 1
	var same: bool
	if _is_number(actual) and _is_number(expected):
		same = is_equal_approx(float(actual), float(expected))
	else:
		same = typeof(actual) == typeof(expected) and actual == expected
	if not same:
		failures.append("%s: expected %s, got %s" % [what, var_to_str(expected), var_to_str(actual)])


func ok(condition: bool, what := "") -> void:
	checks += 1
	if not condition:
		failures.append(what)


## Cards from a spec like "KH KS 2C:enh_wild" (rank, suit, optional enhancement id).
func cards(spec: String) -> Array[PlayingCard]:
	var out: Array[PlayingCard] = []
	for token in spec.split(" ", false):
		var parts := token.split(":")
		var card := PlayingCard.make(_next_id, RANKS[parts[0][0]], SUITS[parts[0][1]])
		_next_id += 1
		if parts.size() > 1:
			card.enhancement = parts[1]
		out.append(card)
	return out


## Pins this town's Favors (to the test Favor, +5 ducats) and Patron (the test one that
## debuffs Hearts), so a test about one card isn't changed by whichever real Favor or
## Patron the seed draws.
func pin_town(run: RunState) -> void:
	run.town_favors.assign(["favor_cash", "favor_cash"])
	run.town_favor_notes.assign(["", ""])
	run.town_patron = "patron_hearts"


func labels(list: Array) -> Array:
	return list.map(func(c: PlayingCard) -> String: return c.label())


func ids(list: Array) -> Array:
	return list.map(func(c: PlayingCard) -> int: return c.id)


func _is_number(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT
