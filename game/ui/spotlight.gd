class_name Spotlight
extends Control
## The first-run guide's spotlight: the screen dims except for the thing the tip is about (the
## hand, the Play button, the goal bar…), which a gold ring circles, breathing. It follows its
## controls as they move or lay out, and lets every tap through.

## The controls lit; the hole is around all of them.
var track: Array[Control] = []
## The tip's words, kept clear of the hole (at the top of the screen when the hole is in the
## lower half, just below it in the upper half); a sibling on the same parent.
var note: Control
var _hole := Rect2()
var _time := 0.0


func _init(controls: Array[Control]) -> void:
	track = controls
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	var lit := Rect2()
	var first := true
	for c in track:
		if not is_instance_valid(c) or not c.is_visible_in_tree() or c.is_queued_for_deletion():
			continue
		var r := c.get_global_rect()
		lit = r if first else lit.merge(r)
		first = false
	_hole = Rect2() if first else (get_global_transform().affine_inverse() * lit).grow(5.0)
	queue_redraw()
	if note == null or not is_instance_valid(note):
		return
	var ns := note.size
	if _hole.size == Vector2.ZERO:
		note.position = Vector2((size.x - ns.x) / 2.0, 4.0)
		return
	var x := clampf(_hole.get_center().x - ns.x / 2.0, 4.0, size.x - ns.x - 4.0)
	# Lit low on the screen (the hand, the buttons): the tip waits at the top, over the
	# Jesters, so it never sits on cards the player has to tap. Lit high: just below it.
	var y := 4.0 if _hole.get_center().y > size.y * 0.5 else _hole.end.y + 10.0
	note.position = Vector2(x, clampf(y, 4.0, size.y - ns.y - 4.0))


## The lit area on this control (empty until laid out).
func hole() -> Rect2:
	return _hole


func _draw() -> void:
	if _hole.size == Vector2.ZERO:
		return
	var dark := Color(0.02, 0.01, 0.04, 0.55)
	var far := 2000.0
	var h := _hole
	draw_rect(Rect2(-far, -far, far * 2.0 + size.x, h.position.y + far), dark)
	draw_rect(Rect2(-far, h.end.y, far * 2.0 + size.x, far + size.y), dark)
	draw_rect(Rect2(-far, h.position.y, h.position.x + far, h.size.y), dark)
	draw_rect(Rect2(h.end.x, h.position.y, far + size.x, h.size.y), dark)
	var breathe := 0.0 if Settings.reduce_motion else 0.5 + 0.5 * sin(_time * 4.0)
	var ring := StyleBoxFlat.new()
	ring.draw_center = false
	ring.border_color = Color(UiTheme.GOLD, 0.65 + 0.35 * breathe)
	ring.set_border_width_all(2)
	ring.set_corner_radius_all(6)
	draw_style_box(ring, h.grow(1.0 + 2.0 * breathe))
