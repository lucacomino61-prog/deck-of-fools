class_name HowToPlay
extends Control
## The rules in six short steps over a dimmed screen: shown on the first run and from the
## "?" and How to play buttons.

signal closed

const STEPS := [
	["Beat the shows", "Each town has three shows: the Matinee, the Evening show and the Patron. Score at least the target to win a show."],
	["Make a poker hand", "Tap up to 5 cards in your hand, then press Play hand. Pairs, straights, flushes and full houses score more."],
	["Points x Mult", "A hand scores its Points times its Mult. Every card that scores adds its own Points."],
	["Hands and discards", "Each show gives you a few hands and discards. Discard swaps cards you don't want for new ones."],
	["Ducats and Jesters", "Winning a show pays ducats. Spend them in the shop on Jesters: each one bends the rules in your favour."],
	["Skip for a Favor", "Skip the Matinee or the Evening show to take its Favor instead. The Patron can't be skipped."],
]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_box(UiTheme.PANEL, UiTheme.GOLD.darkened(0.2)))
	panel.position = Vector2(100, 8)
	panel.size = Vector2(440, 344)
	UiTheme.stage(self).add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	panel.add_child(col)
	var heading := UiTheme.title("How to play", 20, UiTheme.GOLD)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(heading)
	for i in STEPS.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var number := UiTheme.title(str(i + 1), 16, UiTheme.MULT if i % 2 == 1 else UiTheme.POINTS)
		number.custom_minimum_size = Vector2(16, 0)
		row.add_child(number)
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 0)
		text.add_child(UiTheme.label(STEPS[i][0], 11, UiTheme.GOLD))
		var body := UiTheme.label(STEPS[i][1], 10)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(392, 0)
		text.add_child(body)
		row.add_child(text)
		col.add_child(row)
	var ok := UiTheme.button("Got it", _close, 12, UiTheme.MULT)
	ok.custom_minimum_size = Vector2(120, 0)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(ok)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	Feel.play("select")
	Settings.seen_help = true
	Settings.save()
	closed.emit()
	queue_free()
