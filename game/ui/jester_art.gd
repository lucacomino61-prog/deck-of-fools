class_name JesterArt
extends RefCounted
## Draws a Jester's portrait from its hand-made design (JesterDesigns): the backdrop and its
## pattern, the costume, the head with its mask, face and extras, the headwear, the prop in
## hand, and a corner badge for the kind of effect. Shapes are given in units of the head
## (s) around the head's centre (h), so one design fits any card size.

const INK := Color("2a2433")
const GOLD := Color("f0b84a")
const SKINS := [Color("f1c8a0"), Color("d9a27a"), Color("a86f4c"), Color("f7dcc0"), Color("7a4e34")]
const HAIRS := [Color("4a2c18"), Color("1a141f"), Color("8a5a2c"), Color("c89a4a"), Color("7a2a1a")]
const RUFF_COSTUMES := ["diamonds", "stripes", "buttons", "checks", "patches", "dots"]
const BADGES := {
	"m": Color("e0503c"), "p": Color("3f7ad8"), "x": Color("f0703a"), "d": Color("f0b84a"),
	"r": Color("4fa860"), "c": Color("8a4ad0"),
}

var canvas: CanvasItem
var w: Rect2
var h: Vector2
var s: float
var a: Color
var b: Color
var hair: Color
var bottom: float


func _init(target: CanvasItem) -> void:
	canvas = target


static func has_design(def_id: String) -> bool:
	return JesterDesigns.DESIGNS.has(def_id)


## The whole picture inside `window` (whose rounded outline is `pane`).
func draw(window: Rect2, pane: PackedVector2Array, def_id: String) -> void:
	var d: Array = JesterDesigns.DESIGNS[def_id]
	var n := absi(def_id.hash())
	w = window
	s = minf(window.size.x, window.size.y) * 0.46
	h = window.get_center() + Vector2(0, window.size.y * 0.03)
	bottom = (window.end.y - h.y) / s
	a = JesterDesigns.COLOURS[d[6]]
	b = JesterDesigns.COLOURS[d[7]]
	hair = HAIRS[n % HAIRS.size()]
	var back: Color = JesterDesigns.BACKDROPS[d[0]]
	_gradient(pane, back.lightened(0.18), back.darkened(0.3))
	_pattern(pane, str(d[1]), back)
	var mask := str(d[3])
	var skin: Color = SKINS[(n / 7) % SKINS.size()]
	if mask == "white":
		skin = Color("f6f2ea")
	elif mask == "wood":
		skin = Color("c89060")
	var extras := str(d[10]).split(" ", false)
	_hat_back(str(d[2]))
	_costume(str(d[5]))
	_head(skin)
	var covered := _mask(mask)
	_eyes(str(d[4]))
	if not covered:
		_mouth(str(d[4]))
	_extras(extras, covered, mask != "none" and mask != "white" and mask != "wood")
	_hat(str(d[2]))
	_prop(str(d[8]))
	_badge(str(d[9]))


# --- drawing helpers ---

func _at(x: float, y: float) -> Vector2:
	return h + Vector2(x, y) * s


