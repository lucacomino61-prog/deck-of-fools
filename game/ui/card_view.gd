class_name CardView
extends Control
## A card, drawn in code at the screen's own resolution: a playing card (corner indices, pips,
## framed J/Q/K portraits, a gloss, enhancement, edition and seal marks) or a named card (a
## Jester with its own face and harlequin costume, or a Tarocchi, Sign, Omen, pack or Warrant
## picture) with its name on a ribbon and its rarity as gems. Every edge is antialiased.
## Cards cast a shadow, lift under the pointer and, given a sway index, rock gently in place.

signal tapped(view: CardView)

const RANKS := {11: "J", 12: "Q", 13: "K", 14: "A"}
const KIND_COLOURS := {
	"tarocchi": Color("6a3d9a"), "sign": Color("23407a"), "omen": Color("1f6e6a"),
	"pack": Color("7a4a25"), "warrant": Color("8a6a1a"), "show": Color("3d2756"),
}
## Frames by rarity: blue, green, red, gold.
const RARITY_COLOURS := [Color("3f74c4"), Color("2f9a5a"), Color("c43a4a"), Color("c8962a")]
## The deep backdrop behind each Jester's portrait, picked by its id.
const BACKDROPS := [Color("2a1240"), Color("0e2a44"), Color("3a0f1c"), Color("0f3a2e"), Color("3a2a0c"), Color("1c1c4a")]
const EDITION_COLOURS := {
	"ed_silvered": Color("cfd8e0"), "ed_opaline": Color("ff8fd0"),
	"ed_prismatic": Color("7fffd4"), "ed_shadow": Color("101010"),
}
const SEAL_COLOURS := {
	"seal_ducal": Color("f0b84a"), "seal_encore": Color("e0503c"),
	"seal_astral": Color("3f8ed8"), "seal_oracle": Color("9a5ad0"),
}
const INK := Color("2a2433")
const EDGE := Color("3a2e2a")
const PAPER_LINE := Color("c9b48c")
## Pip positions for 2–10, as (column, row) with columns 0..2 and rows 0..1 down the card.
const PIPS := {
	2: [[1, 0.0], [1, 1.0]],
	3: [[1, 0.0], [1, 0.5], [1, 1.0]],
	4: [[0, 0.0], [2, 0.0], [0, 1.0], [2, 1.0]],
	5: [[0, 0.0], [2, 0.0], [1, 0.5], [0, 1.0], [2, 1.0]],
	6: [[0, 0.0], [2, 0.0], [0, 0.5], [2, 0.5], [0, 1.0], [2, 1.0]],
	7: [[0, 0.0], [2, 0.0], [1, 0.25], [0, 0.5], [2, 0.5], [0, 1.0], [2, 1.0]],
	8: [[0, 0.0], [2, 0.0], [1, 0.25], [0, 0.5], [2, 0.5], [1, 0.75], [0, 1.0], [2, 1.0]],
	9: [[0, 0.0], [2, 0.0], [0, 0.33], [2, 0.33], [1, 0.5], [0, 0.67], [2, 0.67], [0, 1.0], [2, 1.0]],
	10: [[0, 0.0], [2, 0.0], [1, 0.17], [0, 0.33], [2, 0.33], [0, 0.67], [2, 0.67], [1, 0.83], [0, 1.0], [2, 1.0]],
}
## The Jesters' costumes, faces and backdrops are picked from these by each card's id.
const COSTUME_COLOURS := [
	Color("e0503c"), Color("3f8ed8"), Color("6cc46a"), Color("f0b84a"),
	Color("9a5ad0"), Color("2e9c8f"), Color("f3ead8"), Color("2a2433"),
]
const SKINS := [Color("f3ead8"), Color("f1c8a0"), Color("d9a27a"), Color("a86f4c"), Color("7a4e34")]
const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Legendary"]

## Held without moving: show the card big with its full text (also right-click).
signal long_pressed(view: CardView)
## Dragged sideways (when draggable): the screen moves it and reorders on release.
signal drag_moved(view: CardView, at: Vector2)
signal drag_ended(view: CardView, at: Vector2)
## Flicked up (+1) or down (-1) (when swipeable): play or discard the selected cards.
signal swiped(view: CardView, direction: int)

const HOLD_SECONDS := 0.42
const FOILS := {"ed_silvered": 1, "ed_opaline": 2, "ed_prismatic": 3, "ed_shadow": 4}

var kind := "card"
var card: PlayingCard
var def_id := ""
var edition := ""
var sticker := ""
var selected := false
var dimmed := false
var face_down := false
var price_text := ""
## Whatever the screen needs to know about this view when it's tapped.
var tag: Dictionary = {}
## Set to the card's place in its row to make it rock gently; -1 holds it still.
var sway := -1
var draggable := false
var swipeable := false
## True for the copy CardArt draws into a texture: it draws the face itself, nothing else.
var baking := false

var _face: TextureRect
var _overlay: Control
var _material: ShaderMaterial
var _tilt := Vector2.ZERO
var _hovered := false
var _gesture := ""
var _press_at := Vector2.ZERO
var _hold_id := 0


func _init(view_size := Vector2(52, 72)) -> void:
	custom_minimum_size = view_size
	size = view_size
	pivot_offset = view_size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_lift.bind(true))
	mouse_exited.connect(_lift.bind(false))


func _ready() -> void:
	if baking:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	_face = TextureRect.new()
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_SCALE
	_face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_face.size = size
	add_child(_face)
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.size = size
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	if Settings.quality > 0:
		_material = ShaderMaterial.new()
		_material.shader = preload("res://shaders/card.gdshader")
		_material.set_shader_parameter("card_size", size)
		_material.set_shader_parameter("foil", 0 if face_down else FOILS.get(edition, 0))
		_face.material = _material
	set_art(CardArt.request(self))
	set_process(_material != null or sway >= 0)


## The texture CardArt drew for this face.
func set_art(texture: Texture2D) -> void:
	if _face != null and texture != null:
		_face.texture = texture


## Everything that changes how the face looks; equal keys share one texture.
func art_key() -> String:
	var face := ""
	if face_down:
		face = "back%d" % Settings.card_back
	elif kind == "card":
		face = "card %d %d %s %s %s" % [card.rank, card.suit, card.enhancement, edition, card.seal]
	else:
		face = "%s %s %s %s" % [kind, def_id, edition, sticker]
	return "%s @%dx%d q%d" % [face, size.x, size.y, Settings.quality]


func baked_copy() -> CardView:
	var copy := CardView.new(size)
	copy.kind = kind
	copy.card = card
	copy.def_id = def_id
	copy.edition = edition
	copy.sticker = sticker
	copy.face_down = face_down
	copy.baking = true
	return copy


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	if Settings.reduce_motion:
		rotation = 0.0
		_tilt = Vector2.ZERO
	else:
		if sway >= 0 and _gesture != "drag":
			rotation = sin(t * 1.6 + sway * 0.9) * 0.025
		var target := Vector2.ZERO
		if _hovered or _gesture != "":
			target = ((get_local_mouse_position() / size) - Vector2(0.5, 0.5)) * 2.0
		elif sway >= 0:
			target = Vector2(sin(t * 1.1 + sway), cos(t * 0.8 + sway * 1.3)) * 0.18
		_tilt = _tilt.lerp(target.clamp(Vector2(-1, -1), Vector2(1, 1)), clampf(delta * 10.0, 0.0, 1.0))
	if _material != null:
		_material.set_shader_parameter("tilt", _tilt)


