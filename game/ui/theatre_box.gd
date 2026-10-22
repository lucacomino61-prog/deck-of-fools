class_name TheatreBox
extends Control
## One of the two theatre boxes (palchi) beside the table during a show on tour (batch 12):
## three spectators who follow the crowd's mood (happy, neutral, grumpy, gone at 0) and
## react to each hand: a cheer (they bob up, roses fly), a gasp (opera glasses up), a boo
## (they shake, a tomato flies). Painted (art/box/left, right, and empty for a walkout)
## once those exist, the picture moving and warming or dimming with the crowd; drawn in
## code until then. It redraws only while it moves.

const SKIN := [Color("f2c9a0"), Color("d9a77c"), Color("b98058"), Color("8d5a3b"), Color("f5d6b8"), Color("c99372")]
const CLOTHES := [Color("7a1f3d"), Color("1f4f7a"), Color("2f6b45"), Color("6a3d9a"), Color("8a5a1a"), Color("3a3a5a")]
## Hats: 0 tricorne, 1 feathered cap, 2 bonnet, 3 powdered wig, 4 bare head.
const HATS := [0, 2, 3, 1, 4, 2]

## Which of the two boxes (left 0, right 1): picks its spectators.
var side := 0
var mood := RunState.MOOD_START:
	set(v):
		mood = v
		queue_redraw()
var _bob := 0.0
var _shake := 0.0
var _glasses := 0.0
var _chant := ""
## The box's paintings, held here so their textures live as long as the box draws them.
var _art: Texture2D
var _empty_art: Texture2D


func _init(box_side := 0) -> void:
	side = box_side
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_art = CardView.painting("box", "left" if side == 0 else "right")
	_empty_art = CardView.painting("box", "empty")


func react(kind: String) -> void:
	if Settings.reduce_motion or mood <= 0:
		return
	var t := create_tween()
	match kind:
		"cheer":
			t.tween_method(_set_bob, 0.0, 1.0, 0.12)
			t.tween_method(_set_bob, 1.0, 0.0, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			Feel.burst(global_position + Vector2(size.x / 2.0, size.y * 0.45), Color("e8414f"), 10)
		"gasp":
			t.tween_method(_set_glasses, 0.0, 1.0, 0.1)
			t.tween_interval(0.7)
			t.tween_method(_set_glasses, 1.0, 0.0, 0.2)
		"boo":
			t.tween_method(_set_shake, 1.0, 0.0, 0.45)
			Feel.burst(global_position + Vector2(size.x / 2.0, size.y * 0.5), Color("d8402a"), 6)


## A word or two above the box ("Bis!"), or "" for none.
func chant(text: String) -> void:
	_chant = text
	queue_redraw()


func _set_bob(v: float) -> void:
	_bob = v
	queue_redraw()


func _set_shake(v: float) -> void:
	_shake = v
	queue_redraw()


func _set_glasses(v: float) -> void:
	_glasses = v
	queue_redraw()


func _draw() -> void:
	if _art != null:
		_draw_painted()
		_draw_chant(size.x)
		return
	var w := size.x
	var h := size.y
	var rail_y := h * 0.66
	# The box: a dark opening in a red wall, under a scalloped valance.
	draw_rect(Rect2(0, 0, w, h), Color("4a0f1c"))
	var opening := Rect2(4, 10, w - 8, rail_y - 6)
	draw_rect(opening, Color("1a0a10"))
	for i in 6:
		draw_rect(Rect2(opening.position + Vector2(0, i * opening.size.y / 6.0), Vector2(opening.size.x, opening.size.y / 6.0)), Color(1.0, 0.75, 0.4, 0.035 * (6 - i)))
	if mood > 0:
		var seats := 3
		for i in seats:
			_draw_spectator(Vector2(w * (0.22 + 0.28 * i), rail_y), i)
	# The front: a gold rail, balusters and a velvet panel with gold trim.
	draw_rect(Rect2(0, rail_y, w, h - rail_y), Color("6a1426"))
	draw_rect(Rect2(0, rail_y, w, 3), UiTheme.GOLD)
	for i in 7:
		var x := 3.0 + i * (w - 6.0) / 6.0
		draw_rect(Rect2(x - 1, rail_y + 3, 2, 7), UiTheme.GOLD.darkened(0.25))
	draw_rect(Rect2(0, rail_y + 10, w, 1.5), UiTheme.GOLD.darkened(0.15))
	draw_rect(Rect2(3, rail_y + 14, w - 6, h - rail_y - 18), Color("801a30"))
	_draw_frame(Rect2(3, rail_y + 14, w - 6, h - rail_y - 18), UiTheme.GOLD.darkened(0.3))
	_draw_curtains(w, rail_y, Game.profile.worn_colour("curtain", Color("9a1b2e")))
	_draw_chant(w)


## Curtains: a swag on each side and a scalloped valance with fringe, in the colour worn in
## the Wagon (batch 13).
func _draw_curtains(w: float, rail_y: float, drape: Color) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(9, 0), Vector2(5, rail_y * 0.6), Vector2(0, rail_y)]), drape)
	draw_colored_polygon(PackedVector2Array([Vector2(w, 0), Vector2(w - 9, 0), Vector2(w - 5, rail_y * 0.6), Vector2(w, rail_y)]), drape)
	draw_rect(Rect2(0, 0, w, 9), drape.darkened(0.1))
	for i in 5:
		var cx := (i + 0.5) * w / 5.0
		draw_circle(Vector2(cx, 9), w / 10.0, drape.darkened(0.1))
		draw_circle(Vector2(cx, 11), 1.2, UiTheme.GOLD)


