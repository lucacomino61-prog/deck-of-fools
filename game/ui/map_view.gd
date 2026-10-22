class_name MapView
extends Control
## The Map of Italy (batch 12), drawn from a simplified coastline: the route's roads, the
## cities visited (gold), where the troupe is (a ring, with its wagon beside it, batch 13),
## and the cities a road leads to next (glowing, tappable). A city where a rematch waits
## wears a red ribbon, the nemesis a black seal, a campaign chapter's Patron a gold crown.
## Tapping one emits city_tapped with its column in the next row.

signal city_tapped(col: int)

## Mainland, Sicily and Sardinia as (longitude, latitude) points, clockwise.
const MAINLAND := [
	Vector2(7.53, 43.78), Vector2(8.2, 43.9), Vector2(8.9, 44.4), Vector2(9.85, 44.07), Vector2(10.25, 43.6),
	Vector2(10.5, 42.95), Vector2(11.1, 42.4), Vector2(11.8, 42.05), Vector2(12.3, 41.7), Vector2(12.95, 41.3),
	Vector2(13.6, 41.25), Vector2(14.05, 40.8), Vector2(14.4, 40.6), Vector2(14.75, 40.67), Vector2(15.0, 40.25),
	Vector2(15.65, 40.05), Vector2(15.8, 39.5), Vector2(16.05, 38.9), Vector2(15.65, 38.25), Vector2(15.95, 37.92),
	Vector2(16.55, 38.45), Vector2(17.1, 38.9), Vector2(17.15, 39.4), Vector2(16.5, 39.75), Vector2(16.85, 40.4),
	Vector2(17.25, 40.45), Vector2(17.9, 40.3), Vector2(18.35, 39.8), Vector2(18.5, 40.15), Vector2(17.95, 40.65),
	Vector2(16.87, 41.13), Vector2(16.1, 41.4), Vector2(15.9, 41.6), Vector2(16.15, 41.9), Vector2(15.4, 41.95),
	Vector2(14.75, 42.1), Vector2(14.2, 42.45), Vector2(13.85, 42.95), Vector2(13.5, 43.6), Vector2(12.6, 44.05),
	Vector2(12.25, 44.45), Vector2(12.4, 45.0), Vector2(12.25, 45.25), Vector2(12.35, 45.45), Vector2(13.0, 45.65),
	Vector2(13.75, 45.65), Vector2(13.9, 45.6), Vector2(13.7, 46.5), Vector2(12.7, 46.65), Vector2(12.2, 47.0),
	Vector2(11.0, 46.8), Vector2(10.45, 46.55), Vector2(10.05, 46.4), Vector2(9.3, 46.5), Vector2(8.9, 45.95),
	Vector2(8.45, 46.25), Vector2(7.85, 45.95), Vector2(7.0, 45.8), Vector2(6.8, 45.2), Vector2(7.05, 44.85),
	Vector2(6.9, 44.4),
]
const SICILY := [
	Vector2(12.4, 37.8), Vector2(12.6, 38.1), Vector2(13.35, 38.15), Vector2(14.0, 38.02), Vector2(15.65, 38.27),
	Vector2(15.2, 37.6), Vector2(15.08, 37.5), Vector2(15.3, 37.1), Vector2(15.1, 36.7), Vector2(14.4, 36.8),
	Vector2(13.58, 37.25), Vector2(12.6, 37.6),
]
const SARDINIA := [
	Vector2(8.2, 41.1), Vector2(9.2, 41.25), Vector2(9.7, 40.9), Vector2(9.65, 40.1), Vector2(9.6, 39.3),
	Vector2(9.05, 39.2), Vector2(8.4, 38.9), Vector2(8.35, 39.7), Vector2(8.5, 40.5),
]
## The part of the world shown: longitude 6.5–18.7, latitude 36.5–47.2, with longitude
## squeezed as it is at Italy's latitude.
const WEST := 6.5
const NORTH := 47.2
const LON_SCALE := 0.743

var run: RunState
var selected := -1
var _scale := 1.0
var _offset := Vector2.ZERO
var _pulse := 0.0
## Painted textures for the land and the sea (art/map/land, art/map/sea), once they exist;
## held here so they live as long as the map draws them.
var _land: Texture2D
var _sea: Texture2D
## The wagon on its way to another city (roll_wagon): where it's heading and how far.
var _roll_to := ""
var _roll := 0.0


