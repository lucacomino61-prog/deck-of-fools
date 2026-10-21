class_name Shows
extends RefCounted
## Score targets per town. Each town has a matinee (×1), an evening show (×1.5) and a
## patron (×2 unless the patron says otherwise). Higher stakes switch to a steeper row.

const MATINEE := 0
const EVENING := 1
const PATRON := 2
const FINAL_TOWN := 8

const SIZE := [1.0, 1.5, 2.0]

## Base target for towns 1–8, one row per scaling level.
const TARGETS := [
	[300, 800, 2000, 5000, 11000, 20000, 35000, 50000],
	[300, 900, 2600, 8000, 20000, 36000, 60000, 100000],
	[300, 1000, 3200, 9000, 25000, 60000, 110000, 200000],
]


static func base_target(town: int, scaling: int) -> float:
	var row: Array = TARGETS[clampi(scaling, 1, TARGETS.size()) - 1]
	if town <= FINAL_TOWN:
		return float(row[maxi(town, 1) - 1])
	# Endless mode: grows faster every town. Placeholder curve, to be tuned with real content.
	var extra := town - FINAL_TOWN
	return floorf(float(row[FINAL_TOWN - 1]) * pow(2.0, extra) * (1.0 + 0.15 * extra * extra))
