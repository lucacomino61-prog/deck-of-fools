class_name GoalBar
extends Control
## The show's goal across the top of the table: a bar that fills with the show score towards
## the target ("120 / 300"), a paler stretch for what the selected cards would add (green when
## it's enough to win), the player's own best in this show as a ghost mark, and the hands and
## discards left beside it. A played hand's total crashes into it and it fills up, flaring
## gold when it passes the target.

const CHIP_W := 58.0

var score := 0.0
var target := 1.0
var hands := 0
var discards := 0
## What the selected cards would score, or < 0 for nothing selected.
var preview := -1.0
## Shown instead of "Hands" during an Encore: one hand, its own target.
var encore := false
## The player's best score in this show before (0 for none): a ghost mark on the bar.
var best := 0.0
var _shown := 0.0
var _flare := 0.0
var _pulse := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_values(new_score: float, new_target: float, hands_left: int, discards_left: int, preview_total := -1.0) -> void:
	score = new_score
	target = maxf(1.0, new_target)
	hands = hands_left
	discards = discards_left
	preview = preview_total
	_shown = score
	set_process(preview >= 0.0 and preview >= target - score and not Settings.reduce_motion)
	queue_redraw()


## The bar's fill, in stage coordinates of this control: where a total should fly to.
func fill_point() -> Vector2:
	var bar := _bar_rect()
	return bar.position + Vector2(bar.size.x * clampf(_shown / target, 0.0, 1.0), bar.size.y / 2.0)


## Fills from the score shown to `to`, ticking; flares gold if it passes the target.
func fill_to(to: float) -> void:
	var from := _shown
	score = to
	preview = -1.0
	set_process(false)
	if Settings.reduce_motion or to <= from:
		_shown = to
		queue_redraw()
		return
	var crossed := from < target and to >= target
	var t := create_tween()
	var ticks := [0]
	t.tween_method(func(v: float) -> void:
		_shown = v
		queue_redraw()
		var step := int((v - from) / (to - from) * 8.0)
		if step > ticks[0]:
			ticks[0] = step
			Feel.play("tick", 1.0 + step * 0.07), from, to, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await t.finished
	if crossed:
		var f := create_tween()
		f.tween_method(_set_flare, 1.0, 0.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _set_flare(v: float) -> void:
	_flare = v
	queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func _bar_rect() -> Rect2:
	return Rect2(0, 2, size.x - 2.0 * CHIP_W - 10.0, size.y - 4.0)


func _draw() -> void:
	var bar := _bar_rect()
	var r := 5
	var back := StyleBoxFlat.new()
	back.bg_color = Color(UiTheme.PANEL_DARK, 0.94)
	back.border_color = UiTheme.GOLD.darkened(0.35).lerp(UiTheme.GOLD, _flare)
	back.set_border_width_all(1)
	back.set_corner_radius_all(r)
	draw_style_box(back, bar)
	var inner := bar.grow(-2.0)
	var share := clampf(_shown / target, 0.0, 1.0)
	# What the selected cards would add, paler, ahead of the fill.
	if preview >= 0.0:
		var ahead := clampf((_shown + preview) / target, 0.0, 1.0)
		var wins := _shown + preview >= target
		var c := UiTheme.GOOD if wins else UiTheme.TEXT
		c.a = 0.28 + (0.18 * (0.5 + 0.5 * sin(_pulse * 6.0)) if wins else 0.0)
		_round_fill(inner, share, ahead, c, r - 1)
	if share > 0.0:
		var gold := UiTheme.GOLD.lerp(Color.WHITE, _flare * 0.6)
		_round_fill(inner, 0.0, share, gold, r - 1)
	# The ghost: where the player's best in this show got to, and how much it was.
	if best > 0.0:
		var bx := inner.position.x + inner.size.x * clampf(best / target, 0.0, 1.0)
		draw_rect(Rect2(bx - 1.0, bar.position.y - 2.0, 2.0, bar.size.y + 4.0), Color(UiTheme.TEXT, 0.9))
		var note := "best " + UiTheme.number(best)
		var ns := UiTheme.px(8)
		var nw := UiTheme.font.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, ns).x
		var base := bar.position.y + (bar.size.y + UiTheme.font.get_ascent(ns) - UiTheme.font.get_descent(ns)) / 2.0
		draw_string(UiTheme.font, Vector2(bar.end.x - nw - 8.0, base), note, HORIZONTAL_ALIGNMENT_LEFT, -1, ns, Color(UiTheme.TEXT, 0.8))
	# The words: the score of the target.
	var font := UiTheme.title_font
	var fs := UiTheme.px(11)
	var text := "%s / %s" % [UiTheme.number(floorf(_shown)), UiTheme.number(target)]
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var at := Vector2(bar.position.x + (bar.size.x - tw) / 2.0, bar.position.y + (bar.size.y + font.get_ascent(fs) - font.get_descent(fs)) / 2.0)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, UiTheme.OUTLINE)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.TEXT)
	# The hands and discards left, as two chips.
	var x := bar.end.x + 6.0
	_chip(Rect2(x, bar.position.y, CHIP_W, bar.size.y), str(hands), "hand" if hands == 1 else "hands", UiTheme.POINTS, hands <= 1)
	if not encore:
		_chip(Rect2(x + CHIP_W + 4.0, bar.position.y, CHIP_W, bar.size.y), str(discards), "discard" if discards == 1 else "discards", UiTheme.MULT, false)


func _round_fill(inner: Rect2, from: float, to: float, colour: Color, radius: int) -> void:
	if to <= from:
		return
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.set_corner_radius_all(radius)
	draw_style_box(box, Rect2(inner.position.x + inner.size.x * from, inner.position.y, inner.size.x * (to - from), inner.size.y))


func _chip(rect: Rect2, number: String, word: String, colour: Color, warn: bool) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(colour.darkened(0.55), 0.94)
	box.border_color = colour.lightened(0.2) if warn else colour.darkened(0.15)
	box.set_border_width_all(2 if warn else 1)
	box.set_corner_radius_all(5)
	draw_style_box(box, rect)
	var font := UiTheme.title_font
	var big := UiTheme.px(11)
	var small := UiTheme.px(7)
	var nw := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, big).x
	var ww := UiTheme.font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, small).x
	var x := rect.position.x + (rect.size.x - nw - 3.0 - ww) / 2.0
	var base := rect.position.y + (rect.size.y + font.get_ascent(big) - font.get_descent(big)) / 2.0
	draw_string(font, Vector2(x, base), number, HORIZONTAL_ALIGNMENT_LEFT, -1, big, colour.lightened(0.35))
	draw_string(UiTheme.font, Vector2(x + nw + 3.0, base - 1.0), word, HORIZONTAL_ALIGNMENT_LEFT, -1, small, UiTheme.TEXT)