## Tap, hold, drag sideways, or flick up/down. A tap happens on release, so the other
## gestures can be told apart from it.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			long_pressed.emit(self)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_gesture = "press"
			_press_at = event.global_position
			_hold_id += 1
			var id := _hold_id
			get_tree().create_timer(HOLD_SECONDS).timeout.connect(func() -> void:
				if _gesture == "press" and _hold_id == id and is_inside_tree():
					_gesture = "held"
					long_pressed.emit(self))
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _gesture != "":
			var moved: Vector2 = event.global_position - _press_at
			match _gesture:
				"press":
					tapped.emit(self)
				"drag":
					drag_ended.emit(self, event.global_position)
				"swipe":
					if absf(moved.y) > 26.0:
						swiped.emit(self, 1 if moved.y < 0 else -1)
			_gesture = ""
			accept_event()
	elif event is InputEventMouseMotion and _gesture != "":
		var moved: Vector2 = event.global_position - _press_at
		if _gesture == "press" and moved.length() > 9.0:
			if swipeable and absf(moved.y) > absf(moved.x) * 1.2:
				_gesture = "swipe"
			elif draggable and absf(moved.x) >= absf(moved.y):
				_gesture = "drag"
				z_index = 2
			else:
				_gesture = "cancel"
		if _gesture == "drag":
			drag_moved.emit(self, event.global_position)
		accept_event()


func _lift(up: bool) -> void:
	_hovered = up
	if _gesture != "drag":
		z_index = 1 if up else 0
	if Settings.reduce_motion or baking:
		return
	var t := create_tween()
	t.tween_property(self, "scale", Vector2.ONE * (1.08 if up else 1.0), 0.08)


## The shadow; the face is the texture above it, and selection marks the overlay above that.
func _draw() -> void:
	if baking:
		_paint_face(Rect2(Vector2.ZERO, size))
		return
	draw_colored_polygon(_round_rect(Rect2(Vector2(1.5, 3.5), size), 5.0), Color(0, 0, 0, 0.38))


func _paint_face(r: Rect2) -> void:
	if face_down:
		_draw_back(r)
	elif kind == "card":
		_draw_playing(r)
	else:
		_draw_named(r)
	if edition != "" and EDITION_COLOURS.has(edition) and not face_down:
		_outline(_round_rect(r.grow(-1.0), 4.5), EDITION_COLOURS[edition], 1.6)


func _draw_overlay() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if selected:
		_overlay.draw_polyline(_closed(_round_rect(r.grow(2.0), 6.5)), UiTheme.GOLD, 1.8, true)
	if dimmed:
		_overlay.draw_colored_polygon(_round_rect(r, 5.0), Color(0, 0, 0, 0.55))
	if price_text != "":
		var badge := Rect2(Vector2(size.x - 22, -7), Vector2(26, 13))
		_overlay.draw_style_box(UiTheme.box(UiTheme.GOLD, UiTheme.OUTLINE, 3), badge)
		_overlay.draw_string(UiTheme.font, badge.position + Vector2(4, 10), price_text, HORIZONTAL_ALIGNMENT_LEFT, 22, 8, UiTheme.OUTLINE)


static func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	closed.append(points[0])
	return closed


# --- drawing helpers ---

## The outline of a rounded rectangle, clockwise from the top-right corner.
static func _round_rect(r: Rect2, radius: float) -> PackedVector2Array:
	# Under half the short side, or the arcs meet in repeated points and filling fails.
	radius = minf(radius, minf(r.size.x, r.size.y) / 2.0 - 0.05)
	var points := PackedVector2Array()
	var corners := [
		[Vector2(r.end.x - radius, r.position.y + radius), -PI / 2.0],
		[Vector2(r.end.x - radius, r.end.y - radius), 0.0],
		[Vector2(r.position.x + radius, r.end.y - radius), PI / 2.0],
		[Vector2(r.position.x + radius, r.position.y + radius), PI],
	]
	for corner in corners:
		for i in 5:
			var a: float = corner[1] + i * PI / 8.0
			points.append(corner[0] + Vector2(cos(a), sin(a)) * radius)
	return points


## A filled shape with a soft antialiased edge.
func _poly(points: PackedVector2Array, colour: Color) -> void:
	draw_colored_polygon(points, colour)
	_outline(points, colour, 0.7)


func _outline(points: PackedVector2Array, colour: Color, width: float) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, colour, width, true)


## A shape shaded from one colour at its top to another at its bottom.
func _gradient(points: PackedVector2Array, top: Color, bottom: Color) -> void:
	var y0 := INF
	var y1 := -INF
	for p in points:
		y0 = minf(y0, p.y)
		y1 = maxf(y1, p.y)
	var colours := PackedColorArray()
	for p in points:
		colours.append(top.lerp(bottom, (p.y - y0) / maxf(1.0, y1 - y0)))
	draw_polygon(points, colours)


func _dot(at: Vector2, radius: float, colour: Color) -> void:
	draw_circle(at, radius, colour, true, -1.0, true)


## A light streak across the top-left corner, as on a glossy card.
func _gloss(r: Rect2) -> void:
	var w := r.size.x
	draw_colored_polygon(PackedVector2Array([Vector2(3, 3), Vector2(w * 0.55, 3), Vector2(3, r.size.y * 0.4)]), Color(1, 1, 1, 0.1))


# --- backs and playing cards ---

## The back the player picked in Settings (Settings.CARD_BACKS names them).
func _draw_back(r: Rect2) -> void:
	var body := _round_rect(r, 5.0)
	var inner := r.grow(-maxf(3.0, r.size.x * 0.08))
	match Settings.card_back:
		1:
			_back_sun_and_moon(r, body, inner)
		2:
			_back_mask(r, body, inner)
		3:
			_back_curtain(r, body, inner)
		4:
			_back_night(r, body, inner)
		5:
			_back_filigree(r, body, inner)
		_:
			_back_harlequin(r, body, inner)
	_gloss(r)


## The nth point of an even scatter over `area` (the same every time, so stars stay put).
static func _scatter(area: Rect2, n: int) -> Vector2:
	return area.position + area.size * Vector2(fposmod(0.5 + n * 0.7548777, 1.0), fposmod(0.5 + n * 0.5698403, 1.0))


## A leaf or feather shape from `from` to `to`, `width` across at its middle.
func _leaf(from: Vector2, to: Vector2, width: float, colour: Color) -> void:
	var side := (to - from).orthogonal().normalized() * width / 2.0
	var points := PackedVector2Array()
	for i in 9:
		var t := i / 8.0
		points.append(from.lerp(to, t) + side * sin(t * PI))
	for i in range(7, 0, -1):
		var t := i / 8.0
		points.append(from.lerp(to, t) - side * sin(t * PI))
	_poly(points, colour)


