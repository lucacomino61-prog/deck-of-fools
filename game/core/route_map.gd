class_name RouteMap
extends RefCounted
## The Map of Italy (batch 12): a run's route, one row per town. Row 1 is the deck's home
## (Palermo on a Grand Tour), the middle rows hold three cities each along a loop across the
## real map (out from home towards the far side of Italy, then back up to Venezia), and the
## last row (8, or 16 on a Grand Tour) is always Venezia for Carnevale. Each city has roads to the one or two nearest
## cities of the next row, and every city can be reached. Endless play adds rows drawn from
## all 24 cities. Everything comes from the run's "route" stream, so a seed always draws the
## same map.

const ROWS := 8
const PER_ROW := 3
## How far (in degrees) a row's cities may wander from the line home → Venezia, and how many
## of the nearest candidates a row picks its three from.
const SPREAD := 1.2
const NEAREST := 5
## The middle of mainland Italy (longitude, latitude).
const CENTRE := Vector2(12.6, 42.4)
## A Grand Tour's way up Italy between Palermo and Venezia: Sicily's east, Naples, Rome,
## Tuscany, Liguria, Piedmont, Lombardy, the Veneto. Its towns are spread evenly along it.
const GRAND_WAY := [Vector2(15.3, 38.6), Vector2(14.6, 41.0), Vector2(12.5, 41.9), Vector2(11.3, 43.5),
	Vector2(9.6, 44.0), Vector2(7.8, 45.0), Vector2(9.5, 45.6), Vector2(10.9, 45.3)]


## The route from `home` to `last` (Venezia, or a campaign chapter's city; it can be home
## again, a loop), `rows` towns long. A Grand Tour's 16 rows are more than Italy has cities,
## so its rows may come back to a city, just not the row before's; it climbs the west coast
## from Palermo, then crosses the north to Venezia.
static func plan(run: RunState, home: String, last := CityCards.VENEZIA, rows := ROWS) -> Array:
	var r := run.rng("route")
	var used := {home: true, last: true}
	var start := _pos(home)
	var goal := _pos(last)
	# The loop bends round a point on the far side of Italy from home.
	var turn := CENTRE + (CENTRE - start) * 0.9
	turn = Vector2(clampf(turn.x, 8.0, 17.0), clampf(turn.y, 38.5, 46.0))
	var way: Array = [start]
	way.append_array(GRAND_WAY)
	way.append(goal)
	var route: Array = [[{"city": home, "to": []}]]
	for row in range(1, rows - 1):
		var t := float(row) / float(rows - 1)
		var on_loop := start * (1.0 - t) * (1.0 - t) + turn * 2.0 * (1.0 - t) * t + goal * t * t
		if rows > ROWS:
			on_loop = _along(way, t)
		var aim := on_loop + Vector2((r.next_float() - 0.5) * 2.0 * SPREAD, (r.next_float() - 0.5) * 2.0 * SPREAD)
		if rows > ROWS:
			used = {home: true, last: true}
			for node in route[row - 1]:
				used[node["city"]] = true
		route.append(_row_near(r, aim, used))
	route.append([{"city": last, "to": []}])
	for row in range(0, rows - 1):
		_connect(r, route[row], route[row + 1])
	return route


## Adds one more row (endless play): three cities other than the last row's, anywhere.
static func extend(run: RunState, route: Array) -> void:
	var r := run.rng("route")
	var last: Array = route[route.size() - 1]
	var used := {}
	for node in last:
		used[node["city"]] = true
	var aim := Vector2(10.0 + r.next_float() * 6.0, 38.5 + r.next_float() * 7.0)
	var row := _row_near(r, aim, used)
	_connect(r, last, row)
	route.append(row)


## Three unused cities near `aim`, picked at random from the nearest few, west to east.
static func _row_near(r: ZRng, aim: Vector2, used: Dictionary) -> Array:
	var free := ContentDB.pool("city", func(d: ContentDef) -> bool: return not used.has(d.id))
	free.sort_custom(func(a: ContentDef, b: ContentDef) -> bool:
		return _pos(a.id).distance_to(aim) < _pos(b.id).distance_to(aim))
	var near := free.slice(0, mini(NEAREST, free.size()))
	var picked: Array = []
	while picked.size() < PER_ROW and not near.is_empty():
		var d: ContentDef = near.pop_at(r.below(near.size()))
		picked.append(d.id)
		used[d.id] = true
	picked.sort_custom(func(a: String, b: String) -> bool: return _pos(a).x < _pos(b).x)
	return picked.map(func(id: String) -> Dictionary: return {"city": id, "to": []})


## Roads from each city to its nearest city in the next row (and, half the time, the second
## nearest); then every city in the next row that no road reaches gets one from its nearest.
static func _connect(r: ZRng, from_row: Array, to_row: Array) -> void:
	for node in from_row:
		var by_distance := range(to_row.size())
		by_distance.sort_custom(func(a: int, b: int) -> bool:
			return _pos(node["city"]).distance_to(_pos(to_row[a]["city"])) < _pos(node["city"]).distance_to(_pos(to_row[b]["city"])))
		var roads: Array = [by_distance[0]]
		if by_distance.size() > 1 and r.chance(0.5):
			roads.append(by_distance[1])
		roads.sort()
		node["to"] = roads
	for j in to_row.size():
		var reached := from_row.any(func(n: Dictionary) -> bool: return (n["to"] as Array).has(j))
		if not reached:
			var nearest: Dictionary = from_row[0]
			for n in from_row:
				if _pos(n["city"]).distance_to(_pos(to_row[j]["city"])) < _pos(nearest["city"]).distance_to(_pos(to_row[j]["city"])):
					nearest = n
			(nearest["to"] as Array).append(j)
			(nearest["to"] as Array).sort()


## The point `t` (0 to 1) of the way along a line through `points`, by distance.
static func _along(points: Array, t: float) -> Vector2:
	var total := 0.0
	for i in range(1, points.size()):
		total += (points[i] as Vector2).distance_to(points[i - 1])
	var left := t * total
	for i in range(1, points.size()):
		var a: Vector2 = points[i - 1]
		var b: Vector2 = points[i]
		var d := a.distance_to(b)
		if left <= d or i == points.size() - 1:
			return a.lerp(b, clampf(left / maxf(d, 0.0001), 0.0, 1.0))
		left -= d
	return points[points.size() - 1]


## A city's place as (longitude, latitude).
static func _pos(city_id: String) -> Vector2:
	var d := ContentDB.get_def(city_id)
	return Vector2(float(d.data["lon"]), float(d.data["lat"])) if d != null else Vector2.ZERO
