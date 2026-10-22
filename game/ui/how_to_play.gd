class_name HowToPlay
extends Control
## The rules in six short steps over a dimmed screen, and a second page for the tour (batch
## 12): shown on the first run and from the "?" and How to play buttons.

signal closed

const TOUR_STEPS := [
	["The Map of Italy", "After each Patron, choose the next city. Every city changes its three shows (its twist) and what its shop sells. The tour ends in Venezia for Carnevale."],
	["Scenarios", "Before a show, Perform its Scenario: your next three hands must hit its beats in order (a Pair, then a Flush...). Hits pay ducats and big Mult; a miss is a Fiasco and that hand scores half. Or Improvise."],
	["The crowd", "Good hands lift the crowd's mood, weak ones lower it. A full house of cheers gives your next hand x1.5 Mult; an empty one walks out and costs 3 ducats."],
	["Encore!", "Win a show with a happy crowd and they shout Bis! One more hand worth half the target doubles your cash-out; miss it and you lose the show's reward. Or take a bow."],
	["Lazzi", "Some Jesters are classic duos. Own both, and in the Market a Merge button makes them one card: one slot, both effects, about 1.5x stronger."],
]

## The page shown: 0 the basics, 1 the tour.
var page := 0

const STEPS := [
	["Beat the shows", "Each town has three shows: the Matinee, the Evening show and the Patron. Score at least the target to win a show."],
	["Make a poker hand", "Tap up to 5 cards, then press Play hand (or flick a card up). Pairs, straights, flushes and full houses score more. Hold any card to read it."],
	["Points x Mult", "A hand scores its Points times its Mult. Every card that scores adds its own Points."],
	["Hands and discards", "Each show gives you a few hands and discards. Discard swaps cards you don't want for new ones."],
	["Ducats and Jesters", "Winning a show pays ducats. In the shop, tap a Jester and Buy, or drag it up to your row: each one bends the rules in your favour. Drag one down off the row to sell it."],
	["Skip for a Favor", "Skip the Matinee or the Evening show to take its Favor instead. The Patron can't be skipped."],
]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_build()


func _build() -> void:
	for child in get_children():
		if not child is ColorRect:
			remove_child(child)
			child.queue_free()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_box(UiTheme.PANEL, UiTheme.GOLD.darkened(0.2)))
	panel.position = Vector2(100, 8)
	panel.size = Vector2(440, 344)
	UiTheme.stage(self).add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	panel.add_child(col)
	var heading := UiTheme.title("How to play" if page == 0 else "On tour", 20, UiTheme.GOLD)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(heading)
	var steps: Array = STEPS if page == 0 else TOUR_STEPS
	for i in steps.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var number := UiTheme.title(str(i + 1), 16, UiTheme.MULT if i % 2 == 1 else UiTheme.POINTS)
		number.custom_minimum_size = Vector2(16, 0)
		row.add_child(number)
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 0)
		text.add_child(UiTheme.label(steps[i][0], 11, UiTheme.GOLD))
		var body := UiTheme.label(steps[i][1], 10 if page == 0 else 9)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(392, 0)
		text.add_child(body)
		row.add_child(text)
		col.add_child(row)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(buttons)
	var turn := UiTheme.button("On tour >" if page == 0 else "< The basics", func() -> void:
		Feel.play("click")
		page = 1 - page
		_build(), 12, UiTheme.PANEL_LIGHT)
	turn.custom_minimum_size = Vector2(120, 0)
	buttons.add_child(turn)
	var ok := UiTheme.button("Got it", _close, 12, UiTheme.MULT)
	ok.custom_minimum_size = Vector2(120, 0)
	buttons.add_child(ok)


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