## The painting, cut to the box's shape around the middle and drawn a little larger than the
## box, so a bob or a shake never shows its edge; a happy crowd glows warmer, an unhappy one
## dims, and an empty house shows the empty box.
func _draw_painted() -> void:
	var tex := _art
	var tint := Color.WHITE
	if mood <= 0:
		tex = _empty_art if _empty_art != null else _art
		tint = Color(0.5, 0.5, 0.6) if _empty_art == null else Color.WHITE
	elif mood >= RunState.ENCORE_MOOD:
		tint = Color(1.08, 1.0, 0.9)
	elif mood <= 3:
		tint = Color(0.72, 0.72, 0.82)
	if _glasses > 0.0:
		tint = tint.lerp(Color(1.2, 1.15, 1.05), _glasses * 0.6)
	var src_w := minf(tex.get_width(), tex.get_height() * size.x / size.y)
	var src := Rect2((tex.get_width() - src_w) / 2.0, 0, src_w, tex.get_height())
	var shift := Vector2(sin(_shake * 40.0) * 2.0 * _shake, -_bob * 3.0)
	draw_texture_rect_region(tex, Rect2(Vector2(-3, -3) + shift, size + Vector2(6, 6)), src, tint)
	if str(Game.profile.worn.get("curtain", "")) != "":
		_draw_curtains(size.x, size.y * 0.66, Game.profile.worn_colour("curtain", Color("9a1b2e")))
	draw_rect(Rect2(Vector2.ZERO, size), UiTheme.GOLD.darkened(0.3), false, 1.0)