## Harlequin: plum diamonds on plum, a gold lozenge in the middle.
func _back_harlequin(r: Rect2, body: PackedVector2Array, inner: Rect2) -> void:
	_gradient(body, Color("6a3058"), Color("3e1a36"))
	_outline(body, UiTheme.GOLD.darkened(0.25), 1.2)
	_outline(_round_rect(inner, 3.0), UiTheme.GOLD.darkened(0.45), 0.8)
	var c := inner.get_center()
	var k := r.size.x / 60.0
	for row in range(-9, 10):
		for col in range(-5, 6):
			var p := c + Vector2(col * 8 + (4 if row % 2 != 0 else 0), row * 6) * k
			if inner.grow(-3.0 * k).has_point(p):
				_poly(_diamond(p, 2.6 * k, 3.2 * k), Color("85406f"))
	_poly(_diamond(c, r.size.x * 0.2, r.size.x * 0.3), UiTheme.GOLD.darkened(0.15))
	_poly(_diamond(c, r.size.x * 0.1, r.size.x * 0.15), Color("6a3058"))


## Sun and moon: a gold sun over a silver crescent in a starry blue.
func _back_sun_and_moon(r: Rect2, body: PackedVector2Array, inner: Rect2) -> void:
	_gradient(body, Color("2a3c7e"), Color("0e1638"))
	_outline(body, UiTheme.GOLD.darkened(0.2), 1.2)
	_outline(_round_rect(inner, 3.0), Color(UiTheme.GOLD, 0.45), 0.8)
	var w := r.size.x
	for i in 22:
		_dot(_scatter(inner.grow(-2.0), i), w * (0.012 + 0.008 * (i % 3)), Color(1, 1, 1, 0.35 + 0.2 * (i % 3)))
	var sun := r.get_center() + Vector2(0, -r.size.y * 0.15)
	for i in 12:
		var a := i * TAU / 12.0
		var tip := sun + Vector2(cos(a), sin(a)) * w * (0.32 if i % 2 == 0 else 0.26)
		var side := Vector2(cos(a + PI / 2.0), sin(a + PI / 2.0)) * w * 0.045
		_poly(PackedVector2Array([sun + side, tip, sun - side]), UiTheme.GOLD.darkened(0.1))
	_dot(sun, w * 0.18, UiTheme.GOLD)
	_dot(sun + Vector2(-w * 0.05, -w * 0.05), w * 0.06, Color(1, 1, 1, 0.35))
	var moon := r.get_center() + Vector2(0, r.size.y * 0.22)
	_dot(moon, w * 0.16, Color("d8e0ee"))
	_dot(moon + Vector2(w * 0.07, -w * 0.04), w * 0.14, Color("15204a"))


## Venetian mask: a gold carnival mask with a feather plume on crimson.
func _back_mask(r: Rect2, body: PackedVector2Array, inner: Rect2) -> void:
	_gradient(body, Color("8e1e34"), Color("3d0a16"))
	_outline(body, UiTheme.GOLD.darkened(0.2), 1.2)
	_outline(_round_rect(inner, 3.0), Color(UiTheme.GOLD, 0.45), 0.8)
	var k := r.size.x / 60.0
	for i in 14:
		var p := _scatter(inner.grow(-2.0), i)
		_poly(_diamond(p, 1.6 * k, 2.4 * k), Color(UiTheme.GOLD, 0.18))
	var c := r.get_center() + Vector2(0, r.size.y * 0.05)
	var s := r.size.x * 0.36
	for f in 3:
		var from := c + Vector2(s * 0.55, -s * 0.3)
		var to := from + Vector2(s * (0.15 + f * 0.25), -s * (1.05 - f * 0.18))
		_leaf(from, to, s * 0.26, [Color("2e9c8f"), Color("f3ead8"), Color("3f8ed8")][f])
		draw_line(from, to, Color(0, 0, 0, 0.3), maxf(0.6, k * 0.6), true)
	var mask := PackedVector2Array()
	for corner in [Vector2(-1.0, -0.08), Vector2(-0.62, -0.42), Vector2(-0.2, -0.3), Vector2(0, -0.18), Vector2(0.2, -0.3),
			Vector2(0.62, -0.42), Vector2(1.0, -0.08), Vector2(0.7, 0.3), Vector2(0.28, 0.26), Vector2(0, 0.1),
			Vector2(-0.28, 0.26), Vector2(-0.7, 0.3)]:
		mask.append(c + corner * s)
	_poly(mask, UiTheme.GOLD)
	_outline(mask, UiTheme.GOLD.darkened(0.4), 0.9)
	for side in [-1.0, 1.0]:
		var eye := PackedVector2Array()
		for i in 14:
			var a := i * TAU / 14.0
			eye.append(c + Vector2(side * s * 0.42 + cos(a) * s * 0.2, -s * 0.04 + sin(a) * s * 0.1))
		_poly(eye, Color("3d0a16"))
	for side in [-1.0, 1.0]:
		var tie := c + Vector2(side * s, -s * 0.08)
		_leaf(tie, tie + Vector2(side * s * 0.12, s * 0.75), s * 0.12, UiTheme.MULT.lightened(0.1))
	_dot(c + Vector2(0, -s * 0.24), s * 0.08, Color("3f8ed8"))


## Curtain: red drapes tied back from a lit stage, under a scalloped valance.
func _back_curtain(r: Rect2, body: PackedVector2Array, inner: Rect2) -> void:
	_gradient(body, Color("2a0e12"), Color("12060a"))
	_outline(body, UiTheme.GOLD.darkened(0.2), 1.2)
	var c := inner.get_center() + Vector2(0, inner.size.y * 0.08)
	var w := inner.size.x
	var h := inner.size.y
	_dot(c, w * 0.42, Color(UiTheme.GOLD, 0.08))
	_dot(c, w * 0.28, Color(UiTheme.GOLD, 0.12))
	_draw_star(c, w * 0.1, UiTheme.GOLD.lightened(0.2))
	var floor_band := Rect2(Vector2(inner.position.x, inner.end.y - h * 0.1), Vector2(w, h * 0.1))
	_gradient(_round_rect(floor_band, 1.0), Color("6e3d1c"), Color("3d2210"))
	for side in [-1.0, 1.0]:
		var edge := inner.position.x if side < 0 else inner.end.x
		var inward: float = -side
		var drape := PackedVector2Array()
		for p in [Vector2(0, 0), Vector2(0.5, 0), Vector2(0.34, 0.32), Vector2(0.2, 0.55), Vector2(0.27, 0.78), Vector2(0.24, 1.0), Vector2(0, 1.0)]:
			drape.append(Vector2(edge + inward * p.x * w, inner.position.y + p.y * h))
		_gradient(drape, UiTheme.MULT, UiTheme.MULT.darkened(0.45))
		for f in 3:
			var x: float = edge + inward * w * (0.08 + f * 0.12)
			draw_line(Vector2(x, inner.position.y), Vector2(edge + inward * w * (0.06 + f * 0.05), inner.position.y + h * 0.55), Color(0, 0, 0, 0.25), maxf(0.6, w * 0.012), true)
		_dot(Vector2(edge + inward * w * 0.2, inner.position.y + h * 0.56), w * 0.05, UiTheme.GOLD)
	var valance := Rect2(inner.position, Vector2(w, h * 0.1))
	_poly(_round_rect(valance, 1.0), UiTheme.MULT.darkened(0.2))
	for i in 5:
		var at := Vector2(inner.position.x + w * (0.1 + i * 0.2), valance.end.y)
		var scallop := PackedVector2Array()
		for j in 9:
			var a := j * PI / 8.0
			scallop.append(at + Vector2(cos(a) * w * 0.1, sin(a) * h * 0.05))
		_poly(scallop, UiTheme.MULT.darkened(0.2))
		draw_arc(at, w * 0.1, 0.1, PI - 0.1, 8, UiTheme.GOLD.darkened(0.1), maxf(0.6, w * 0.012), true)
	_outline(_round_rect(inner, 3.0), Color(UiTheme.GOLD, 0.5), 0.8)


