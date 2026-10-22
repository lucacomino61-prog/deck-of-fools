class_name SpeechBubble
extends Control
## A Patron's line (batch 13) in a speech bubble: the speaker's name, the line, a tail
## pointing down. It stays about 2.5 seconds (longer for a long line), then fades; a tap
## sends it away at once. Group 3 adds the voices.

const SECONDS := 2.5

## Screenshots (tests/preview.gd) keep bubbles up until they're tapped.
static var hold := false

var speaker := ""
var line := ""
var _box: PanelContainer


func _init(who: String, words: String) -> void:
	speaker = who
	line = words
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 4


## Centres the bubble's top edge on `at`, at most `width` wide, and starts its timer.
func place(at: Vector2, width: float) -> void:
	_box = PanelContainer.new()
	_box.add_theme_stylebox_override("panel", UiTheme.box(Color("fff2d6"), Color("6a1426"), 8))
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	_box.add_child(col)
	var who := UiTheme.label(speaker, 8, Color("8a2a3a"))
	who.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	col.add_child(who)
	# Dark ink on the cream bubble: the title font without the titles' outline and shadow.
	var words := UiTheme.label("“%s”" % line, 12, Color("3a0a14"))
	words.add_theme_font_override("font", UiTheme.title_font)
	words.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var font := UiTheme.title_font
	var natural := font.get_string_size(words.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 4.0
	words.custom_minimum_size = Vector2(minf(natural, width - 20.0), 0)
	col.add_child(words)
	_box.reset_size()
	size = _box.size + Vector2(0, 6)
	position = at - Vector2(size.x / 2.0, 0)
	queue_redraw()
	if Settings.reduce_motion:
		modulate.a = 1.0
	else:
		modulate.a = 0.0
		scale = Vector2(0.92, 0.92)
		pivot_offset = Vector2(size.x / 2.0, size.y)
		var t := create_tween().set_parallel()
		t.tween_property(self, "modulate:a", 1.0, 0.15)
		t.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Real seconds, whatever the game speed (the scoring speed-up changes Engine.time_scale).
	if not hold:
		get_tree().create_timer(SECONDS + line.length() * 0.02, true, false, true).timeout.connect(_fade)


func _draw() -> void:
	if _box == null:
		return
	var x := _box.size.x * 0.3
	var y := _box.size.y - 1.0
	draw_colored_polygon(PackedVector2Array([Vector2(x - 5, y), Vector2(x + 5, y), Vector2(x - 2, y + 7)]), Color("fff2d6"))
	draw_polyline(PackedVector2Array([Vector2(x - 5, y + 0.5), Vector2(x - 2, y + 7), Vector2(x + 5, y + 0.5)]), Color("6a1426"), 1.0, true)


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		accept_event()
		_fade()


func _fade() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if Settings.reduce_motion:
		queue_free()
		return
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(queue_free)