func _init(for_run: RunState) -> void:
	run = for_run
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_land = CardView.painting("map", "land")
	_sea = CardView.painting("map", "sea")


func _ready() -> void:
	resized.connect(_fit)
	_fit()
	if not Settings.reduce_motion:
		var t := create_tween().set_loops()
		t.tween_method(_set_pulse, 0.0, 1.0, 0.9)
		t.tween_method(_set_pulse, 1.0, 0.0, 0.9)


func _set_pulse(v: float) -> void:
	_pulse = v
	queue_redraw()


## Rolls the troupe's wagon along the road to `dest` (about 1.2 s); returns when it's there.
func roll_wagon(dest: String) -> void:
	_roll_to = dest
	var t := create_tween()
	t.tween_method(func(v: float) -> void:
		_roll = v
		queue_redraw(), 0.0, 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished


func _fit() -> void:
	var world := Vector2((18.7 - WEST) * LON_SCALE, NORTH - 36.5)
	_scale = minf(size.x / world.x, size.y / world.y)
	_offset = (size - world * _scale) / 2.0
	queue_redraw()


## A (longitude, latitude) point on screen.
func project(lonlat: Vector2) -> Vector2:
	return _offset + Vector2((lonlat.x - WEST) * LON_SCALE, NORTH - lonlat.y) * _scale


func city_point(city_id: String) -> Vector2:
	var d := ContentDB.get_def(city_id)
	return project(Vector2(float(d.data["lon"]), float(d.data["lat"]))) if d != null else Vector2.ZERO


func _gui_input(event: InputEvent) -> void:
	var at := Vector2.INF
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		at = event.position
	elif event is InputEventScreenTouch and event.pressed:
		at = event.position
	if at == Vector2.INF or run.route_row + 1 >= run.route.size():
		return
	var next_row: Array = run.route[run.route_row + 1]
	var best := -1
	var best_d := 18.0
	for col in run.roads():
		var d := city_point(next_row[col]["city"]).distance_to(at)
		if d < best_d:
			best_d = d
			best = col
	if best >= 0:
		accept_event()
		city_tapped.emit(best)


func _draw() -> void:
	# Sea and land: painted when the textures exist, plain colours until then.
	if _sea != null:
		var src_h := minf(_sea.get_height(), _sea.get_width() * size.y / size.x)
		draw_texture_rect_region(_sea, Rect2(Vector2.ZERO, size), Rect2(0, (_sea.get_height() - src_h) / 2.0, _sea.get_width(), src_h))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color("10223a"))
		for i in 6:
			draw_rect(Rect2(0, i * size.y / 6.0, size.x, size.y / 6.0), Color(0.3, 0.5, 0.8, 0.012 * i))
	for shape in [MAINLAND, SICILY, SARDINIA]:
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		for p in shape:
			var at := project(p)
			pts.append(at)
			uvs.append(at / size)
		if _land != null:
			draw_colored_polygon(pts, Color.WHITE, uvs, _land)
		else:
			draw_colored_polygon(pts, Color("e8d6ae"))
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, Color("8a6a3a"), 1.2, true)
	# Roads: the whole route, done roads in gold, the ones ahead dashed.
	for row in run.route.size() - 1:
		for col in (run.route[row] as Array).size():
			var node: Dictionary = run.route[row][col]
			for to in node["to"]:
				var a := city_point(node["city"])
				var b := city_point(run.route[row + 1][to]["city"])
				var on_path := row < run.route_row and _visited(row, col) and _visited(row + 1, to)
				var from_here := row == run.route_row and col == run.route_col
				if on_path:
					draw_line(a, b, UiTheme.GOLD, 2.0, true)
				elif from_here:
					draw_line(a, b, Color(UiTheme.GOLD, 0.55 + 0.35 * _pulse), 1.6, true)
				elif row >= run.route_row:
					draw_dashed_line(a, b, Color("6a4a2a", 0.7), 1.0, 3.0, true)
	# Cities, then their names (where the troupe is and where it can go first).
	var labels: Array = []
	for row in run.route.size():
		for col in (run.route[row] as Array).size():
			var city_id: String = run.route[row][col]["city"]
			var p := city_point(city_id)
			var here := row == run.route_row and col == run.route_col
			var next := row == run.route_row + 1 and run.roads().has(col) and run.phase == RunState.Phase.MAP
			var visited := row < run.route_row and _visited(row, col)
			var colour := Color("6a4a2a")
			var radius := 2.4
			if visited:
				colour = UiTheme.GOLD.darkened(0.15)
			if next:
				colour = Color("ffd27a") if col == selected else Color("f0b84a")
				radius = 3.4 + (1.2 * _pulse if col != selected else 1.4)
				draw_circle(p, radius + 4.0, Color(1.0, 0.8, 0.4, 0.18))
			if here:
				draw_arc(p, 6.0 + 1.5 * _pulse, 0, TAU, 20, UiTheme.GOLD, 1.6, true)
				colour = UiTheme.GOLD
				radius = 3.6
			draw_circle(p, radius + 1.0, Color("2a1a10"))
			draw_circle(p, radius, colour)
			if row == run.route_row + 1:
				_draw_grudge(p, row, col)
			if here or next or visited or row == run.route.size() - 1:
				labels.append([0 if here else (1 if next else 2), city_id, p, here or next])
	# The troupe's wagon beside its city, or rolling along the road to the next.
	var from := city_point(run.city)
	var wagon_at := from
	if _roll_to != "":
		wagon_at = from.lerp(city_point(_roll_to), _roll) + Vector2(0, -sin(_roll * PI * 6.0) * 0.8)
	var k := clampf(_scale / 45.0, 0.3, 0.6)
	WagonArt.draw(self, wagon_at + Vector2(-14, 2) * k, k, WagonArt.worn_paint(), WagonArt.worn_trims(), _roll * 12.0)
	labels.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var font := UiTheme.title_font
	var placed: Array[Rect2] = []
	for label in labels:
		var name := UiTheme.name_of(label[1])
		var p: Vector2 = label[2]
		var bright: bool = label[3]
		var fs := 9 if bright else 7
		var text := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		# Right of the dot, left, above, below: the first spot that's free and on the map.
		var spots: Array[Vector2] = [Vector2(7, 3), Vector2(-7 - text.x, 3), Vector2(-text.x / 2.0, -7), Vector2(-text.x / 2.0, 13)]
		var at: Vector2 = p + spots[0]
		for spot: Vector2 in spots:
			var box := Rect2(p + spot - Vector2(0, text.y * 0.8), text)
			if box.position.x >= 0 and box.end.x <= size.x and not placed.any(func(other: Rect2) -> bool: return other.intersects(box)):
				at = p + spot
				break
		placed.append(Rect2(at - Vector2(0, text.y * 0.8), text))
		draw_string_outline(font, at, name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.85))
		draw_string(font, at, name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("fff2d6") if bright else Color("e8d6ae"))