## Night sky: a deep violet sky full of stars, a constellation and one bright star.
func _back_night(r: Rect2, body: PackedVector2Array, inner: Rect2) -> void:
	_gradient(body, Color("2a1650"), Color("060818"))
	_outline(body, Color("a8d0ff").darkened(0.2), 1.2)
	_outline(_round_rect(inner, 3.0), Color("a8d0ff", 0.35), 0.8)
	var w := r.size.x
	for i in 40:
		_dot(_scatter(inner.grow(-1.0), i + 7), w * (0.008 + 0.007 * (i % 3)), Color(1, 1, 1, 0.25 + 0.2 * (i % 4)))
	var shape := PackedVector2Array()
	for p in [Vector2(0.18, 0.2), Vector2(0.36, 0.12), Vector2(0.55, 0.24), Vector2(0.72, 0.16), Vector2(0.82, 0.3)]:
		shape.append(inner.position + inner.size * p)
	draw_polyline(shape, Color(UiTheme.GOLD, 0.5), maxf(0.6, w * 0.01), true)
	for p in shape:
		_dot(p, w * 0.022, UiTheme.GOLD.lightened(0.3))
	var c := r.get_center() + Vector2(0, r.size.y * 0.08)
	_dot(c, w * 0.26, Color("8060d0", 0.12))
	_draw_star(c, w * 0.15, Color("f0e8ff"))
	var moon := inner.position + inner.size * Vector2(0.78, 0.82)
	_dot(moon, w * 0.08, Color("f0d860"))
	_dot(moon + Vector2(w * 0.035, -w * 0.02), w * 0.07, Color("0a0c22"))


## Gold filigree: gold scrollwork and a rosette on dark green, like an old playing card.
func _back_filigree(r: Rect2, body: PackedVector2Array, inner: Rect2) -> void:
	_gradient(body, Color("1a4a34"), Color("08160f"))
	_outline(body, UiTheme.GOLD, 1.3)
	var gold := UiTheme.GOLD.darkened(0.1)
	var line := maxf(0.6, r.size.x * 0.014)
	_outline(_round_rect(inner, 3.0), gold, line)
	_outline(_round_rect(inner.grow(-r.size.x * 0.05), 2.0), Color(gold, 0.6), line * 0.7)
	var step := inner.size.x / 4.0
	for i in range(-6, 7):
		var x := inner.position.x + i * step
		for dir in [1.0, -1.0]:
			var a := Vector2(x, inner.position.y if dir > 0 else inner.end.y)
			var b := a + Vector2(inner.size.y, inner.size.y * dir) * 0.7
			var clipped := Geometry2D.clip_polyline_with_polygon(PackedVector2Array([a, b]), _round_rect(inner.grow(-r.size.x * 0.07), 2.0))
			for seg in clipped:
				draw_polyline(seg, Color(gold, 0.16), line * 0.6, true)
	for corner in [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]:
		var toward: Vector2 = (inner.get_center() - corner).normalized()
		var at: Vector2 = corner + toward * r.size.x * 0.13
		draw_arc(at, r.size.x * 0.06, 0.0, TAU, 16, gold, line, true)
		_dot(at, r.size.x * 0.025, gold)
	var c := r.get_center()
	var s := r.size.x * 0.16
	for i in 8:
		var a := i * TAU / 8.0
		_leaf(c, c + Vector2(cos(a), sin(a)) * s * 1.5, s * 0.55, gold if i % 2 == 0 else gold.darkened(0.25))
	_dot(c, s * 0.45, Color("1a4a34"))
	_dot(c, s * 0.3, UiTheme.MULT)
	_dot(c + Vector2(-s * 0.08, -s * 0.08), s * 0.1, Color(1, 1, 1, 0.4))
	for dir in [-1.0, 1.0]:
		_poly(_diamond(c + Vector2(0, dir * r.size.y * 0.3), s * 0.25, s * 0.45), gold)


func _draw_playing(r: Rect2) -> void:
	var enh_def := ContentDB.get_def(card.enhancement)
	var paper := UiTheme.CARD
	if card.enhancement == "enh_marble":
		paper = Color("a4a4ac")
	elif enh_def != null:
		paper = UiTheme.CARD.lerp(_enhancement_tint(card.enhancement), 0.32)
	var body := _round_rect(r, 5.0)
	_gradient(body, paper.lightened(0.1), paper.darkened(0.08))
	_outline(body, EDGE, 1.1)
	_outline(_round_rect(r.grow(-3.0), 3.0), PAPER_LINE, 0.6)
	var k := r.size.x / 60.0
	if card.has_rank():
		var colour := UiTheme.RED_SUIT if card.suit == PlayingCard.Suit.HEARTS or card.suit == PlayingCard.Suit.DIAMONDS else UiTheme.BLACK_SUIT
		_draw_index(k, colour)
		draw_set_transform(r.size, PI)
		_draw_index(k, colour)
		draw_set_transform(Vector2.ZERO)
		if card.enhancement == "enh_motley":
			for s in 4:
				draw_suit(self, r.get_center() + Vector2(((s % 2) - 0.5) * 18 * k, (int(s / 2) - 0.5) * 22 * k), 7.0 * k, s, [UiTheme.BLACK_SUIT, UiTheme.RED_SUIT][s % 2])
		elif card.rank >= 11 and card.rank <= 13:
			_draw_face(r, k, colour)
		elif card.rank == 14:
			draw_arc(r.get_center(), 17.0 * k, 0.0, TAU, 32, colour.lerp(UiTheme.CARD, 0.6), 1.0, true)
			draw_suit(self, r.get_center(), 13.0 * k, card.suit, colour)
		else:
			var area := Rect2(Vector2(18, 18) * k, r.size - Vector2(36, 36) * k)
			for pip in PIPS.get(card.rank, []):
				var at := area.position + Vector2(area.size.x * pip[0] / 2.0, area.size.y * pip[1])
				draw_suit(self, at, 5.0 * k, card.suit, colour)
	else:
		draw_string(UiTheme.font, Vector2(4, r.size.y / 2.0 + 4), "MARBLE", HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 8, 10, INK)
	if enh_def != null and card.enhancement != "enh_marble":
		var band := Rect2(Vector2(4, r.size.y - 14), Vector2(r.size.x - 8, 10))
		draw_colored_polygon(_round_rect(band, 2.0), _enhancement_tint(card.enhancement).darkened(0.3))
		var short := UiTheme.name_of(card.enhancement).to_upper()
		draw_string(UiTheme.font, band.position + Vector2(0, 8), short, HORIZONTAL_ALIGNMENT_CENTER, band.size.x, 8, UiTheme.TEXT)
	if SEAL_COLOURS.has(card.seal):
		var at := Vector2(r.size.x - 9 * k, 9 * k)
		_dot(at, 4.8 * k, SEAL_COLOURS[card.seal].darkened(0.45))
		_dot(at, 3.8 * k, SEAL_COLOURS[card.seal])
		_dot(at + Vector2(-1.2, -1.2) * k, 1.2 * k, Color(1, 1, 1, 0.6))
	_gloss(r)


