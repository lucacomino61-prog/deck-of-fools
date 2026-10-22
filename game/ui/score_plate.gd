class_name ScorePlate
extends PanelContainer
## Under the played cards while a hand scores: the hand's name over its Points x Mult, each
## step pumping the box it changes (harder for a xMult). Once Points x Mult reaches what the
## show still needs, the plate catches fire: a gold glow that breathes until the score lands.
## At the end the two boxes close in on each other and the total slams down in their place.

var need := 0.0
var _pbox: PanelContainer
var _mbox: PanelContainer
var _points: Label
var _mult: Label
var _times: Label
var _style: StyleBoxFlat
var _hot := false


func _init(hand_name: String, needed: float) -> void:
	need = needed
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 2
	_style = UiTheme.box(Color(UiTheme.PANEL_DARK, 0.95), UiTheme.PANEL_LIGHT, 6)
	_style.content_margin_left = 8
	_style.content_margin_right = 8
	_style.content_margin_top = 2
	_style.content_margin_bottom = 4
	add_theme_stylebox_override("panel", _style)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 1)
	add_child(col)
	var title := UiTheme.title(hand_name, 11, UiTheme.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	col.add_child(row)
	_pbox = _box(UiTheme.POINTS)
	_points = _pbox.get_child(0) as Label
	row.add_child(_pbox)
	_times = UiTheme.title("x", 16, UiTheme.TEXT)
	row.add_child(_times)
	_mbox = _box(UiTheme.MULT)
	_mult = _mbox.get_child(0) as Label
	row.add_child(_mbox)


func _box(colour: Color) -> PanelContainer:
	var box := PanelContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override("panel", UiTheme.button_box(colour))
	box.custom_minimum_size = Vector2(72, 0)
	var l := UiTheme.title("0", 20, UiTheme.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)
	return box


## Puts the plate with its top centre at `top_centre` (on its parent) and brings it in.
func place(top_centre: Vector2) -> void:
	size = get_combined_minimum_size()
	position = top_centre - Vector2(size.x / 2.0, 0.0)
	pivot_offset = size / 2.0
	if Settings.reduce_motion:
		return
	modulate.a = 0.0
	scale = Vector2(0.94, 0.94)
	var t := create_tween().set_parallel()
	t.tween_property(self, "modulate:a", 1.0, 0.16)
	t.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


## One scoring step: the Points and Mult after it.
func show_step(e: Dictionary) -> void:
	var p := float(e["points"])
	var m := float(e["mult"])
	var p_text := UiTheme.number(p)
	var m_text := UiTheme.number(m) if m >= 100.0 or is_equal_approx(m, roundf(m)) else ("%.1f" % m)
	if _points.text != p_text:
		_points.text = p_text
		_bump(_pbox, false)
	if _mult.text != m_text:
		_mult.text = m_text
		_bump(_mbox, str(e["t"]) == "xmult")
	if not _hot and need > 0.0 and p * m >= need:
		_catch_fire()


func _bump(box: Control, big: bool) -> void:
	box.pivot_offset = box.size / 2.0
	box.modulate = Color(1.7, 1.7, 1.7)
	if Settings.reduce_motion:
		box.modulate = Color.WHITE
		return
	var t := box.create_tween()
	t.tween_property(box, "scale", Vector2.ONE * (1.32 if big else 1.16), 0.05)
	t.tween_property(box, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(box, "modulate", Color.WHITE, 0.2)


## Enough to win: the plate glows gold and breathes.
func _catch_fire() -> void:
	_hot = true
	_style.border_color = UiTheme.GOLD
	_style.set_border_width_all(2)
	_style.shadow_color = Color(UiTheme.GOLD, 0.45)
	_style.shadow_size = 6
	Feel.play("tick", 1.9)
	Feel.kick(0.5)
	Feel.burst(get_global_rect().get_center(), UiTheme.GOLD, 12)
	if Settings.reduce_motion:
		return
	var t := create_tween().set_loops()
	t.tween_method(func(v: float) -> void: _style.shadow_size = int(v), 6.0, 12.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(func(v: float) -> void: _style.shadow_size = int(v), 12.0, 6.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Points and Mult slide into each other and vanish.
func collide() -> void:
	if Settings.reduce_motion:
		return
	var meet := _times.position.x + _times.size.x / 2.0
	var t := create_tween().set_parallel()
	for box: Control in [_pbox, _mbox]:
		box.pivot_offset = box.size / 2.0
		var shift := meet - (box.position.x + box.size.x / 2.0)
		t.tween_property(box, "position:x", box.position.x + shift, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		t.tween_property(box, "scale", Vector2(0.7, 0.7), 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(_times, "modulate:a", 0.0, 0.1)
	t.tween_property(self, "modulate:a", 0.0, 0.08).set_delay(0.12)
	await t.finished