func _draw_chant(w: float) -> void:
	if _chant != "":
		# A speech bubble in the dark above the spectators' heads.
		var font := UiTheme.title_font
		var text_w := font.get_string_size(_chant, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		var bubble := Rect2((w - text_w) / 2.0 - 3.0, 15, text_w + 6.0, 13)
		draw_rect(bubble, Color("fff2d6"))
		draw_colored_polygon(PackedVector2Array([Vector2(w / 2.0 - 3, bubble.end.y), Vector2(w / 2.0 + 3, bubble.end.y), Vector2(w / 2.0, bubble.end.y + 4)]), Color("fff2d6"))
		draw_string(font, Vector2(bubble.position.x + 3.0, bubble.end.y - 3.0), _chant, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("6a1426"))


func _draw_spectator(base: Vector2, seat: int) -> void:
	var n := side * 3 + seat
	var skin: Color = SKIN[n % SKIN.size()]
	var cloth: Color = CLOTHES[(n * 2 + 1) % CLOTHES.size()]
	var hat: int = HATS[n % HATS.size()]
	var jitter := sin(float(seat) * 2.1 + _shake * 30.0) * 2.0 * _shake
	var lift := _bob * (3.0 + seat % 2)
	var head := base + Vector2(jitter, -16.0 - lift - (seat % 2) * 1.5)
	var r := 5.2
	# Shoulders and head.
	draw_colored_polygon(PackedVector2Array([base + Vector2(-9 + jitter, 0), base + Vector2(-7 + jitter, -9 - lift), base + Vector2(7 + jitter, -9 - lift), base + Vector2(9 + jitter, 0)]), cloth)
	draw_circle(head + Vector2(0, r * 0.9), 1.6, Color(1, 1, 1, 0.8))
	draw_circle(head, r, skin)
	if hat == 3:
		for a in [-1, 1]:
			draw_circle(head + Vector2(a * r * 0.85, 1), 2.6, Color("e8e2d6"))
		draw_circle(head + Vector2(0, -r * 0.6), r * 0.85, Color("efe9de"))
	elif hat == 0:
		draw_colored_polygon(PackedVector2Array([head + Vector2(-r - 2, -r * 0.4), head + Vector2(0, -r - 4), head + Vector2(r + 2, -r * 0.4), head + Vector2(0, -r * 0.9)]), Color("1c1414"))
	elif hat == 1:
		draw_colored_polygon(PackedVector2Array([head + Vector2(-r, -r * 0.5), head + Vector2(-r * 0.6, -r - 2), head + Vector2(r * 0.8, -r - 1.5), head + Vector2(r, -r * 0.4)]), cloth.darkened(0.3))
		draw_line(head + Vector2(r * 0.4, -r - 1.5), head + Vector2(r + 4, -r - 7), Color("f0e6d0"), 1.6, true)
	elif hat == 2:
		draw_arc(head, r + 1.2, PI * 1.05, PI * 1.95, 10, Color("f3eadb"), 2.4, true)
	# The face: eyes and a mouth that follows the mood (an "o" while gasping).
	var eye_y := head.y - 0.6
	draw_circle(Vector2(head.x - 1.8, eye_y), 0.65, Color("2a1a14"))
	draw_circle(Vector2(head.x + 1.8, eye_y), 0.65, Color("2a1a14"))
	var mouth := head + Vector2(0, 2.4)
	if _glasses > 0.5 and seat == 1:
		draw_circle(mouth, 1.0, Color("5a1a1a"))
	elif mood >= 8:
		draw_arc(mouth + Vector2(0, -1.0), 1.8, 0.2, PI - 0.2, 6, Color("5a1a1a"), 0.9, true)
	elif mood <= 3:
		draw_arc(mouth + Vector2(0, 1.4), 1.8, PI + 0.3, TAU - 0.3, 6, Color("5a1a1a"), 0.9, true)
	else:
		draw_line(mouth + Vector2(-1.4, 0), mouth + Vector2(1.4, 0), Color("5a1a1a"), 0.9, true)
	# Opera glasses, raised for a big hand.
	if _glasses > 0.0 and seat == 1:
		var g := head + Vector2(0, -0.6 + (1.0 - _glasses) * 8.0)
		for a in [-1, 1]:
			draw_circle(g + Vector2(a * 1.9, 0), 1.5, UiTheme.GOLD.darkened(0.2))
			draw_circle(g + Vector2(a * 1.9, 0), 0.8, Color("2a3a5a"))


func _draw_frame(r: Rect2, colour: Color) -> void:
	draw_rect(r, colour, false, 1.0)
