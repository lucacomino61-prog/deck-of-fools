class_name ScoreContext
extends RefCounted
## One played hand being scored. Effects change points and mult through the methods
## below, and each change is logged in `events` with the running totals, so the UI can
## replay the scoring step by step.

var run: RunState
var hand_type := ""
var contains: Dictionary = {}
var played: Array[PlayingCard] = []
var scoring: Array[PlayingCard] = []
var held: Array[PlayingCard] = []
var points := 0.0
var mult := 0.0
var total := 0.0
var events: Array[Dictionary] = []
## Cards an effect destroyed (e.g. a shattering enhancement); removed from the deck after scoring.
var destroyed: Array[PlayingCard] = []
## Notes rules leave for after scoring, e.g. "beat": whether the Scenario's beat was hit.
var flags: Dictionary = {}


func has(hand: String) -> bool:
	return bool(contains.get(hand, false))


## While a duo (Lazzo) fires its two Jesters, every amount below grows by run.duo_scale.
func add_points(amount: float, source: String, card_id := -1) -> void:
	if run != null:
		amount = run.duo_amount(amount, 5.0)
	points += amount
	_log("points", amount, source, card_id)


func add_mult(amount: float, source: String, card_id := -1) -> void:
	if run != null:
		amount = run.duo_amount(amount, 1.0)
	mult += amount
	_log("mult", amount, source, card_id)


func x_mult(factor: float, source: String, card_id := -1) -> void:
	if run != null:
		factor = run.duo_factor(factor)
	mult *= factor
	_log("xmult", factor, source, card_id)


func add_ducats(amount: int, source: String, card_id := -1) -> void:
	amount = roundi(run.duo_amount(amount, 1.0))
	run.ducats += amount
	_log("ducats", amount, source, card_id)


## The usual effect shape: some points, some mult, then an optional ×mult.
func bonus(add_pts: float, add_mlt: float, times_mlt: float, source: String, card_id := -1) -> void:
	if add_pts != 0.0:
		add_points(add_pts, source, card_id)
	if add_mlt != 0.0:
		add_mult(add_mlt, source, card_id)
	if times_mlt != 1.0:
		x_mult(times_mlt, source, card_id)


## Points and Mult trade places.
func swap(source: String) -> void:
	var was := points
	points = mult
	mult = was
	_log("swap", 0.0, source, -1)


func note(kind: String, source: String, card_id := -1) -> void:
	_log(kind, 0.0, source, card_id)


func _log(kind: String, amount: float, source: String, card_id: int) -> void:
	events.append({"t": kind, "v": amount, "src": source, "card": card_id, "points": points, "mult": mult})


func summary() -> Dictionary:
	return {
		"hand": hand_type,
		"points": points,
		"mult": mult,
		"total": total,
		"scoring": scoring.map(func(c: PlayingCard) -> int: return c.id),
		"events": events.duplicate(true),
	}
