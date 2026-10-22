class_name FlapWipe
extends CanvasLayer
## The change between screens (the menu, a run, back to the menu): the whole screen becomes a
## station board whose flaps fall shut in a diagonal wave, clattering; behind them the next
## screen is put up, and the flaps fold away the other way. Flaps from the wagon (the
## "curtain" cosmetics) colour them. Reduce motion swaps screens at once.

const COLS := 10
const ROWS := 6
## Seconds for one flap, and between neighbouring diagonals.
const FLAP := 0.16
const STAGGER := 0.02
const HOLD := 0.06

## 0 is open, 1 is shut; each flap runs its own part of it, by its diagonal.
var amount := 0.0
var _closing := true
var _root: Control
var _tween: Tween
var _ticked := -1


func _init() -> void:
	layer = 8


func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.draw.connect(_draw_flaps)
	add_child(_root)
	visible = false


## Shuts the flaps, runs `swap` (the next screen) behind them, then folds them away.
func sweep(swap: Callable) -> void:
	if Settings.reduce_motion or not is_inside_tree():
		swap.call()
		return
	if _tween != null and _tween.is_running():
		_tween.kill()
	visible = true
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	var span := FLAP + (COLS + ROWS - 2) * STAGGER
	_tween = create_tween()
	_tween.tween_callback(func() -> void: _closing = true)
	_tween.tween_method(_set_amount, 0.0, 1.0, span)
	_tween.tween_callback(swap)
	# The next screen takes taps as soon as it's up, while the flaps fold away.
	_tween.tween_callback(func() -> void: _root.mouse_filter = Control.MOUSE_FILTER_IGNORE)
	_tween.tween_interval(HOLD)
	_tween.tween_callback(func() -> void:
		_closing = false
		_ticked = -1)
	_tween.tween_method(_set_amount, 1.0, 0.0, span)
	_tween.tween_callback(func() -> void:
		visible = false
		_root.mouse_filter = Control.MOUSE_FILTER_IGNORE)


func _set_amount(value: float) -> void:
	amount = value
	# A tick each time the wave reaches a new diagonal.
	var span := FLAP + (COLS + ROWS - 2) * STAGGER
	var elapsed := (value if _closing else 1.0 - value) * span
	var diagonal := int(elapsed / STAGGER)
	if diagonal != _ticked and diagonal < COLS + ROWS - 1:
		_ticked = diagonal
		Feel.play("tick", randf_range(1.5, 2.1))
	_root.queue_redraw()


## How shut the flap on diagonal `d` is (0 open, 1 shut).
func _flap(d: int) -> float:
	var span := FLAP + (COLS + ROWS - 2) * STAGGER
	if _closing:
		return clampf((amount * span - d * STAGGER) / FLAP, 0.0, 1.0)
	# Opening runs the same way across the screen: the first diagonal to shut opens first.
	return 1.0 - clampf(((1.0 - amount) * span - d * STAGGER) / FLAP, 0.0, 1.0)


func _draw_flaps() -> void:
	var view := _root.size
	var w := view.x / COLS
	var h := view.y / ROWS
	var top := FlapCell.TOP
	var bottom := FlapCell.BOTTOM
	if str(Game.profile.worn.get("curtain", "")) != "":
		var dye := Game.profile.worn_colour("curtain", top)
		top = top.lerp(dye.darkened(0.55), 0.6)
		bottom = bottom.lerp(dye.darkened(0.7), 0.6)
	for r in ROWS:
		for c in COLS:
			var k := _flap(c + r)
			if k <= 0.0:
				continue
			var cell := Rect2(c * w, r * h, w + 1.0, h + 1.0)
			# Shutting, a flap falls from the cell's top edge; opening, it folds back up to it.
			var shown := Rect2(cell.position, Vector2(cell.size.x, cell.size.y * k))
			var light := lerpf(0.6, 1.0, k)
			_root.draw_rect(Rect2(shown.position, Vector2(shown.size.x, minf(shown.size.y, h / 2.0))), Color(top.r * light, top.g * light, top.b * light))
			if shown.size.y > h / 2.0:
				_root.draw_rect(Rect2(cell.position + Vector2(0, h / 2.0), Vector2(cell.size.x, shown.size.y - h / 2.0)), Color(bottom.r * light, bottom.g * light, bottom.b * light))
				_root.draw_rect(Rect2(cell.position + Vector2(0, h / 2.0 - 0.5), Vector2(cell.size.x, 1.5)), FlapCell.SPLIT)
			_root.draw_rect(Rect2(cell.position, Vector2(1.0, shown.size.y)), FlapCell.SPLIT)
			_root.draw_rect(Rect2(cell.position, Vector2(cell.size.x, 1.0)), FlapCell.SPLIT)