## A mark over a city of the next row where a Patron is already waiting (batch 13): the
## nemesis's black seal, a rematch's red ribbon, a chapter's story Patron's gold crown.
func _draw_grudge(p: Vector2, row: int, col: int) -> void:
	var waiting := run.patron_waiting(row, col)
	if waiting == "":
		return
	var at := p + Vector2(0, -10)
	if run.town == run.nemesis_town() and waiting == run.nemesis_patron():
		draw_circle(at, 4.2, Color("1a1014"))
		draw_arc(at, 4.2, 0, TAU, 16, Color("c0a060"), 0.8, true)
		draw_line(at + Vector2(-2, -2), at + Vector2(2, 2), Color("c0a060"), 0.9, true)
		draw_line(at + Vector2(2, -2), at + Vector2(-2, 2), Color("c0a060"), 0.9, true)
	elif int(run.rematch.get("town", -1)) == run.town:
		draw_colored_polygon(PackedVector2Array([at + Vector2(-4, -3), at + Vector2(4, -3), at + Vector2(4, 2), at + Vector2(0, 0), at + Vector2(-4, 2)]), Color("c8283a"))
	elif run.chapter != "" and run.town == Shows.FINAL_TOWN:
		draw_colored_polygon(PackedVector2Array([at + Vector2(-4, 2), at + Vector2(-4, -2), at + Vector2(-2, 0), at + Vector2(0, -4),
			at + Vector2(2, 0), at + Vector2(4, -2), at + Vector2(4, 2)]), UiTheme.GOLD)


## Whether the troupe's road went through this city (rows behind it).
func _visited(row: int, col: int) -> bool:
	return run.path.size() > row and run.path[row] == col