## A shape from flat (x, y) pairs in head units.
func _pts(coords: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(0, coords.size(), 2):
		points.append(_at(coords[i], coords[i + 1]))
	return points


func _shape(coords: Array, colour: Color) -> void:
	_poly(_pts(coords), colour)


func _poly(points: PackedVector2Array, colour: Color) -> void:
	canvas.draw_colored_polygon(points, colour)
	var closed := points.duplicate()
	closed.append(points[0])
	canvas.draw_polyline(closed, colour, 0.6, true)


func _dot(at: Vector2, radius: float, colour: Color) -> void:
	canvas.draw_circle(at, radius, colour, true, -1.0, true)


func _ring(at: Vector2, radius: float, colour: Color, width := 0.8) -> void:
	canvas.draw_arc(at, radius, 0.0, TAU, 20, colour, width, true)


func _line(from: Vector2, to: Vector2, colour: Color, width := 1.0) -> void:
	canvas.draw_line(from, to, colour, width, true)


func _ellipse(at: Vector2, rx: float, ry: float, colour: Color, turn := 0.0) -> void:
	var points := PackedVector2Array()
	for k in 18:
		var t := k * TAU / 18.0
		points.append(at + Vector2(cos(t) * rx, sin(t) * ry).rotated(turn))
	_poly(points, colour)


func _gradient(points: PackedVector2Array, top: Color, low: Color) -> void:
	var y0 := INF
	var y1 := -INF
	for p in points:
		y0 = minf(y0, p.y)
		y1 = maxf(y1, p.y)
	var colours := PackedColorArray()
	for p in points:
		colours.append(top.lerp(low, (p.y - y0) / maxf(1.0, y1 - y0)))
	canvas.draw_polygon(points, colours)


## Fills the part of `shape` that lies inside `inside`.
func _clip(shape: PackedVector2Array, inside: PackedVector2Array, colour: Color) -> void:
	for piece in Geometry2D.intersect_polygons(shape, inside):
		canvas.draw_colored_polygon(piece, colour)


func _diamond(at: Vector2, half_w: float, half_h: float) -> PackedVector2Array:
	return PackedVector2Array([at + Vector2(0, -half_h), at + Vector2(half_w, 0), at + Vector2(0, half_h), at + Vector2(-half_w, 0)])


func _star(at: Vector2, radius: float, colour: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var r := radius if i % 2 == 0 else radius * 0.45
		var angle := -PI / 2.0 + i * PI / 5.0
		points.append(at + Vector2(cos(angle), sin(angle)) * r)
	_poly(points, colour)


# --- backdrop ---

func _pattern(pane: PackedVector2Array, kind: String, back: Color) -> void:
	var light := Color(back.lightened(0.45), 0.28)
	var c := w.get_center()
	var far := w.size.length()
	var shapes: Array[PackedVector2Array] = []
	match kind:
		"rays":
			for i in range(0, 16, 2):
				var a0 := i * TAU / 16.0
				var a1 := (i + 1) * TAU / 16.0
				shapes.append(PackedVector2Array([c, c + Vector2(cos(a0), sin(a0)) * far, c + Vector2(cos(a1), sin(a1)) * far]))
		"lattice":
			var cell := w.size.x / 4.0
			for row in range(-1, 7):
				for col in range(-1, 6):
					if (row + col) % 2 == 0:
						shapes.append(_diamond(w.position + Vector2(col * cell, row * cell * 1.3), cell / 2.0, cell * 0.65))
		"rings":
			for i in range(7, 0, -2):
				var ring := PackedVector2Array()
				for k in 24:
					ring.append(c + Vector2(cos(k * TAU / 24.0), sin(k * TAU / 24.0)) * w.size.x * 0.13 * i)
				shapes.append(ring)
		"stripes":
			var band := w.size.x / 5.0
			for i in range(-6, 8, 2):
				var x := w.position.x + i * band
				shapes.append(PackedVector2Array([Vector2(x, w.position.y), Vector2(x + band, w.position.y), Vector2(x + band + w.size.y, w.end.y), Vector2(x + w.size.y, w.end.y)]))
		"checks":
			var cell := w.size.x / 5.0
			for row in 7:
				for col in 6:
					if (row + col) % 2 == 0:
						var p := w.position + Vector2(col, row) * cell
						shapes.append(PackedVector2Array([p, p + Vector2(cell, 0), p + Vector2(cell, cell), p + Vector2(0, cell)]))
		"waves":
			for row in range(0, 8, 2):
				var y := w.position.y + row * w.size.y / 7.0
				var wave := PackedVector2Array()
				for k in 13:
					wave.append(Vector2(w.position.x + k * w.size.x / 12.0, y + sin(k * 1.1) * 2.5))
				for k in range(12, -1, -1):
					wave.append(Vector2(w.position.x + k * w.size.x / 12.0, y + w.size.y / 7.0 + sin(k * 1.1) * 2.5))
				shapes.append(wave)
		"curtain":
			var fold := w.size.x / 8.0
			for i in range(0, 9, 2):
				var x := w.position.x + i * fold
				shapes.append(PackedVector2Array([Vector2(x, w.position.y), Vector2(x + fold, w.position.y), Vector2(x + fold * 0.8, w.end.y), Vector2(x + fold * 0.2, w.end.y)]))
	for shape in shapes:
		_clip(shape, pane, light)
	if kind == "stars":
		for i in 9:
			var p := w.position + Vector2(fposmod(i * 0.37, 1.0) * w.size.x, fposmod(i * 0.61 + 0.1, 1.0) * w.size.y * 0.7)
			_star(p, 1.4 + (i % 3) * 0.5, Color(1, 0.95, 0.75, 0.55))
	elif kind == "dots":
		for row in 5:
			for col in 5:
				var p := w.position + Vector2((col + (0.5 if row % 2 == 1 else 0.0) + 0.25) * w.size.x / 5.0, (row + 0.5) * w.size.y / 5.0)
				_dot(p, w.size.x * 0.03, light)


# --- costume, head, face ---

func _costume(kind: String) -> void:
	var torso := _pts([-1.0, bottom, -0.62, 0.55, 0.62, 0.55, 1.0, bottom])
	if kind in ["gown", "robe", "cape"]:
		torso = _pts([-1.2, bottom, -0.62, 0.55, 0.62, 0.55, 1.2, bottom])
	_poly(torso, Color("9aa4b0") if kind == "armour" else (b if kind == "cape" else a))
	match kind:
		"diamonds":
			for row in 4:
				for col in range(-4, 5):
					if (row + col) % 2 == 0:
						_clip(_diamond(_at(col * 0.28 + (0.14 if row % 2 == 1 else 0.0), 0.7 + row * 0.25), s * 0.13, s * 0.15), torso, b)
		"stripes":
			for i in range(-5, 6, 2):
				_clip(_pts([i * 0.18, 0.5, i * 0.18 + 0.18, 0.5, i * 0.24 + 0.24, bottom, i * 0.24, bottom]), torso, b)
		"checks":
			for row in 4:
				for col in range(-4, 4):
					if (row + col) % 2 == 0:
						_clip(_pts([col * 0.25, 0.55 + row * 0.25, col * 0.25 + 0.25, 0.55 + row * 0.25, col * 0.25 + 0.25, 0.8 + row * 0.25, col * 0.25, 0.8 + row * 0.25]), torso, b)
		"dots":
			for row in 3:
				for col in range(-2, 3):
					_dot(_at(col * 0.3 + (0.15 if row % 2 == 1 else 0.0), 0.78 + row * 0.26), s * 0.06, b)
		"patches":
			_clip(_pts([-0.5, 0.7, -0.2, 0.7, -0.2, 0.98, -0.5, 0.98]), torso, b)
			_clip(_pts([0.15, 0.85, 0.5, 0.85, 0.5, 1.15, 0.15, 1.15]), torso, JesterDesigns.COLOURS["cream"])
			_clip(_pts([-0.2, 1.1, 0.1, 1.1, 0.1, 1.4, -0.2, 1.4]), torso, b.darkened(0.2))
		"buttons":
			for i in 3:
				_dot(_at(0, 0.78 + i * 0.26), s * 0.08, b)
		"sash":
			_clip(_pts([-1.1, 0.45, -0.75, 0.45, 0.85, bottom + 0.1, 0.5, bottom + 0.1]), torso, b)
			_dot(_at(0.3, 0.75), s * 0.05, GOLD)
			_dot(_at(0.3, 0.95), s * 0.05, GOLD)
		"robe":
			_shape([-0.3, 0.55, 0.0, 1.0, -0.12, 0.55], b)
			_shape([0.3, 0.55, 0.12, 0.55, 0.0, 1.0], b)
			_line(_at(0, 1.0), _at(0, bottom), b.darkened(0.2), 0.8)
		"apron":
			_clip(_pts([-0.42, 0.85, 0.42, 0.85, 0.5, bottom, -0.5, bottom]), torso, b)
			_line(_at(-0.42, 0.85), _at(-0.62, 0.6), b, 0.8)
			_line(_at(0.42, 0.85), _at(0.62, 0.6), b, 0.8)
		"cape":
			_clip(_pts([-0.32, 0.55, 0.32, 0.55, 0.42, bottom, -0.42, bottom]), torso, a)
		"armour":
			for i in 3:
				_line(_at(-0.8, 0.8 + i * 0.25), _at(0.8, 0.8 + i * 0.25), Color("6a7480"), 0.8)
			_clip(_pts([-0.2, 0.55, 0.2, 0.55, 0.2, bottom, -0.2, bottom]), torso, b)
		"gown":
			_shape([-0.45, 0.55, 0.45, 0.55, 0.3, 0.98, -0.3, 0.98], b)
			_dot(_at(0, 0.62), s * 0.06, GOLD)
		"plain":
			_line(_at(0, 0.6), _at(0, bottom), b, 0.8)
			_dot(_at(0, 0.8), s * 0.04, b)
			_dot(_at(0, 1.0), s * 0.04, b)
	if kind in RUFF_COSTUMES:
		var pleats := 6
		for i in pleats:
			var x0 := -0.6 + 1.2 * i / pleats
			var x1 := x0 + 1.2 / pleats
			_shape([x0, 0.42, x1, 0.42, (x0 + x1) / 2.0, 0.72], Color.WHITE if i % 2 == 0 else Color("dcd4c4"))
	else:
		_shape([-0.25, 0.42, 0.0, 0.66, 0.25, 0.42, 0.0, 0.5], JesterDesigns.COLOURS["cream"])


func _head(skin: Color) -> void:
	_dot(h, s * 0.42, skin)
	canvas.draw_arc(h, s * 0.42, 0.0, TAU, 24, skin.darkened(0.3), 0.7, true)
	_dot(_at(0, 0.08), s * 0.05, skin.darkened(0.2))


## Draws the mask; true when it covers the mouth too.
func _mask(kind: String) -> bool:
	match kind:
		"half", "nose":
			var colour := Color("1a141f") if kind == "half" else Color("8a5a2c")
			_shape([-0.42, -0.04, -0.38, -0.3, 0.0, -0.38, 0.38, -0.3, 0.42, -0.04, 0.2, 0.1, 0.07, 0.2, -0.07, 0.2, -0.2, 0.1], colour)
			if kind == "nose":
				_shape([0.0, 0.0, 0.62, 0.1, 0.06, 0.2], colour.darkened(0.15))
			else:
				_dot(_at(0.28, -0.24), s * 0.04, Color("3a3040"))
		"domino":
			_shape([-0.46, -0.16, -0.2, -0.2, 0.0, -0.12, 0.2, -0.2, 0.46, -0.16, 0.3, 0.06, 0.0, 0.0, -0.3, 0.06], b)
			_dot(_at(-0.42, -0.2), s * 0.04, GOLD)
			_dot(_at(0.42, -0.2), s * 0.04, GOLD)
		"bauta":
			_shape([-0.42, -0.36, 0.42, -0.36, 0.44, 0.05, 0.32, 0.5, 0.0, 0.64, -0.32, 0.5, -0.44, 0.05], Color("f6f2ea"))
			_line(_at(-0.4, -0.3), _at(0.4, -0.3), GOLD, 0.8)
			return true
		"volto", "gold":
			var face := Color("f6f2ea") if kind == "volto" else GOLD
			_ellipse(h, s * 0.43, s * 0.47, face)
			canvas.draw_arc(_at(-0.15, -0.3), s * 0.12, PI, TAU, 8, GOLD.darkened(0.3), 0.8, true)
			canvas.draw_arc(_at(0.15, -0.3), s * 0.12, PI, TAU, 8, GOLD.darkened(0.3), 0.8, true)
			_line(_at(-0.08, 0.26), _at(0.08, 0.26), Color("c04050"), 1.0)
			return true
		"moretta":
			_ellipse(h, s * 0.4, s * 0.46, Color("1a141f"))
			return true
		"wood":
			_line(_at(0.0, 0.06), _at(0.62, -0.02), Color("a87040"), maxf(1.0, s * 0.07))
			_dot(_at(-0.28, 0.14), s * 0.07, Color("d8584a"))
			_dot(_at(0.28, 0.14), s * 0.07, Color("d8584a"))
	return false


func _eyes(face: String) -> void:
	for side in [-1.0, 1.0]:
		var e := _at(side * 0.16, -0.05)
		if face == "sleepy" or (face == "wink" and side > 0):
			_line(e + Vector2(-s * 0.07, 0), e + Vector2(s * 0.07, 0), INK, 1.0)
		else:
			_dot(e, s * 0.075, Color.WHITE)
			_dot(e + Vector2(0, s * 0.01), s * 0.042, INK)
		if face == "shout":
			_line(e + Vector2(side * s * 0.09, -s * 0.15), e + Vector2(-side * s * 0.08, -s * 0.09), INK, 1.0)
		elif face == "tear" or face == "frown":
			_line(e + Vector2(side * s * 0.09, -s * 0.09), e + Vector2(-side * s * 0.08, -s * 0.15), INK, 0.9)
	if face == "tear":
		var t := _at(0.18, 0.1)
		_shape([0.18, 0.04, 0.23, 0.16, 0.18, 0.2, 0.13, 0.16], Color("6ab0f0"))
		_dot(t + Vector2(0, s * 0.07), s * 0.045, Color("6ab0f0"))


func _mouth(face: String) -> void:
	match face:
		"smile", "wink":
			canvas.draw_arc(_at(0, 0.1), s * 0.18, 0.35, PI - 0.35, 10, INK, 1.0, true)
		"grin":
			var grin := PackedVector2Array()
			for k in 9:
				var t := k * PI / 8.0
				grin.append(_at(0, 0.16) + Vector2(cos(t) * s * 0.22, sin(t) * s * 0.18))
			_poly(grin, Color("8a2030"))
			_line(_at(-0.18, 0.17), _at(0.18, 0.17), Color.WHITE, maxf(1.0, s * 0.05))
		"frown", "tear":
			canvas.draw_arc(_at(0, 0.34), s * 0.14, PI + 0.5, TAU - 0.5, 10, INK, 1.0, true)
		"o":
			_dot(_at(0, 0.22), s * 0.07, Color("8a2030"))
		"smirk":
			_line(_at(-0.12, 0.22), _at(0.15, 0.15), INK, 1.0)
		"sleepy":
			_line(_at(-0.06, 0.22), _at(0.06, 0.22), INK, 1.0)
		"shout":
			_ellipse(_at(0, 0.24), s * 0.12, s * 0.1, Color("8a2030"))


func _extras(extras: PackedStringArray, covered: bool, masked: bool) -> void:
	for extra in extras:
		match extra:
			"moustache":
				if not covered:
					_ellipse(_at(-0.11, 0.13), s * 0.13, s * 0.05, Color("3a2416"), 0.25)
					_ellipse(_at(0.11, 0.13), s * 0.13, s * 0.05, Color("3a2416"), -0.25)
			"beard":
				if not covered:
					_shape([-0.36, 0.12, -0.2, 0.3, 0.2, 0.3, 0.36, 0.12, 0.3, 0.45, 0.0, 0.66, -0.3, 0.45], hair.lerp(Color("8a8a98"), 0.3))
			"goatee":
				if not covered:
					_shape([-0.08, 0.32, 0.08, 0.32, 0.0, 0.52], hair)
			"stubble":
				for i in 7:
					_dot(_at(-0.24 + i * 0.08, 0.3 + (i % 2) * 0.06), s * 0.02, Color(0.2, 0.15, 0.15, 0.5))
			"glasses":
				for side in [-1.0, 1.0]:
					_ring(_at(side * 0.16, -0.05), s * 0.12, INK, 0.8)
				_line(_at(-0.04, -0.06), _at(0.04, -0.06), INK, 0.8)
			"monocle":
				_ring(_at(0.16, -0.05), s * 0.13, GOLD, 0.9)
				_line(_at(0.27, 0.0), _at(0.36, 0.4), GOLD, 0.6)
			"freckles":
				for i in 3:
					_dot(_at(-0.28 + i * 0.05, 0.08 + (i % 2) * 0.04), s * 0.022, Color("a8603a"))
					_dot(_at(0.18 + i * 0.05, 0.08 + (i % 2) * 0.04), s * 0.022, Color("a8603a"))
			"blush":
				if not masked:
					_dot(_at(-0.25, 0.12), s * 0.07, Color(0.92, 0.4, 0.45, 0.5))
					_dot(_at(0.25, 0.12), s * 0.07, Color(0.92, 0.4, 0.45, 0.5))
			"earring":
				_dot(_at(-0.44, 0.14), s * 0.05, GOLD)
			"rednose":
				_dot(_at(0, 0.07), s * 0.1, Color("d8433a"))
			"mole":
				_dot(_at(0.2, 0.24), s * 0.025, INK)


# --- headwear ---

func _hat_back(kind: String) -> void:
	match kind:
		"hood":
			_dot(_at(0, -0.04), s * 0.6, a.darkened(0.35))
			_shape([-0.6, 0.0, 0.6, 0.0, 0.8, 0.6, -0.8, 0.6], a.darkened(0.35))
		"longhair":
			_dot(_at(0, -0.08), s * 0.52, b.darkened(0.2))
			_shape([-0.52, -0.05, 0.52, -0.05, 0.58, 0.62, -0.58, 0.62], b.darkened(0.2))
		"wig":
			for i in 4:
				_dot(_at(-0.46, -0.22 + i * 0.2), s * 0.15, Color("e4e4ee"))
				_dot(_at(0.46, -0.22 + i * 0.2), s * 0.15, Color("e4e4ee"))


func _hat(kind: String) -> void:
	match kind:
		"cap2", "cap3", "cap4":
			_cap(int(kind.substr(3)))
		"bicorne":
			_shape([-0.8, -0.22, -0.42, -0.64, 0.0, -0.52, 0.42, -0.64, 0.8, -0.22, 0.0, -0.32], a.darkened(0.5))
			_line(_at(-0.7, -0.27), _at(0.7, -0.27), GOLD, 0.8)
		"tricorne":
			_shape([-0.75, -0.25, -0.5, -0.64, 0.0, -0.5, 0.5, -0.64, 0.75, -0.25, 0.0, -0.18], a.darkened(0.45))
			canvas.draw_polyline(_pts([-0.75, -0.25, -0.5, -0.64, 0.0, -0.5, 0.5, -0.64, 0.75, -0.25]), GOLD, 0.8, true)
		"sugarloaf":
			_shape([-0.36, -0.28, -0.1, -1.08, 0.12, -1.12, 0.36, -0.28], Color("f3ead8"))
			_ellipse(_at(0, -0.3), s * 0.46, s * 0.08, Color("e4dccb"))
		"crown":
			_shape([-0.45, -0.3, -0.45, -0.85, -0.22, -0.6, 0.0, -0.95, 0.22, -0.6, 0.45, -0.85, 0.45, -0.3], GOLD)
			_dot(_at(0, -0.55), s * 0.08, Color("e0503c"))
			_dot(_at(-0.27, -0.45), s * 0.05, Color("3f7ad8"))
			_dot(_at(0.27, -0.45), s * 0.05, Color("4fa860"))
		"tiara":
			_shape([-0.32, -0.34, -0.2, -0.5, -0.1, -0.42, 0.0, -0.62, 0.1, -0.42, 0.2, -0.5, 0.32, -0.34], GOLD)
			_dot(_at(0, -0.46), s * 0.06, b)
		"beret":
			_ellipse(_at(0.08, -0.42), s * 0.54, s * 0.18, a.darkened(0.3), -0.12)
			_dot(_at(0.1, -0.6), s * 0.05, a.darkened(0.3))
		"flatcap":
			var dome := PackedVector2Array()
			for k in 11:
				var t := PI + k * PI / 10.0
				dome.append(_at(0, -0.22) + Vector2(cos(t) * s * 0.44, sin(t) * s * 0.4))
			_poly(dome, b)
			_shape([0.2, -0.26, 0.74, -0.22, 0.72, -0.15, 0.2, -0.18], b.darkened(0.25))
		"feather":
			_shape([0.12, -0.55, -0.1, -0.9, -0.45, -1.0, -0.28, -0.8, -0.04, -0.6], b)
			_line(_at(0.1, -0.56), _at(-0.4, -0.97), b.darkened(0.3), 0.6)
			_ellipse(_at(0, -0.36), s * 0.72, s * 0.12, a.darkened(0.35))
			_ellipse(_at(0, -0.48), s * 0.36, s * 0.18, a.darkened(0.35))
			_line(_at(-0.34, -0.42), _at(0.34, -0.42), b, maxf(1.0, s * 0.06))
		"laurel":
			for i in 9:
				var t := PI + 0.25 + i * (PI - 0.5) / 8.0
				var at := h + Vector2(cos(t), sin(t)) * s * 0.44
				_ellipse(at, s * 0.12, s * 0.06, Color("6cc46a") if a != GOLD else GOLD, t + PI / 2.0)
		"turban":
			_ellipse(_at(0, -0.46), s * 0.5, s * 0.28, a)
			canvas.draw_arc(_at(0, -0.3), s * 0.42, PI + 0.4, TAU - 0.4, 10, b, 1.0, true)
			canvas.draw_arc(_at(0, -0.4), s * 0.42, PI + 0.5, TAU - 0.5, 10, b, 1.0, true)
			_dot(_at(0, -0.5), s * 0.08, GOLD)
			_line(_at(0, -0.56), _at(0.12, -0.92), Color.WHITE, maxf(1.0, s * 0.05))
		"hood":
			canvas.draw_arc(h, s * 0.48, PI + 0.2, TAU - 0.2, 14, a.darkened(0.55), 1.0, true)
		"flowers":
			var petals := [Color("f08ab8"), Color.WHITE, Color("f0d860")]
			for i in 7:
				var t := PI + 0.3 + i * (PI - 0.6) / 6.0
				var at := h + Vector2(cos(t), sin(t)) * s * 0.44
				_dot(at, s * 0.11, petals[i % 3])
				_dot(at, s * 0.04, GOLD.darkened(0.2))
		"tophat":
			_shape([-0.3, -1.0, 0.3, -1.0, 0.3, -0.36, -0.3, -0.36], a.darkened(0.6))
			_shape([-0.52, -0.42, 0.52, -0.42, 0.52, -0.32, -0.52, -0.32], a.darkened(0.6))
			_shape([-0.3, -0.54, 0.3, -0.54, 0.3, -0.44, -0.3, -0.44], b)
		"chef":
			_shape([-0.36, -0.52, 0.36, -0.52, 0.36, -0.32, -0.36, -0.32], Color("f6f2ea"))
			for x in [-0.24, 0.0, 0.24]:
				_dot(_at(x, -0.64 - (0.08 if x == 0.0 else 0.0)), s * 0.2, Color("f6f2ea"))
			_line(_at(-0.36, -0.52), _at(0.36, -0.52), Color("c8c0b0"), 0.6)
		"helmet":
			_shape([-0.05, -0.68, 0.1, -1.0, 0.45, -0.95, 0.15, -0.66], b)
			var dome := PackedVector2Array()
			for k in 11:
				var t := PI + k * PI / 10.0
				dome.append(_at(0, -0.18) + Vector2(cos(t) * s * 0.48, sin(t) * s * 0.52))
			_poly(dome, Color("a8b0bc"))
			_line(_at(-0.48, -0.2), _at(0.48, -0.2), Color("6a7480"), 1.0)
			_line(_at(0, -0.2), _at(0, 0.05), Color("6a7480"), 1.0)
		"skullcap":
			var cap := PackedVector2Array()
			for k in 11:
				var t := PI + k * PI / 10.0
				cap.append(_at(0, -0.12) + Vector2(cos(t) * s * 0.43, sin(t) * s * 0.34))
			_poly(cap, Color("1a141f") if a == JesterDesigns.COLOURS["white"] or a == JesterDesigns.COLOURS["black"] else a.darkened(0.3))
		"nightcap":
			_shape([-0.42, -0.25, -0.1, -0.75, 0.35, -0.82, 0.78, -0.48, 0.42, -0.25], a)
			_shape([-0.46, -0.32, 0.46, -0.32, 0.46, -0.22, -0.46, -0.22], Color("f3ead8"))
			_dot(_at(0.78, -0.48), s * 0.1, Color("f3ead8"))
		"bonnet":
			var bonnet := PackedVector2Array()
			for k in 13:
				var t := PI - 0.15 + k * (PI + 0.3) / 12.0
				bonnet.append(_at(0, -0.1) + Vector2(cos(t), sin(t)) * s * 0.52)
			_poly(bonnet, Color("f6f2ea"))
			for k in 7:
				var t := PI + k * PI / 6.0
				_dot(_at(0, -0.1) + Vector2(cos(t), sin(t)) * s * 0.52, s * 0.06, Color("e4dccb"))
			_dot(_at(0.5, 0.0), s * 0.08, b)
		"doge":
			_shape([-0.4, -0.28, -0.32, -0.8, -0.05, -0.98, 0.25, -0.9, 0.4, -0.28], GOLD)
			_shape([-0.42, -0.38, 0.42, -0.38, 0.42, -0.26, -0.42, -0.26], GOLD.darkened(0.3))
			_dot(_at(-0.05, -0.62), s * 0.06, Color("e0503c"))
		"wig":
			for x in [-0.3, -0.1, 0.1, 0.3]:
				_dot(_at(x, -0.38), s * 0.15, Color("eeeef6"))
			_dot(_at(0.5, 0.36), s * 0.07, b)
		"hair":
			var dome := PackedVector2Array()
			for k in 11:
				var t := PI + k * PI / 10.0
				dome.append(_at(0, -0.1) + Vector2(cos(t) * s * 0.45, sin(t) * s * 0.36))
			_poly(dome, hair)
		"longhair":
			var fringe := PackedVector2Array()
			for k in 11:
				var t := PI + k * PI / 10.0
				fringe.append(_at(0, -0.12) + Vector2(cos(t) * s * 0.46, sin(t) * s * 0.34))
			_poly(fringe, b.darkened(0.2))
		"bald":
			_dot(_at(-0.16, -0.28), s * 0.06, Color(1, 1, 1, 0.35))


## A fool's cap with two, three or four points and a bell on each.
func _cap(points: int) -> void:
	var tips: Array[Vector2] = []
	match points:
		2:
			tips = [_at(-0.92, -0.6), _at(0.92, -0.6)]
		3:
			tips = [_at(-0.92, -0.6), _at(0.0, -0.98), _at(0.92, -0.6)]
		_:
			tips = [_at(-0.95, -0.45), _at(-0.4, -0.95), _at(0.4, -0.95), _at(0.95, -0.45)]
	var left := _at(-0.46, -0.26)
	var right := _at(0.46, -0.26)
	for i in tips.size():
		var from := left.lerp(right, float(i) / tips.size())
		var to := left.lerp(right, float(i + 1) / tips.size())
		_poly(PackedVector2Array([from, tips[i], to, (from + to) / 2.0 + Vector2(0, s * 0.06)]), a if i % 2 == 0 else b)
	_poly(PackedVector2Array([left + Vector2(-s * 0.04, -s * 0.06), right + Vector2(s * 0.04, -s * 0.06), right + Vector2(s * 0.04, s * 0.06), left + Vector2(-s * 0.04, s * 0.06)]), b.darkened(0.25))
	for tip in tips:
		_dot(tip, s * 0.12, GOLD.darkened(0.2))
		_dot(tip + Vector2(-s * 0.03, -s * 0.03), s * 0.05, GOLD.lightened(0.35))


# --- the prop in hand ---

func _prop(kind: String) -> void:
	var r := _at(0.72, 0.85)
	var l := _at(-0.72, 0.85)
	match kind:
		"balls":
			var colours := [Color("e0503c"), Color("3f7ad8"), GOLD]
			for i in 3:
				var at := _at(0.55 + 0.22 * i, -0.15 - 0.35 * sin(i * 1.3))
				_dot(at, s * 0.12, colours[i])
				_dot(at + Vector2(-s * 0.04, -s * 0.04), s * 0.04, Color(1, 1, 1, 0.6))
		"marotte":
			var top := _at(0.78, -0.3)
			_line(_at(0.66, bottom), top, Color("8a5a2c"), maxf(1.0, s * 0.07))
			_dot(top, s * 0.15, SKINS[0])
			_poly(PackedVector2Array([top + Vector2(-s * 0.18, -s * 0.05), top + Vector2(-s * 0.3, -s * 0.35), top + Vector2(0, -s * 0.12), top + Vector2(s * 0.3, -s * 0.35), top + Vector2(s * 0.18, -s * 0.05)]), b)
			_dot(top + Vector2(-s * 0.3, -s * 0.35), s * 0.06, GOLD)
			_dot(top + Vector2(s * 0.3, -s * 0.35), s * 0.06, GOLD)
		"lute":
			_line(r, r + Vector2(s * 0.5, -s * 0.75), Color("5a3a1c"), maxf(1.0, s * 0.08))
			_ellipse(r, s * 0.24, s * 0.3, Color("c08040"), 0.3)
			_dot(r, s * 0.07, Color("4a2a10"))
		"cards":
			for i in 3:
				var angle := -0.5 + i * 0.4
				var card := PackedVector2Array()
				for corner in [Vector2(-0.12, -0.42), Vector2(0.12, -0.42), Vector2(0.12, 0), Vector2(-0.12, 0)]:
					card.append(l + (corner * s).rotated(angle))
				_poly(card, Color("f4ead6"))
				canvas.draw_polyline(card + PackedVector2Array([card[0]]), Color("3a2e2a"), 0.5, true)
				_dot(l + (Vector2(0, -0.28) * s).rotated(angle), s * 0.05, Color("c8323c") if i % 2 == 0 else INK)
		"slapstick":
			for side in [-1.0, 1.0]:
				_poly(PackedVector2Array([r + Vector2((-0.05 + side * 0.03) * s, 0), r + Vector2((0.05 + side * 0.03) * s, 0), r + Vector2((0.25 + side * 0.1) * s, -s * 0.85), r + Vector2((0.15 + side * 0.1) * s, -s * 0.85)]), Color("d8b070") if side < 0 else Color("b08848"))
		"coins":
			for i in 4:
				_ellipse(r + Vector2(0, -i * s * 0.09), s * 0.22, s * 0.08, GOLD.darkened(0.1 * (i % 2)))
			_dot(r + Vector2(s * 0.05, -s * 0.5), s * 0.16, GOLD)
			_ring(r + Vector2(s * 0.05, -s * 0.5), s * 0.11, GOLD.darkened(0.3), 0.7)
		"bag":
			_dot(r, s * 0.26, Color("b08850"))
			_shape([0.6, 0.5, 0.84, 0.5, 0.78, 0.62, 0.66, 0.62], Color("8a6a3a"))
			_dot(r + Vector2(0, s * 0.04), s * 0.08, GOLD)
		"dice":
			for i in 2:
				var c := r + Vector2(i * s * 0.3 - s * 0.15, -i * s * 0.2)
				_poly(PackedVector2Array([c + Vector2(-0.13, -0.13) * s, c + Vector2(0.13, -0.13) * s, c + Vector2(0.13, 0.13) * s, c + Vector2(-0.13, 0.13) * s]), Color.WHITE)
				_dot(c, s * 0.035, INK)
				_dot(c + Vector2(-0.07, -0.07) * s, s * 0.03, INK)
				_dot(c + Vector2(0.07, 0.07) * s, s * 0.03, INK)
		"sword":
			_line(r, r + Vector2(s * 0.3, -s * 1.2), Color("d8e0e8"), maxf(1.2, s * 0.09))
			_line(r + Vector2(-s * 0.15, -s * 0.05), r + Vector2(s * 0.17, s * 0.05), GOLD, maxf(1.0, s * 0.07))
			_dot(r + Vector2(-s * 0.03, s * 0.1), s * 0.06, GOLD)
		"book":
			_poly(PackedVector2Array([l + Vector2(-0.25, -0.3) * s, l + Vector2(0.25, -0.35) * s, l + Vector2(0.28, 0.1) * s, l + Vector2(-0.22, 0.15) * s]), Color("7a2a2a"))
			_line(l + Vector2(-0.2, 0.1) * s, l + Vector2(0.24, 0.05) * s, Color("f3ead8"), 1.0)
			_dot(l + Vector2(0.02, -0.1) * s, s * 0.05, GOLD)
		"quill":
			_shape([0.62, 0.9, 0.7, 0.4, 0.95, -0.1, 0.85, 0.45], Color("f6f2ea"))
			_line(r + Vector2(-s * 0.1, s * 0.05), r + Vector2(s * 0.22, -s * 0.9), Color("b0a090"), 0.6)
		"goblet":
			_shape([0.52, 0.35, 0.92, 0.35, 0.82, 0.6, 0.62, 0.6], GOLD)
			_ellipse(_at(0.72, 0.36), s * 0.2, s * 0.05, Color("8a1a2a"))
			_line(_at(0.72, 0.6), _at(0.72, 0.85), GOLD, maxf(1.0, s * 0.06))
			_ellipse(_at(0.72, 0.86), s * 0.13, s * 0.04, GOLD.darkened(0.2))
		"mirror":
			_line(r, r + Vector2(0, -s * 0.3), Color("8a5a2c"), maxf(1.0, s * 0.07))
			_ellipse(r + Vector2(0, -s * 0.55), s * 0.22, s * 0.28, GOLD)
			_ellipse(r + Vector2(0, -s * 0.55), s * 0.16, s * 0.22, Color("bfe4f4"))
			_line(r + Vector2(-s * 0.08, -s * 0.66), r + Vector2(s * 0.02, -s * 0.76), Color.WHITE, 0.8)
		"rose":
			_line(r, r + Vector2(s * 0.1, -s * 0.6), Color("4fa860"), 1.0)
			_ellipse(r + Vector2(s * 0.08, -s * 0.3), s * 0.1, s * 0.05, Color("4fa860"), 0.6)
			_dot(r + Vector2(s * 0.1, -s * 0.68), s * 0.16, Color("c8323c"))
			canvas.draw_arc(r + Vector2(s * 0.1, -s * 0.68), s * 0.08, 0.0, 4.5, 8, Color("8a1a2a"), 0.7, true)
		"lantern":
			_dot(r + Vector2(0, -s * 0.3), s * 0.42, Color(1.0, 0.85, 0.4, 0.15))
			_poly(PackedVector2Array([r + Vector2(-0.15, -0.5) * s, r + Vector2(0.15, -0.5) * s, r + Vector2(0.18, -0.1) * s, r + Vector2(-0.18, -0.1) * s]), Color("f8d870"))
			_line(r + Vector2(-0.18, -0.5) * s, r + Vector2(0.18, -0.5) * s, Color("5a4a3a"), 1.0)
			_line(r + Vector2(-0.2, -0.1) * s, r + Vector2(0.2, -0.1) * s, Color("5a4a3a"), 1.0)
			canvas.draw_arc(r + Vector2(0, -s * 0.5), s * 0.12, PI, TAU, 8, Color("5a4a3a"), 0.8, true)
		"maskstick":
			_line(r + Vector2(0, s * 0.1), r + Vector2(s * 0.1, -s * 0.5), Color("8a5a2c"), maxf(1.0, s * 0.06))
			var m := r + Vector2(s * 0.12, -s * 0.6)
			_poly(PackedVector2Array([m + Vector2(-0.3, -0.06) * s, m + Vector2(0, -0.12) * s, m + Vector2(0.3, -0.06) * s, m + Vector2(0.2, 0.1) * s, m + Vector2(0, 0.04) * s, m + Vector2(-0.2, 0.1) * s]), b)
			_dot(m + Vector2(-0.12, -0.02) * s, s * 0.04, INK)
			_dot(m + Vector2(0.12, -0.02) * s, s * 0.04, INK)
		"bell":
			_shape([0.6, 0.55, 0.65, 0.2, 0.79, 0.2, 0.84, 0.55], GOLD)
			_ellipse(_at(0.72, 0.56), s * 0.15, s * 0.05, GOLD.darkened(0.2))
			_dot(_at(0.72, 0.64), s * 0.05, GOLD.darkened(0.4))
			_line(_at(0.72, 0.2), _at(0.72, 0.08), Color("8a5a2c"), maxf(1.0, s * 0.06))
		"hourglass":
			_shape([0.55, 0.2, 0.89, 0.2, 0.72, 0.52], Color("f0d8a0"))
			_shape([0.72, 0.52, 0.89, 0.84, 0.55, 0.84], Color("f0d8a0"))
			_line(_at(0.52, 0.2), _at(0.92, 0.2), Color("8a5a2c"), 1.2)
			_line(_at(0.52, 0.84), _at(0.92, 0.84), Color("8a5a2c"), 1.2)
		"scroll":
			_poly(PackedVector2Array([r + Vector2(-0.22, -0.4) * s, r + Vector2(0.2, -0.4) * s, r + Vector2(0.2, 0.15) * s, r + Vector2(-0.22, 0.15) * s]), Color("f3ead8"))
			_ellipse(r + Vector2(-0.01, -0.42) * s, s * 0.26, s * 0.06, Color("d8c8a0"))
			_ellipse(r + Vector2(-0.01, 0.16) * s, s * 0.26, s * 0.06, Color("d8c8a0"))
			for i in 3:
				_line(r + Vector2(-0.14, -0.25 + i * 0.12) * s, r + Vector2(0.12, -0.25 + i * 0.12) * s, Color("b0a080"), 0.6)
		"star":
			_dot(_at(0.72, -0.3), s * 0.32, Color(1.0, 0.9, 0.5, 0.18))
			_star(_at(0.72, -0.3), s * 0.25, GOLD)
			_line(r, _at(0.72, -0.1), Color("8a5a2c"), maxf(1.0, s * 0.05))
		"heart":
			CardView.draw_suit(canvas, r + Vector2(0, -s * 0.25), s * 0.24, PlayingCard.Suit.HEARTS, Color("e0503c"))
		"key":
			_ring(r + Vector2(0, -s * 0.5), s * 0.12, GOLD, maxf(1.0, s * 0.06))
			_line(r + Vector2(0, -s * 0.38), r + Vector2(0, s * 0.12), GOLD, maxf(1.0, s * 0.06))
			_line(r + Vector2(0, s * 0.05), r + Vector2(s * 0.12, s * 0.05), GOLD, maxf(1.0, s * 0.05))
			_line(r + Vector2(0, -s * 0.05), r + Vector2(s * 0.1, -s * 0.05), GOLD, maxf(1.0, s * 0.05))
		"fan":
			var fan := PackedVector2Array([l])
			for k in 9:
				var t := PI + 0.4 + k * (PI - 0.8) / 8.0
				fan.append(l + Vector2(cos(t), sin(t)) * s * 0.45)
			_poly(fan, b)
			for k in 5:
				var t := PI + 0.4 + k * (PI - 0.8) / 4.0
				_line(l, l + Vector2(cos(t), sin(t)) * s * 0.45, b.darkened(0.3), 0.6)
		"bottle":
			_poly(PackedVector2Array([r + Vector2(-0.14, -0.2) * s, r + Vector2(-0.06, -0.38) * s, r + Vector2(-0.06, -0.55) * s, r + Vector2(0.06, -0.55) * s, r + Vector2(0.06, -0.38) * s, r + Vector2(0.14, -0.2) * s, r + Vector2(0.14, 0.15) * s, r + Vector2(-0.14, 0.15) * s]), Color("4a9a7a"))
			_poly(PackedVector2Array([r + Vector2(-0.1, -0.08) * s, r + Vector2(0.1, -0.08) * s, r + Vector2(0.1, 0.05) * s, r + Vector2(-0.1, 0.05) * s]), Color("f3ead8"))
			_dot(r + Vector2(0, -0.58) * s, s * 0.05, Color("a87040"))
		"bread":
			_ellipse(r + Vector2(0, -s * 0.1), s * 0.3, s * 0.15, Color("d8a050"), -0.3)
			for i in 3:
				_line(r + Vector2(-0.12 + i * 0.1, -0.2 + i * 0.04) * s, r + Vector2(-0.06 + i * 0.1, -0.08 + i * 0.04) * s, Color("a87030"), 0.7)
		"drum":
			_poly(PackedVector2Array([r + Vector2(-0.26, -0.2) * s, r + Vector2(0.26, -0.2) * s, r + Vector2(0.26, 0.15) * s, r + Vector2(-0.26, 0.15) * s]), Color("c8323c"))
			_ellipse(r + Vector2(0, -0.2) * s, s * 0.26, s * 0.08, Color("f3ead8"))
			canvas.draw_polyline(PackedVector2Array([r + Vector2(-0.26, -0.1) * s, r + Vector2(-0.13, 0.08) * s, r + Vector2(0, -0.1) * s, r + Vector2(0.13, 0.08) * s, r + Vector2(0.26, -0.1) * s]), GOLD, 0.7, true)
			_line(r + Vector2(-0.1, -0.3) * s, r + Vector2(-0.35, -0.65) * s, Color("8a5a2c"), 1.0)
		"trumpet":
			_line(_at(0.1, 0.25), _at(0.8, 0.0), GOLD, maxf(1.0, s * 0.08))
			_shape([0.75, 0.02, 1.0, -0.18, 1.02, 0.22], GOLD)
		"torch":
			_line(r + Vector2(0, s * 0.15), r + Vector2(s * 0.05, -s * 0.4), Color("8a5a2c"), maxf(1.0, s * 0.09))
			_dot(r + Vector2(s * 0.05, -s * 0.6), s * 0.38, Color(1.0, 0.6, 0.2, 0.18))
			_poly(PackedVector2Array([r + Vector2(-0.12, -0.42) * s, r + Vector2(0.0, -0.95) * s, r + Vector2(0.08, -0.65) * s, r + Vector2(0.2, -0.85) * s, r + Vector2(0.2, -0.42) * s]), Color("f08a3c"))
			_poly(PackedVector2Array([r + Vector2(-0.04, -0.44) * s, r + Vector2(0.04, -0.75) * s, r + Vector2(0.12, -0.44) * s]), Color("f8d870"))
		"flag":
			_line(r + Vector2(0, s * 0.15), r + Vector2(0, -s * 1.1), Color("8a5a2c"), maxf(1.0, s * 0.06))
			_poly(PackedVector2Array([r + Vector2(0, -1.1) * s, r + Vector2(0.5, -1.0) * s, r + Vector2(0.45, -0.75) * s, r + Vector2(0, -0.7) * s]), b)
			_poly(PackedVector2Array([r + Vector2(0, -0.95) * s, r + Vector2(0.48, -0.9) * s, r + Vector2(0.47, -0.82) * s, r + Vector2(0, -0.85) * s]), a)
		"broom":
			_line(r + Vector2(-s * 0.2, -s * 0.9), r + Vector2(s * 0.05, s * 0.05), Color("8a5a2c"), maxf(1.0, s * 0.06))
			_poly(PackedVector2Array([r + Vector2(-0.05, 0.0) * s, r + Vector2(0.12, 0.0) * s, r + Vector2(0.3, 0.3) * s, r + Vector2(-0.12, 0.3) * s]), Color("d8b070"))
		"scissors":
			_line(r + Vector2(-0.1, 0.1) * s, r + Vector2(0.2, -0.5) * s, Color("c8d0d8"), maxf(1.0, s * 0.06))
			_line(r + Vector2(0.1, 0.1) * s, r + Vector2(-0.12, -0.5) * s, Color("c8d0d8"), maxf(1.0, s * 0.06))
			_ring(r + Vector2(-0.12, 0.18) * s, s * 0.08, Color("e0503c"), 1.0)
			_ring(r + Vector2(0.12, 0.18) * s, s * 0.08, Color("e0503c"), 1.0)
		"hammer":
			_line(r + Vector2(0, s * 0.15), r + Vector2(s * 0.1, -s * 0.55), Color("8a5a2c"), maxf(1.0, s * 0.07))
			_poly(PackedVector2Array([r + Vector2(-0.12, -0.7) * s, r + Vector2(0.32, -0.64) * s, r + Vector2(0.3, -0.5) * s, r + Vector2(-0.14, -0.56) * s]), Color("8a8a98"))
		"brush":
			_ellipse(l + Vector2(0, -s * 0.05), s * 0.3, s * 0.2, Color("d8b880"), 0.2)
			for i in 3:
				_dot(l + Vector2(-0.15 + i * 0.12, -0.1) * s, s * 0.05, [Color("e0503c"), Color("3f7ad8"), Color("f0d860")][i])
			_line(r + Vector2(0, s * 0.1), r + Vector2(s * 0.15, -s * 0.6), Color("8a5a2c"), maxf(1.0, s * 0.05))
			_dot(r + Vector2(s * 0.16, -s * 0.64), s * 0.06, b)
		"telescope":
			_poly(PackedVector2Array([r + Vector2(-0.3, 0.1) * s, r + Vector2(0.4, -0.6) * s, r + Vector2(0.5, -0.5) * s, r + Vector2(-0.2, 0.2) * s]), Color("c89a4a"))
			_ring(r + Vector2(0.45, -0.55) * s, s * 0.08, GOLD.darkened(0.3), 1.0)
		"crystal":
			_dot(r + Vector2(0, -s * 0.3), s * 0.42, Color(0.7, 0.5, 1.0, 0.15))
			_dot(r + Vector2(0, -s * 0.3), s * 0.25, Color("b090e0"))
			_dot(r + Vector2(-s * 0.08, -s * 0.38), s * 0.07, Color(1, 1, 1, 0.7))
			_shape([0.56, 0.95, 0.88, 0.95, 0.8, 0.8, 0.64, 0.8], GOLD.darkened(0.2))
		"letter":
			var env := PackedVector2Array([r + Vector2(-0.28, -0.3) * s, r + Vector2(0.28, -0.3) * s, r + Vector2(0.28, 0.08) * s, r + Vector2(-0.28, 0.08) * s])
			_poly(env, Color("f6f2ea"))
			canvas.draw_polyline(PackedVector2Array([env[0], r + Vector2(0, -0.08) * s, env[1]]), Color("b0a080"), 0.7, true)
			_dot(r + Vector2(0, -0.08) * s, s * 0.06, Color("c8323c"))
		"fish":
			_ellipse(r + Vector2(0, -s * 0.15), s * 0.3, s * 0.12, Color("7aa0c0"), -0.2)
			_poly(PackedVector2Array([r + Vector2(0.24, -0.22) * s, r + Vector2(0.45, -0.38) * s, r + Vector2(0.45, -0.05) * s]), Color("7aa0c0"))
			_dot(r + Vector2(-0.17, -0.12) * s, s * 0.035, INK)
		"pan":
			_line(r + Vector2(0.15, 0.0), r + Vector2(s * 0.55, s * 0.2), Color("3a3040"), maxf(1.0, s * 0.08))
			_ellipse(r + Vector2(-s * 0.05, -s * 0.05), s * 0.3, s * 0.12, Color("3a3040"))
			for i in 4:
				canvas.draw_arc(r + Vector2((-0.18 + i * 0.1) * s, -s * 0.1), s * 0.06, PI, TAU, 6, Color("f0d860"), 1.0, true)
		"shovel":
			_line(r + Vector2(0, -s * 0.8), r + Vector2(0, s * 0.0), Color("8a5a2c"), maxf(1.0, s * 0.06))
			CardView.draw_suit(canvas, r + Vector2(0, s * 0.12), s * 0.2, PlayingCard.Suit.SPADES, Color("8a8a98"))
		"gem":
			_dot(r + Vector2(0, -s * 0.2), s * 0.36, Color(b, 0.15))
			_poly(PackedVector2Array([r + Vector2(-0.22, -0.3) * s, r + Vector2(-0.1, -0.42) * s, r + Vector2(0.1, -0.42) * s, r + Vector2(0.22, -0.3) * s, r + Vector2(0, 0.0) * s]), b.lightened(0.2))
			_line(r + Vector2(-0.22, -0.3) * s, r + Vector2(0.22, -0.3) * s, b.darkened(0.3), 0.6)
			_dot(r + Vector2(-0.06, -0.34) * s, s * 0.04, Color.WHITE)
		"clock":
			_dot(r + Vector2(0, -s * 0.2), s * 0.28, GOLD)
			_dot(r + Vector2(0, -s * 0.2), s * 0.22, Color("f6f2ea"))
			_line(r + Vector2(0, -s * 0.2), r + Vector2(0, -s * 0.36), INK, 0.8)
			_line(r + Vector2(0, -s * 0.2), r + Vector2(s * 0.12, -s * 0.16), INK, 0.8)
		"candle":
			_dot(r + Vector2(0, -s * 0.55), s * 0.3, Color(1.0, 0.85, 0.4, 0.18))
			_poly(PackedVector2Array([r + Vector2(-0.08, -0.4) * s, r + Vector2(0.08, -0.4) * s, r + Vector2(0.08, 0.1) * s, r + Vector2(-0.08, 0.1) * s]), Color("f6f2ea"))
			_shape([0.68, 0.45, 0.72, 0.2, 0.76, 0.45], Color("f8b040"))
		"puppet":
			_line(r + Vector2(-0.25, -0.9) * s, r + Vector2(0.25, -0.9) * s, Color("8a5a2c"), maxf(1.0, s * 0.06))
			for x in [-0.2, 0.0, 0.2]:
				_line(r + Vector2(x, -0.9) * s, r + Vector2(x * 0.5, -0.35) * s, Color(1, 1, 1, 0.6), 0.5)
			_dot(r + Vector2(0, -0.38) * s, s * 0.1, SKINS[0])
			_poly(PackedVector2Array([r + Vector2(-0.12, -0.28) * s, r + Vector2(0.12, -0.28) * s, r + Vector2(0.15, 0.05) * s, r + Vector2(-0.15, 0.05) * s]), b)
		"ticket":
			_poly(PackedVector2Array([r + Vector2(-0.3, -0.35) * s, r + Vector2(0.3, -0.35) * s, r + Vector2(0.3, -0.05) * s, r + Vector2(-0.3, -0.05) * s]), Color("f0d880"))
			for i in 4:
				_dot(r + Vector2(0.1, -0.32 + i * 0.08) * s, s * 0.02, Color("8a6a2a"))
			_line(r + Vector2(-0.22, -0.2) * s, r + Vector2(0.02, -0.2) * s, Color("c8323c"), 0.8)
		"flowers":
			_poly(PackedVector2Array([r + Vector2(-0.2, -0.25) * s, r + Vector2(0.2, -0.25) * s, r + Vector2(0, 0.15) * s]), Color("f3ead8"))
			var colours := [Color("e0503c"), Color("f08ab8"), Color("f0d860"), Color("8a4ad0")]
			for i in 4:
				_dot(r + Vector2(-0.18 + i * 0.12, -0.38 - (i % 2) * 0.1) * s, s * 0.1, colours[i])
		"wheel":
			_ring(r + Vector2(0, -s * 0.2), s * 0.3, Color("8a5a2c"), maxf(1.0, s * 0.07))
			for k in 4:
				var t := k * PI / 4.0
				_line(r + Vector2(0, -s * 0.2) + Vector2(cos(t), sin(t)) * s * 0.3, r + Vector2(0, -s * 0.2) - Vector2(cos(t), sin(t)) * s * 0.3, Color("8a5a2c"), 0.8)
		"horn":
			_poly(PackedVector2Array([r + Vector2(-0.1, 0.1) * s, r + Vector2(0.06, 0.1) * s, r + Vector2(0.15, -0.2) * s, r + Vector2(0.1, -0.5) * s, r + Vector2(0.0, -0.2) * s]), Color("d8303a"))
			_ellipse(r + Vector2(-0.02, 0.12) * s, s * 0.09, s * 0.04, GOLD)
		"bird":
			_ellipse(r + Vector2(0, -s * 0.3), s * 0.16, s * 0.24, Color("4fa860"))
			_dot(r + Vector2(0, -s * 0.55), s * 0.12, Color("e0503c"))
			_shape([0.8, 0.26, 0.94, 0.31, 0.8, 0.36], Color("f0b84a"))
			_dot(r + Vector2(s * 0.03, -s * 0.57), s * 0.025, INK)
		"masks":
			_ellipse(r + Vector2(-0.12, -0.35) * s, s * 0.17, s * 0.2, GOLD)
			canvas.draw_arc(r + Vector2(-0.12, -0.32) * s, s * 0.08, 0.3, PI - 0.3, 6, INK, 0.8, true)
			_ellipse(r + Vector2(0.15, -0.15) * s, s * 0.17, s * 0.2, Color("c8d0d8"))
			canvas.draw_arc(r + Vector2(0.15, -0.05) * s, s * 0.08, PI + 0.3, TAU - 0.3, 6, INK, 0.8, true)
		"pole":
			_line(_at(-1.1, 0.75), _at(1.1, 0.75), Color("8a5a2c"), maxf(1.0, s * 0.06))
			_dot(_at(-1.1, 0.75), s * 0.07, GOLD)
			_dot(_at(1.1, 0.75), s * 0.07, GOLD)
		"pie":
			_ellipse(r + Vector2(0, -s * 0.05), s * 0.32, s * 0.12, Color("c89060"))
			_ellipse(r + Vector2(0, -s * 0.1), s * 0.26, s * 0.08, Color("f6f2ea"))
			_dot(r + Vector2(0, -s * 0.18), s * 0.06, Color("c8323c"))
		"ribbon":
			canvas.draw_polyline(PackedVector2Array([r + Vector2(0, 0.1) * s, r + Vector2(0.15, -0.2) * s, r + Vector2(-0.05, -0.45) * s, r + Vector2(0.2, -0.75) * s, r + Vector2(0.0, -1.0) * s]), b, maxf(1.0, s * 0.08), true)
		"bubbles":
			for i in 5:
				_ring(_at(0.55 + (i % 2) * 0.22, 0.4 - i * 0.25), s * (0.07 + (i % 3) * 0.03), Color("bfe4f4"), 0.7)
		"chest":
			_poly(PackedVector2Array([r + Vector2(-0.3, -0.3) * s, r + Vector2(0.3, -0.3) * s, r + Vector2(0.3, 0.1) * s, r + Vector2(-0.3, 0.1) * s]), Color("8a5a2c"))
			_line(r + Vector2(-0.3, -0.15) * s, r + Vector2(0.3, -0.15) * s, GOLD, 0.9)
			_dot(r + Vector2(0, -0.1) * s, s * 0.05, GOLD)
		"chisel":
			_line(r + Vector2(0, s * 0.15), r + Vector2(s * 0.15, -s * 0.3), Color("8a5a2c"), maxf(1.0, s * 0.08))
			_line(r + Vector2(s * 0.15, -s * 0.3), r + Vector2(s * 0.25, -s * 0.6), Color("c8d0d8"), maxf(1.0, s * 0.06))
		"wand":
			_line(r + Vector2(0, s * 0.1), r + Vector2(s * 0.25, -s * 0.6), Color("1a141f"), maxf(1.0, s * 0.06))
			_line(r + Vector2(s * 0.2, -s * 0.48), r + Vector2(s * 0.25, -s * 0.6), Color.WHITE, maxf(1.0, s * 0.06))
			_star(r + Vector2(s * 0.32, -s * 0.78), s * 0.1, GOLD)
			_star(r + Vector2(s * 0.08, -s * 0.85), s * 0.06, GOLD)
		"question":
			canvas.draw_string(UiTheme.font, r + Vector2(-s * 0.2, -s * 0.1), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(maxf(8.0, s * 0.9)), GOLD)


# --- the effect badge ---

## A small disc in the picture's top-left corner: what kind of thing this Jester does.
func _badge(effect: String) -> void:
	var at := w.position + Vector2(6.0, 6.0)
	var r := 4.6
	if effect == "pm":
		var left := PackedVector2Array([at])
		var right := PackedVector2Array([at])
		for k in 9:
			left.append(at + Vector2(cos(PI / 2.0 + k * PI / 8.0), sin(PI / 2.0 + k * PI / 8.0)) * r)
			right.append(at + Vector2(cos(-PI / 2.0 + k * PI / 8.0), sin(-PI / 2.0 + k * PI / 8.0)) * r)
		_poly(left, BADGES["p"])
		_poly(right, BADGES["m"])
	else:
		_dot(at, r, BADGES.get(effect, BADGES["r"]))
	canvas.draw_arc(at, r, 0.0, TAU, 16, Color(0, 0, 0, 0.5), 0.6, true)
	var mark := Color.WHITE
	match effect:
		"m", "p", "pm":
			_line(at + Vector2(-2.4, 0), at + Vector2(2.4, 0), mark, 1.1)
			_line(at + Vector2(0, -2.4), at + Vector2(0, 2.4), mark, 1.1)
		"x":
			_line(at + Vector2(-2, -2), at + Vector2(2, 2), mark, 1.1)
			_line(at + Vector2(-2, 2), at + Vector2(2, -2), mark, 1.1)
		"d":
			_ring(at, 2.6, GOLD.darkened(0.45), 0.8)
			_line(at + Vector2(0, -1.6), at + Vector2(0, 1.6), GOLD.darkened(0.45), 0.8)
		"r":
			_star(at, 2.8, mark)
		"c":
			canvas.draw_rect(Rect2(at + Vector2(-2.6, -2.6), Vector2(3.4, 3.4)), mark, false, 0.8)
			canvas.draw_rect(Rect2(at + Vector2(-0.8, -0.8), Vector2(3.4, 3.4)), mark, false, 0.8)
