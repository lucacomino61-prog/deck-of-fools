class_name FlapCell
extends Control
## One character of the station board (an Italian split-flap board): a dark cell split
## across the middle. Told a new character, it flips through the drum towards it, a flap at
## a time: the upper flap falls over the split, then the lower one lands. Far targets skip
## ahead so a cell never takes more than a few flips. With Reduce motion it changes at once.

const DRUM := " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:!?+-%'/>"
## Seconds for one flap.
const FLIP := 0.07
const MOST_FLIPS := 6
const TOP := Color("231c29")
const BOTTOM := Color("19141e")
const SPLIT := Color("0b080e")

## The board's clatter: one tick at most every few milliseconds for all cells together.
static var _last_tick := 0

var shown := " "
var target := " "
var font_size := 16
var colour := UiTheme.TEXT
var _next := " "
var _t := -1.0
var _wait := 0.0
var _top: Control
var _bottom: Control


func _init(cell_size: Vector2, text_size: int, text_colour: Color) -> void:
	size = cell_size
	font_size = text_size
	colour = text_colour
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for top in [true, false]:
		var half := Control.new()
		half.clip_contents = true
		half.mouse_filter = Control.MOUSE_FILTER_IGNORE
		half.position = Vector2(0, 0 if top else cell_size.y / 2.0)
		half.size = Vector2(cell_size.x, cell_size.y / 2.0)
		half.draw.connect(_draw_half.bind(half, top))
		add_child(half)
		if top:
			_top = half
		else:
			_bottom = half
	set_process(false)


## Shows `c` at once.
func set_now(c: String) -> void:
	shown = c
	target = c
	_t = -1.0
	set_process(false)
	_redraw()


## Flips towards `c`, starting after `delay` seconds.
func flip_to(c: String, delay := 0.0) -> void:
	if Settings.reduce_motion or not is_inside_tree():
		set_now(c)
		return
	target = c
	_wait = delay
	if shown != target or _t >= 0.0:
		set_process(true)


func settled() -> bool:
	return shown == target and _t < 0.0


func _process(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		return
	if _t < 0.0:
		if shown == target:
			set_process(false)
			return
		_next = _step_towards(shown, target)
		_t = 0.0
		var now := Time.get_ticks_msec()
		if now - _last_tick > 30:
			_last_tick = now
			Feel.play("tick", randf_range(1.7, 2.3))
	_t += delta / FLIP
	if _t >= 1.0:
		shown = _next
		_t = -1.0
	_redraw()


## The next character on the drum, or a jump ahead when the target is far round it.
static func _step_towards(from: String, to: String) -> String:
	var a := DRUM.find(from)
	var b := DRUM.find(to)
	if a < 0 or b < 0:
		return to
	var distance := posmod(b - a, DRUM.length())
	if distance > MOST_FLIPS:
		return DRUM[posmod(b - MOST_FLIPS + 1, DRUM.length())]
	return DRUM[(a + 1) % DRUM.length()]


func _redraw() -> void:
	_top.queue_redraw()
	_bottom.queue_redraw()


func _draw_half(half: Control, top: bool) -> void:
	var hh := size.y / 2.0
	var old := shown
	var flipping := _t >= 0.0
	var phase := clampf(_t, 0.0, 1.0)
	# What's printed on this half when nothing is moving over it: the new character on top as
	# soon as the flap starts to fall, the old one below until the lower flap lands.
	var still := (_next if flipping else old) if top else old
	_face(half, top, still, 1.0)
	if flipping:
		if top and phase < 0.5:
			# The upper flap, still showing the old character, falls towards the split.
			var k := 1.0 - phase * 2.0
			half.draw_set_transform(Vector2(0, hh * (1.0 - k)), 0.0, Vector2(1, k))
			_face(half, true, old, lerpf(0.55, 1.0, k))
			half.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		elif not top and phase >= 0.5:
			# The lower flap, now showing the new character, lands from the split.
			var k := (phase - 0.5) * 2.0
			half.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, k))
			_face(half, false, _next, lerpf(0.55, 1.0, k))
			half.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# The split, across the letter as on a real board (web/shell.html draws the same).
	if top:
		half.draw_rect(Rect2(0, hh - 0.6, size.x, 0.6), SPLIT)
	else:
		half.draw_rect(Rect2(0, 0, size.x, 0.6), SPLIT)


## One half of the cell with character `c`, `light` darkening a flap mid-fall.
func _face(half: Control, top: bool, c: String, light: float) -> void:
	var hh := size.y / 2.0
	var bg := TOP if top else BOTTOM
	half.draw_rect(Rect2(0, 0, size.x, hh), Color(bg.r * light, bg.g * light, bg.b * light))
	if c == " ":
		return
	var font := UiTheme.title_font
	var w := font.get_char_size(c.unicode_at(0), font_size).x
	var baseline := (size.y + font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	var y := baseline - (0.0 if top else hh)
	half.draw_char(font, Vector2((size.x - w) / 2.0, y), c, font_size, Color(colour.r * light, colour.g * light, colour.b * light))