## The rank and a small suit in the top-left corner (drawn twice, once turned round).
func _draw_index(k: float, colour: Color) -> void:
	var rank_text := str(RANKS.get(card.rank, card.rank))
	draw_string(UiTheme.font, Vector2(4, 14) * k, rank_text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(round(14 * k)), colour)
	draw_suit(self, Vector2(9, 21) * k, 3.5 * k, card.suit, colour)


## Jack, Queen and King: a framed portrait on the suit's colour, with a fool's cap, a small
## crown or a large one, over a robe trimmed in gold.
func _draw_face(r: Rect2, k: float, colour: Color) -> void:
	var frame := Rect2(Vector2(14, 14) * k, r.size - Vector2(28, 28) * k)
	var back := _round_rect(frame, 2.0)
	_gradient(back, colour.lerp(UiTheme.CARD, 0.82), colour.lerp(UiTheme.CARD, 0.6))
	_outline(back, colour, 0.8)
	var c := frame.get_center() + Vector2(0, 2 * k)
	var s := frame.size.x * 0.44
	var robe := PackedVector2Array([
		Vector2(c.x - s * 0.95, frame.end.y), Vector2(c.x - s * 0.7, c.y + s * 0.55),
		Vector2(c.x, c.y + s * 0.4), Vector2(c.x + s * 0.7, c.y + s * 0.55), Vector2(c.x + s * 0.95, frame.end.y),
	])
	_poly(robe, colour)
	draw_line(Vector2(c.x, c.y + s * 0.45), Vector2(c.x, frame.end.y), UiTheme.GOLD, 1.2 * k, true)
	_draw_ruff(c + Vector2(0, s * 0.5), s * 0.9, UiTheme.CARD.darkened(0.05))
	_draw_head(c, s, SKINS[1], card.rank * 7)
	if card.rank == 11:
		_draw_cap(c, s, colour, UiTheme.GOLD, 2)
	else:
		_draw_crown(c, s, colour, 0.55 if card.rank == 13 else 0.36)
	draw_suit(self, frame.position + Vector2(5, 6) * k, 3.0 * k, card.suit, colour)


# --- named cards ---

func _draw_named(r: Rect2) -> void:
	var def := ContentDB.get_def(def_id)
	var colour: Color = KIND_COLOURS.get(kind, UiTheme.PANEL_LIGHT)
	if kind == "zanni" and def != null:
		colour = RARITY_COLOURS[clampi(def.rarity, 0, 3)]
	var body := _round_rect(r, 5.0)
	_gradient(body, colour.lightened(0.18), colour.darkened(0.2))
	_outline(body, colour.lightened(0.5), 1.1)
	var window := Rect2(Vector2(4, 4), Vector2(r.size.x - 8, r.size.y * 0.6))
	var pane := _round_rect(window, 3.0)
	var seed_value := absi(def_id.hash())
	if kind == "zanni" and JesterArt.has_design(def_id):
		JesterArt.new(self).draw(window, pane, def_id)
	else:
		_draw_picture(window, pane, colour, seed_value)
	var rarity := clampi(def.rarity, 0, 3) if kind == "zanni" and def != null else 0
	_draw_frame_marks(r, window, pane, colour, rarity, kind == "zanni" and def != null)
	_draw_ribbon(r, window.end.y + 4, colour)
	if sticker != "":
		draw_string(UiTheme.font, Vector2(7, 13), sticker.left(1).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UiTheme.GOLD)
	_gloss(r)


## The picture for a card without a hand-made design: a generated Jester, or the icon of a
## Tarocchi, Sign, Omen, pack or Warrant, on a soft sunburst.
func _draw_picture(window: Rect2, pane: PackedVector2Array, colour: Color, seed_value: int) -> void:
	var backdrop: Color = BACKDROPS[(seed_value / 3) % BACKDROPS.size()] if kind == "zanni" else colour.darkened(0.55)
	_gradient(pane, backdrop.lightened(0.18), backdrop.darkened(0.25))
	_draw_pattern(pane, window, colour, seed_value if kind == "zanni" else -1)
	for i in 3:
		_dot(window.get_center(), window.size.x * (0.42 - i * 0.1), Color(colour.lightened(0.4), 0.06))
	match kind:
		"zanni":
			_draw_jester(window, seed_value)
		"tarocchi":
			_draw_star(window.get_center(), window.size.x * 0.32, UiTheme.GOLD)
		"sign":
			_draw_sign(window, seed_value, colour.darkened(0.6))
		"omen":
			_draw_eye(window)
		"pack":
			_draw_pack(window, colour)
		"warrant":
			_draw_scroll(window)


## The picture's frame and a Jester's rarity: gold edging and corner diamonds from Rare up,
## a rainbow sheen and inner gold line on a Legendary, and one gem per rarity step.
func _draw_frame_marks(r: Rect2, window: Rect2, pane: PackedVector2Array, colour: Color, rarity: int, gems: bool) -> void:
	if rarity == 3:
		var sheen := PackedColorArray()
		var hues := [Color("ff8fd0"), Color("7fffd4"), Color("f0d060"), Color("8fb0ff")]
		for i in pane.size():
			sheen.append(Color(hues[i % hues.size()], 0.16))
		draw_polygon(pane, sheen)
	_outline(pane, UiTheme.GOLD if rarity >= 2 else colour.lightened(0.3), 0.9 if rarity >= 2 else 0.7)
	if rarity == 3:
		_outline(_round_rect(r.grow(-2.0), 4.0), UiTheme.GOLD, 0.8)
	if rarity >= 2:
		for corner in [Vector2(3, 3), Vector2(r.size.x - 3, 3), Vector2(3, r.size.y - 3), Vector2(r.size.x - 3, r.size.y - 3)]:
			_poly(_diamond(corner, 2.4, 2.4), UiTheme.GOLD)
	if gems:
		for i in rarity + 1:
			var at := Vector2(r.size.x / 2.0 + (i - rarity / 2.0) * 7.0, window.end.y)
			_poly(_diamond(at, 2.8, 3.6), UiTheme.GOLD.darkened(0.35))
			_poly(_diamond(at, 2.0, 2.8), UiTheme.GOLD)


## The card's name on a notched ribbon under the picture (up to three lines).
func _draw_ribbon(r: Rect2, top: float, colour: Color) -> void:
	var title := UiTheme.name_of(def_id) if def_id != "" else ""
	# Long names shrink until they fit in two lines ("Il Venditore di Almanacchi").
	var font_size := 8
	var lines := _wrap(title, r.size.x - 10, font_size)
	while font_size > 5 and (lines.size() > 2 or _widest(lines, font_size) > r.size.x - 8):
		font_size -= 1
		lines = _wrap(title, r.size.x - 10, font_size)
	lines = lines.slice(0, 3)
	var line_h := font_size + 1.0
	var h := maxf(12.0, lines.size() * line_h + 4.0)
	var x0 := 2.0
	var x1 := r.size.x - 2.0
	var band := PackedVector2Array([
		Vector2(x0, top), Vector2(x1, top), Vector2(x1 - 3, top + h / 2.0), Vector2(x1, top + h),
		Vector2(x0, top + h), Vector2(x0 + 3, top + h / 2.0),
	])
	_poly(band, colour.darkened(0.5))
	var y := top + 1.0 + line_h
	for line in lines:
		draw_string(UiTheme.font, Vector2(4, y), line, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 8, font_size, UiTheme.TEXT)
		y += line_h


