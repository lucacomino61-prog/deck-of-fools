class_name FlapBoard
extends Control
## Rows of split-flap cells (FlapCell) on the 640x360 stage, each row a fixed number of
## characters. Setting a row's text flips each cell to its letter, column by column so the
## change runs across the row like a wave.

## Row id -> its cells, left to right.
var rows: Dictionary = {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## A row of `cols` cells of `cell` size starting at `at`, `gap` apart.
func add_row(id: String, at: Vector2, cols: int, cell: Vector2, gap: float, text_size: int, colour: Color) -> void:
	var cells: Array[FlapCell] = []
	for i in cols:
		var c := FlapCell.new(cell, text_size, colour)
		c.position = at + Vector2(i * (cell.x + gap), 0)
		add_child(c)
		cells.append(c)
	rows[id] = cells


## The row's text, padded or cut to fit; flips to it (column by column, `stagger` apart, after
## `delay`), or shows it at once when `now`.
func set_text(id: String, text: String, now := false, delay := 0.0, stagger := 0.018) -> void:
	var cells: Array = rows[id]
	var line := fit(text, cells.size())
	for i in cells.size():
		var cell: FlapCell = cells[i]
		var c := line.substr(i, 1)
		if now:
			cell.set_now(c)
		elif cell.target != c:
			cell.flip_to(c, delay + i * stagger)


func text_of(id: String) -> String:
	return "".join((rows[id] as Array).map(func(c: FlapCell) -> String: return c.target))


func settled() -> bool:
	for id in rows:
		for c: FlapCell in rows[id]:
			if not c.settled():
				return false
	return true


## Upper case, cut or padded with spaces to `width`.
static func fit(text: String, width: int) -> String:
	var t := text.to_upper()
	return t.substr(0, width) if t.length() >= width else t + " ".repeat(width - t.length())
