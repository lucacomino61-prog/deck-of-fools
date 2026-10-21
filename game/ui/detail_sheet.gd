class_name DetailSheet
extends Sheet
## One card, big, with everything about it: shown when a card is held down (or right-clicked).

var shown: CardView
var lines: Array = []


## `card_view` is a fresh CardView set up like the one held (it's shown at a bigger size);
## `about` is [subtitle, text…].
func _init(card_view: CardView, heading_text: String, about: Array) -> void:
	shown = card_view
	title_text = heading_text
	lines = about
	panel_size = Vector2(420, 250)


func _build() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	body.add_child(row)
	shown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if shown.get_parent() != null:
		shown.get_parent().remove_child(shown)
	row.add_child(shown)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	for i in lines.size():
		var l := UiTheme.label(str(lines[i]), 10 if i > 0 else 9, UiTheme.TEXT if i > 0 else UiTheme.GOLD)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(250, 0)
		col.add_child(l)