func _widest(lines: Array, font_size: int) -> float:
	var widest := 0.0
	for line in lines:
		widest = maxf(widest, UiTheme.font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	return widest


## The picture's backdrop, clipped to its window: for a Jester one of four poster patterns
## (sunburst, harlequin lattice, rings, stripes) picked by its id; for other cards a soft
## sunburst.
func _draw_pattern(pane: PackedVector2Array, window: Rect2, colour: Color, n: int) -> void:
	var c := window.get_center()
	var far := window.size.length()
	var light := Color(colour.lightened(0.45), 0.24)
	var shapes: Array[PackedVector2Array] = []
	match (n / 29) % 4 if n >= 0 else 0:
		0:
			for i in 16:
				if i % 2 == 0:
					var a0 := i * TAU / 16.0
					var a1 := (i + 1) * TAU / 16.0
					shapes.append(PackedVector2Array([c, c + Vector2(cos(a0), sin(a0)) * far, c + Vector2(cos(a1), sin(a1)) * far]))
		1:
			var cell := window.size.x / 4.0
			for row in range(-1, 7):
				for col in range(-1, 6):
					if (row + col) % 2 == 0:
						shapes.append(_diamond(window.position + Vector2(col * cell, row * cell * 1.3), cell / 2.0, cell * 0.65))
		2:
			for i in range(7, 0, -1):
				if i % 2 == 1:
					var ring := PackedVector2Array()
					for k in 24:
						ring.append(c + Vector2(cos(k * TAU / 24.0), sin(k * TAU / 24.0)) * window.size.x * 0.13 * i)
					shapes.append(ring)
		3:
			var band := window.size.x / 5.0
			for i in range(-6, 8, 2):
				var x := window.position.x + i * band
				shapes.append(PackedVector2Array([Vector2(x, window.position.y), Vector2(x + band, window.position.y), Vector2(x + band + window.size.y, window.end.y), Vector2(x + window.size.y, window.end.y)]))
	for shape in shapes:
		for piece in Geometry2D.intersect_polygons(shape, pane):
			draw_colored_polygon(piece, light)


## A Jester's portrait: a harlequin costume, the face (some behind Arlecchino's black
## half-mask), a ruff, a belled cap and a prop in hand. Colours, the cap's points, the face,
## the expression and the prop come from the card's id, so each Jester keeps its own look.
func _draw_jester(window: Rect2, n: int) -> void:
	var c := window.get_center() + Vector2(0, window.size.y * 0.02)
	var s := minf(window.size.x, window.size.y) * 0.46
	var a: Color = COSTUME_COLOURS[n % COSTUME_COLOURS.size()]
	var b: Color = COSTUME_COLOURS[(n / 8 + 3) % COSTUME_COLOURS.size()]
	if b == a:
		b = COSTUME_COLOURS[(n + 1) % COSTUME_COLOURS.size()]
	var torso := PackedVector2Array([
		Vector2(c.x - s * 1.0, window.end.y), Vector2(c.x - s * 0.62, c.y + s * 0.55),
		Vector2(c.x + s * 0.62, c.y + s * 0.55), Vector2(c.x + s * 1.0, window.end.y),
	])
	_poly(torso, a)
	var cell := s * 0.28
	for row in 4:
		for col in range(-4, 5):
			var at := Vector2(c.x + col * cell + (cell / 2.0 if row % 2 == 1 else 0.0), c.y + s * 0.7 + row * cell * 0.9)
			var d := _diamond(at, cell * 0.42, cell * 0.5)
			var inside := true
			for p in d:
				if not Geometry2D.is_point_in_polygon(p, torso):
					inside = false
			if inside and (row + col) % 2 == 0:
				_poly(d, b)
	_draw_ruff(c + Vector2(0, s * 0.52), s, b.lerp(Color.WHITE, 0.35))
	_draw_head(c, s, SKINS[(n / 64) % SKINS.size()], n)
	if (n / 17) % 3 == 0:
		_draw_mask(c, s)
	_draw_cap(c, s, a, b, 2 + (n / 5) % 2)
	_draw_prop(window, c, s, (n / 13) % 6, a, b)


## Arlecchino's black half-mask across the eyes, with the eyes showing through.
func _draw_mask(c: Vector2, s: float) -> void:
	var y := c.y - s * 0.05
	_poly(PackedVector2Array([
		Vector2(c.x - s * 0.4, y - s * 0.02), Vector2(c.x - s * 0.2, y - s * 0.16), Vector2(c.x, y - s * 0.08),
		Vector2(c.x + s * 0.2, y - s * 0.16), Vector2(c.x + s * 0.4, y - s * 0.02), Vector2(c.x + s * 0.22, y + s * 0.12),
		Vector2(c.x, y + s * 0.05), Vector2(c.x - s * 0.22, y + s * 0.12),
	]), Color("1a141f"))
	for side in [-1.0, 1.0]:
		_dot(Vector2(c.x + side * s * 0.16, y), s * 0.06, Color.WHITE)
		_dot(Vector2(c.x + side * s * 0.16, y + s * 0.01), s * 0.035, INK)


## Something in the Jester's hands: juggling balls, a marotte (a jester's stick with its own
## little head), a lute, a fan of cards, a slapstick, or nothing.
func _draw_prop(window: Rect2, c: Vector2, s: float, prop: int, a: Color, b: Color) -> void:
	var hand := Vector2(c.x + s * 0.72, c.y + s * 0.78)
	match prop:
		0:
			var colours := [UiTheme.MULT, UiTheme.POINTS, UiTheme.GOLD]
			for i in 3:
				var at := c + Vector2(s * (0.55 + 0.25 * i), -s * (0.15 + 0.35 * sin(i * 1.3)))
				_dot(at, s * 0.12, colours[i])
				_dot(at + Vector2(-s * 0.04, -s * 0.04), s * 0.04, Color(1, 1, 1, 0.6))
		1:
			var top := Vector2(window.end.x - s * 0.25, c.y - s * 0.35)
			draw_line(Vector2(top.x - s * 0.08, window.end.y), top, Color("8a5a2c"), maxf(1.0, s * 0.07), true)
			_dot(top, s * 0.16, SKINS[1])
			_poly(PackedVector2Array([top + Vector2(-s * 0.18, -s * 0.05), top + Vector2(-s * 0.3, -s * 0.35), top + Vector2(0, -s * 0.12), top + Vector2(s * 0.3, -s * 0.35), top + Vector2(s * 0.18, -s * 0.05)]), b)
			_dot(top + Vector2(-s * 0.3, -s * 0.35), s * 0.06, UiTheme.GOLD)
			_dot(top + Vector2(s * 0.3, -s * 0.35), s * 0.06, UiTheme.GOLD)
		2:
			var body := hand + Vector2(-s * 0.05, -s * 0.05)
			draw_line(body, body + Vector2(s * 0.5, -s * 0.75), Color("5a3a1c"), maxf(1.0, s * 0.08), true)
			var oval := PackedVector2Array()
			for k in 16:
				oval.append(body + Vector2(cos(k * TAU / 16.0) * s * 0.24, sin(k * TAU / 16.0) * s * 0.3))
			_poly(oval, Color("c08040"))
			_dot(body, s * 0.07, Color("4a2a10"))
		3:
			var at := Vector2(c.x - s * 0.75, c.y + s * 0.75)
			for i in 3:
				var angle := -0.5 + i * 0.4
				var card := PackedVector2Array()
				for corner in [Vector2(-0.12, -0.42), Vector2(0.12, -0.42), Vector2(0.12, 0), Vector2(-0.12, 0)]:
					card.append(at + (corner * s).rotated(angle))
				_poly(card, UiTheme.CARD)
				_outline(card, EDGE, 0.5)
				_dot(at + (Vector2(0, -0.28) * s).rotated(angle), s * 0.05, UiTheme.RED_SUIT if i % 2 == 0 else INK)
		4:
			for side in [-1.0, 1.0]:
				var slat := PackedVector2Array([hand + Vector2(-s * 0.05 + side * 0.03 * s, 0), hand + Vector2(s * 0.05 + side * 0.03 * s, 0), hand + Vector2(s * 0.25 + side * 0.1 * s, -s * 0.85), hand + Vector2(s * 0.15 + side * 0.1 * s, -s * 0.85)])
				_poly(slat, Color("d8b070") if side < 0 else Color("b08848"))
			_poly(_round_rect(Rect2(hand - Vector2(s * 0.09, s * 0.02), Vector2(s * 0.18, s * 0.16)), 1.0), a.darkened(0.3))


## A face: eyes with whites, rosy cheeks, a nose and one of three expressions.
func _draw_head(c: Vector2, s: float, skin: Color, n: int) -> void:
	_dot(c, s * 0.42, skin)
	draw_arc(c, s * 0.42, 0.0, TAU, 24, skin.darkened(0.3), 0.7, true)
	for side in [-1.0, 1.0]:
		var eye := c + Vector2(side * s * 0.16, -s * 0.05)
		_dot(eye, s * 0.075, Color.WHITE)
		_dot(eye + Vector2(0, s * 0.01), s * 0.042, INK)
		_dot(c + Vector2(side * s * 0.25, s * 0.12), s * 0.07, Color(0.9, 0.35, 0.35, 0.45))
	if (n / 11) % 3 == 0:
		_dot(c + Vector2(0, s * 0.08), s * 0.07, Color("d8433a"))
	else:
		_dot(c + Vector2(0, s * 0.08), s * 0.045, skin.darkened(0.25))
	match (n / 7) % 3:
		0:
			draw_arc(c + Vector2(0, s * 0.1), s * 0.18, 0.35, PI - 0.35, 10, INK, 1.0, true)
		1:
			draw_arc(c + Vector2(0, s * 0.33), s * 0.14, PI + 0.5, TAU - 0.5, 10, INK, 1.0, true)
		2:
			_dot(c + Vector2(0, s * 0.24), s * 0.065, INK)
	if (n / 3) % 2 == 0:
		_poly(_diamond(c + Vector2(s * 0.17, s * 0.15), s * 0.05, s * 0.09), Color("2a2433"))


## A fool's cap with two or three points and a bell on each.
func _draw_cap(c: Vector2, s: float, a: Color, b: Color, points: int) -> void:
	var left := Vector2(c.x - s * 0.46, c.y - s * 0.26)
	var right := Vector2(c.x + s * 0.46, c.y - s * 0.26)
	var tips := [Vector2(c.x - s * 0.92, c.y - s * 0.6), Vector2(c.x + s * 0.92, c.y - s * 0.6)]
	if points == 3:
		tips.insert(1, Vector2(c.x, c.y - s * 0.98))
	for i in tips.size():
		var from := left.lerp(right, float(i) / tips.size())
		var to := left.lerp(right, float(i + 1) / tips.size())
		_poly(PackedVector2Array([from, tips[i], to, (from + to) / 2.0 + Vector2(0, s * 0.06)]), a if i % 2 == 0 else b)
	var band := PackedVector2Array([left + Vector2(-s * 0.04, -s * 0.06), right + Vector2(s * 0.04, -s * 0.06), right + Vector2(s * 0.04, s * 0.06), left + Vector2(-s * 0.04, s * 0.06)])
	_poly(band, b.darkened(0.25))
	for tip in tips:
		_dot(tip, s * 0.12, UiTheme.GOLD.darkened(0.2))
		_dot(tip + Vector2(-s * 0.03, -s * 0.03), s * 0.06, UiTheme.GOLD.lightened(0.3))


func _draw_crown(c: Vector2, s: float, colour: Color, tall: float) -> void:
	var base := c.y - s * 0.3
	var crown := PackedVector2Array([
		Vector2(c.x - s * 0.45, base), Vector2(c.x - s * 0.45, base - s * tall),
		Vector2(c.x - s * 0.22, base - s * tall * 0.55), Vector2(c.x, base - s * tall * 1.15),
		Vector2(c.x + s * 0.22, base - s * tall * 0.55), Vector2(c.x + s * 0.45, base - s * tall),
		Vector2(c.x + s * 0.45, base),
	])
	_poly(crown, UiTheme.GOLD)
	draw_line(Vector2(c.x - s * 0.45, base - s * 0.06), Vector2(c.x + s * 0.45, base - s * 0.06), UiTheme.GOLD.darkened(0.3), 1.0, true)
	_dot(Vector2(c.x, base - s * tall * 0.45), s * 0.07, colour)
	_dot(Vector2(c.x - s * 0.25, base - s * tall * 0.3), s * 0.045, Color("3f8ed8"))
	_dot(Vector2(c.x + s * 0.25, base - s * tall * 0.3), s * 0.045, Color("6cc46a"))


## A pleated collar: a zigzag of points under the chin.
func _draw_ruff(c: Vector2, s: float, colour: Color) -> void:
	var w := s * 1.1
	var pleats := 6
	for i in pleats:
		var x0 := c.x - w / 2.0 + w * i / pleats
		var x1 := x0 + w / pleats
		_poly(PackedVector2Array([Vector2(x0, c.y - s * 0.1), Vector2(x1, c.y - s * 0.1), Vector2((x0 + x1) / 2.0, c.y + s * 0.2)]), colour if i % 2 == 0 else colour.darkened(0.15))


func _draw_star(c: Vector2, s: float, colour: Color) -> void:
	for i in 12:
		var angle := i * TAU / 12.0
		draw_line(c + Vector2(cos(angle), sin(angle)) * s * 0.6, c + Vector2(cos(angle), sin(angle)) * s * 1.25, Color(colour, 0.35), 1.0, true)
	var points := PackedVector2Array()
	for i in 10:
		var radius := s if i % 2 == 0 else s * 0.45
		var angle := -PI / 2.0 + i * PI / 5.0
		points.append(c + Vector2(cos(angle), sin(angle)) * radius)
	_poly(points, colour)
	_dot(c, s * 0.2, colour.lightened(0.6))


## A Sign: a crescent in a ring, with a small constellation drawn round it.
func _draw_sign(window: Rect2, n: int, sky: Color) -> void:
	var c := window.get_center()
	var s := minf(window.size.x, window.size.y) * 0.34
	var light := Color("a8d0ff")
	draw_arc(c, s * 1.05, 0.0, TAU, 32, light, 1.0, true)
	_dot(c + Vector2(-s * 0.15, 0), s * 0.55, light)
	_dot(c + Vector2(s * 0.08, -s * 0.1), s * 0.5, sky)
	var stars := PackedVector2Array()
	for i in 4:
		var angle := float((n >> (i * 3)) % 8) / 8.0 * TAU + i * 0.4
		stars.append(c + Vector2(cos(angle), sin(angle)) * s * 1.35)
	draw_polyline(stars, Color(UiTheme.GOLD, 0.5), 0.7, true)
	for p in stars:
		_dot(p, 1.4, UiTheme.GOLD)


func _draw_eye(window: Rect2) -> void:
	var c := window.get_center()
	var s := window.size.x * 0.36
	var lid := PackedVector2Array()
	for i in 17:
		var t := float(i) / 16.0
		lid.append(c + Vector2(lerpf(-s, s, t), -sin(t * PI) * s * 0.55))
	for i in range(15, 0, -1):
		var t := float(i) / 16.0
		lid.append(c + Vector2(lerpf(-s, s, t), sin(t * PI) * s * 0.55))
	_poly(lid, UiTheme.CARD)
	_dot(c, s * 0.4, Color("2e9c8f"))
	_dot(c, s * 0.18, INK)
	_dot(c + Vector2(-s * 0.12, -s * 0.12), s * 0.08, Color.WHITE)
	for i in 5:
		var x := lerpf(-s * 0.7, s * 0.7, i / 4.0)
		draw_line(c + Vector2(x, -s * 0.5), c + Vector2(x * 1.15, -s * 0.75), UiTheme.CARD, 0.8, true)


func _draw_pack(window: Rect2, colour: Color) -> void:
	var c := window.get_center() + Vector2(0, 2)
	var box := Rect2(c - Vector2(window.size.x * 0.3, window.size.y * 0.22), Vector2(window.size.x * 0.6, window.size.y * 0.5))
	_gradient(_round_rect(box, 2.0), colour.lightened(0.35), colour.lightened(0.05))
	_poly(PackedVector2Array([box.position, box.position + Vector2(box.size.x, 0), box.position + Vector2(box.size.x, box.size.y * 0.22), box.position + Vector2(0, box.size.y * 0.22)]), colour.lightened(0.5))
	draw_rect(Rect2(Vector2(c.x - 2, box.position.y), Vector2(4, box.size.y)), UiTheme.MULT)
	var top := Vector2(c.x, box.position.y)
	_poly(PackedVector2Array([top, top + Vector2(-8, -6), top + Vector2(-7, 3)]), UiTheme.MULT)
	_poly(PackedVector2Array([top, top + Vector2(8, -6), top + Vector2(7, 3)]), UiTheme.MULT)
	_dot(top, 2.2, UiTheme.MULT.darkened(0.2))


func _draw_scroll(window: Rect2) -> void:
	var c := window.get_center()
	var paper := Rect2(c - Vector2(window.size.x * 0.28, window.size.y * 0.3), Vector2(window.size.x * 0.56, window.size.y * 0.6))
	_gradient(_round_rect(paper, 1.5), UiTheme.CARD, UiTheme.CARD.darkened(0.12))
	for y in [paper.position.y, paper.end.y]:
		_poly(_round_rect(Rect2(Vector2(paper.position.x - 3, y - 2.5), Vector2(paper.size.x + 6, 5)), 2.5), UiTheme.CARD.darkened(0.25))
	for i in 4:
		var y := paper.position.y + 7 + i * 5
		draw_line(Vector2(paper.position.x + 4, y), Vector2(paper.end.x - 4 - (8 if i == 3 else 0), y), Color("b0a080"), 0.8, true)
	_dot(Vector2(paper.end.x - 5, paper.end.y - 6), 4.0, UiTheme.MULT)
	_dot(Vector2(paper.end.x - 6, paper.end.y - 7), 1.4, Color(1, 1, 1, 0.5))


static func _diamond(c: Vector2, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(0, -h), c + Vector2(w, 0), c + Vector2(0, h), c + Vector2(-w, 0)])


