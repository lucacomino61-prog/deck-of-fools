class_name Sheet
extends Control
## A panel over a dimmed screen (account, profile, leaderboards, a save conflict): a title,
## a Close button and a column the sheet fills in _build(). rebuild() redraws it after a
## change; close() removes it.

signal closed

var title_text := ""
var panel_size := Vector2(420, 320)
## Whether Close is offered (a conflict must be answered).
var closable := true
var body: VBoxContainer
var heading: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_box(UiTheme.PANEL, UiTheme.GOLD.darkened(0.25)))
	panel.position = (UiTheme.STAGE - panel_size) / 2.0
	panel.size = panel_size
	UiTheme.stage(self).add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	var top := HBoxContainer.new()
	heading = UiTheme.title(title_text, 18, UiTheme.GOLD)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(heading)
	if closable:
		top.add_child(UiTheme.button("Close", close))
	col.add_child(top)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 5)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	_build()
	heading.text = title_text


## Fills `body` (and may set title_text).
func _build() -> void:
	pass


## Esc closes the sheet (the topmost one gets it first).
func _unhandled_input(event: InputEvent) -> void:
	if closable and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()


func rebuild() -> void:
	for child in body.get_children():
		child.queue_free()
	_build()
	heading.text = title_text


func close() -> void:
	Feel.play("click")
	closed.emit()
	queue_free()


## Wrapped text across the sheet.
func words(text: String, font_size := 10, colour := UiTheme.TEXT) -> Label:
	var l := UiTheme.label(text, font_size, colour)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(panel_size.x - 24, 0)
	return l


func field(placeholder: String, secret := false) -> LineEdit:
	var f := LineEdit.new()
	f.placeholder_text = placeholder
	f.secret = secret
	f.custom_minimum_size = Vector2(0, 24)
	return f


## A row with a muted caption on the left and a value on the right.
func pair(caption: String, value: String, colour := UiTheme.TEXT) -> HBoxContainer:
	var row := HBoxContainer.new()
	var key := UiTheme.label(caption, 10, UiTheme.MUTED)
	key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(key)
	row.add_child(UiTheme.label(value, 10, colour))
	return row


## "3 minutes ago", for a unix time.
static func ago(unix: float) -> String:
	var seconds := int(Time.get_unix_time_from_system() - unix)
	if seconds < 90:
		return "just now"
	if seconds < 5400:
		return "%d minutes ago" % (seconds / 60)
	if seconds < 129600:
		return "%d hours ago" % (seconds / 3600)
	return "%d days ago" % (seconds / 86400)
