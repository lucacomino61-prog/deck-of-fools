class_name Shows
extends RefCounted
## Score targets per town. Each town has four shows: a matinee (×1), an evening show (×1.5),
## the Gala (×1.75, added 2026-10-28) and the patron (×2 unless the patron says otherwise).
## Higher stakes switch to a steeper row. A Grand Tour stretches the same climb over more
## towns.

const MATINEE := 0
const EVENING := 1
const GALA := 2
const PATRON := 3
## A tour's towns; finale Patrons come every FINAL_TOWN towns (8, then 16 in a Grand Tour
## or endless play).
const FINAL_TOWN := 8
## The Grand Tour (2026-10-28): from Palermo to Venezia in 16 towns, its last town as hard
## as town GRAND_END of a normal tour's endless play.
const GRAND_TOWNS := 16
const GRAND_START := "c_palermo"
const GRAND_END := 10.0

const SIZE := [1.0, 1.5, 1.75, 2.0]

## Base target for towns 1–8, one row per scaling level. Towns 1–3 were raised on
## 2026-10-28 (Luca: early shows fell to one lucky hand).
const TARGETS := [
	[400, 1100, 2600, 5000, 11000, 20000, 35000, 50000],
	[400, 1200, 3200, 8000, 20000, 36000, 60000, 100000],
	[400, 1300, 3800, 9000, 25000, 60000, 110000, 200000],
]


## The base target of `town` in a tour of `towns` towns.
static func base_target(town: int, scaling: int, towns := FINAL_TOWN) -> float:
	if towns <= FINAL_TOWN:
		return floorf(_curve(float(town), scaling))
	# A longer tour climbs the same curve more slowly, then carries on from its last town.
	var step := (GRAND_END - 1.0) / float(towns - 1)
	var equivalent := 1.0 + (town - 1) * step if town <= towns else GRAND_END + (town - towns)
	return floorf(_curve(equivalent, scaling))


## The curve at a town that can fall between towns: between two of TARGETS' towns it grows
## evenly in proportion (geometrically); past town 8, the endless curve.
static func _curve(t: float, scaling: int) -> float:
	var row: Array = TARGETS[clampi(scaling, 1, TARGETS.size()) - 1]
	if t <= FINAL_TOWN:
		var low := clampi(floori(t), 1, FINAL_TOWN)
		var high := mini(low + 1, FINAL_TOWN)
		var k := t - low
		return float(row[low - 1]) * pow(float(row[high - 1]) / float(row[low - 1]), k)
	# Endless mode: grows faster every town. Placeholder curve, to be tuned with real content.
	var extra := t - FINAL_TOWN
	return float(row[FINAL_TOWN - 1]) * pow(2.0, extra) * (1.0 + 0.15 * extra * extra)