func _wrap(text: String, width: float, font_size: int) -> Array:
	var lines := []
	var current := ""
	for word in text.split(" "):
		var attempt := word if current == "" else current + " " + word
		if UiTheme.font.get_string_size(attempt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width and current != "":
			lines.append(current)
			current = word
		else:
			current = attempt
	if current != "":
		lines.append(current)
	return lines


func _enhancement_tint(enh: String) -> Color:
	match enh:
		"enh_lacquered":
			return UiTheme.POINTS
		"enh_masked":
			return UiTheme.MULT
		"enh_motley":
			return Color("e0c040")
		"enh_mirror":
			return Color("a8e0ff")
		"enh_iron":
			return Color("707888")
		"enh_gilt":
			return UiTheme.GOLD
		"enh_charmed":
			return UiTheme.GOOD
	return UiTheme.CARD


## Suits drawn as smooth shapes, since the pixel font has no suit symbols.
static func draw_suit(canvas: CanvasItem, c: Vector2, s: float, suit: int, colour: Color) -> void:
	var circle := func(at: Vector2, radius: float) -> void: canvas.draw_circle(at, radius, colour, true, -1.0, true)
	var shape := func(points: PackedVector2Array) -> void:
		canvas.draw_colored_polygon(points, colour)
		var closed := points.duplicate()
		closed.append(points[0])
		canvas.draw_polyline(closed, colour, 0.6, true)
	match suit:
		PlayingCard.Suit.HEARTS:
			circle.call(c + Vector2(-s * 0.45, -s * 0.2), s * 0.5)
			circle.call(c + Vector2(s * 0.45, -s * 0.2), s * 0.5)
			shape.call(PackedVector2Array([c + Vector2(-s * 0.93, -s * 0.05), c + Vector2(s * 0.93, -s * 0.05), c + Vector2(0, s)]))
		PlayingCard.Suit.DIAMONDS:
			shape.call(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.72, 0), c + Vector2(0, s), c + Vector2(-s * 0.72, 0)]))
		PlayingCard.Suit.SPADES:
			circle.call(c + Vector2(-s * 0.45, s * 0.2), s * 0.5)
			circle.call(c + Vector2(s * 0.45, s * 0.2), s * 0.5)
			shape.call(PackedVector2Array([c + Vector2(-s * 0.93, s * 0.05), c + Vector2(s * 0.93, s * 0.05), c + Vector2(0, -s)]))
			shape.call(PackedVector2Array([c + Vector2(0, s * 0.3), c + Vector2(s * 0.35, s), c + Vector2(-s * 0.35, s)]))
		PlayingCard.Suit.CLUBS:
			circle.call(c + Vector2(0, -s * 0.45), s * 0.42)
			circle.call(c + Vector2(-s * 0.45, s * 0.15), s * 0.42)
			circle.call(c + Vector2(s * 0.45, s * 0.15), s * 0.42)
			shape.call(PackedVector2Array([c + Vector2(0, 0), c + Vector2(s * 0.35, s), c + Vector2(-s * 0.35, s)]))
