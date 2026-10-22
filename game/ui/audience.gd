class_name Audience
extends Control
## The audience along the table during a show: a painted row of silhouettes (art/crowd/strip)
## seen from behind, as from a seat further back, with the cards on the stage beyond them.
## Each figure bobs on its own, livelier the happier the crowd (the tour's mood, or how close
## the show is to its target elsewhere), slumped and dimmed when it's sour. A hand makes them
## react: a cheer (they jump, in a wave), a gasp (a quick hop), a boo (they sink and shake);
## winning the show brings a standing ovation. Still with Reduce motion.

const STRIP := "res://art/crowd/strip.webp"
## Where the painting is cut between figures (its x in pixels), so each can move on its own.
const CUTS := [0, 105, 292, 410, 562, 706, 848, 940, 1040, 1165, 1240, 1344]
## The painting's scale on the 360-tall stage.
const SCALE := 0.36

## 0 (gone sour) to 10 (on their feet).
var mood := 5.0:
	set(v):
		mood = clampf(v, 0.0, 10.0)
		_settle()
var _art: Texture2D
var _time := 0.0
## Per figure: its slice of the painting, where it stands, its bob's phase and rate.
var _figures: Array[Dictionary] = []
## A jump or sink applied to every figure, each a little after its left neighbour (a wave).
var _lift := 0.0
var _shake := 0.0
var _wave_from := 0.0
var _chant := ""
var _chant_wait := 0.0
var _tween: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_art = load(STRIP) if ResourceLoader.exists(STRIP) else null


func _ready() -> void:
	resized.connect(_place)
	visibility_changed.connect(_settle)
	_place()
	_settle()


## Lays figures along the width; a wider table takes more of them, starting further along the
## painting so the row doesn't visibly repeat.
func _place() -> void:
	_figures.clear()
	var x := 0.0
	var count := CUTS.size() - 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var n := 0
	while x < size.x and n < count * 4:
		var i := (n + floori(float(n) / count) * 5) % count
		var w := float(CUTS[i + 1] - CUTS[i])
		_figures.append({"src": Rect2(CUTS[i], 0, w, 290), "x": x, "phase": rng.randf() * TAU, "rate": rng.randf_range(0.8, 1.25)})
		x += w * SCALE
		n += 1
	queue_redraw()


func _settle() -> void:
	set_process(is_inside_tree() and visible and not Settings.reduce_motion and (mood > 0.0 or _lift != 0.0 or _chant != ""))
	queue_redraw()


func react(kind: String) -> void:
	if Settings.reduce_motion or _art == null:
		return
	if _tween != null and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	set_process(true)
	match kind:
		"cheer":
			_wave_from = randf()
			_tween.tween_method(_set_lift, 0.0, 1.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_tween.tween_method(_set_lift, 1.0, 0.0, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		"ovation":
			_wave_from = 0.0
			for i in 3:
				_tween.tween_method(_set_lift, 0.0, 1.4, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				_tween.tween_method(_set_lift, 1.4, 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		"gasp":
			_wave_from = -1.0
			_tween.tween_method(_set_lift, 0.0, 0.45, 0.08)
			_tween.tween_method(_set_lift, 0.45, 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		"boo":
			_wave_from = -1.0
			_tween.set_parallel()
			_tween.tween_method(_set_lift, -0.6, 0.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_tween.tween_method(_set_shake, 1.0, 0.0, 0.6)
	_tween.finished.connect(_settle, CONNECT_ONE_SHOT)


## A word called out over their heads every so often ("Bis!"), or "" for none.
func chant(text: String) -> void:
	if text == _chant:
		return
	_chant = text
	_chant_wait = 0.2
	if text != "":
		set_process(not Settings.reduce_motion)
	else:
		_settle()


func _set_lift(v: float) -> void:
	_lift = v
	queue_redraw()


func _set_shake(v: float) -> void:
	_shake = v
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _chant != "" and is_visible_in_tree():
		_chant_wait -= delta
		if _chant_wait <= 0.0 and not _figures.is_empty():
			_chant_wait = randf_range(0.5, 0.9)
			var f: Dictionary = _figures[randi() % _figures.size()]
			var w: float = (f["src"] as Rect2).size.x * SCALE
			Feel.float_text(_chant, global_position + Vector2(float(f["x"]) + w / 2.0, -6.0), UiTheme.GOLD, 12)


func _draw() -> void:
	if _art == null:
		return
	var energy := mood / 10.0
	# A sour house sits lower and darker; a happy one is lit by the stage.
	var sag := (1.0 - smoothstep(0.0, 0.35, energy)) * 6.0
	var light := lerpf(0.62, 1.0, smoothstep(0.1, 0.7, energy))
	var amp := 0.0 if Settings.reduce_motion else lerpf(0.0, 3.6, energy)
	var count := maxi(1, _figures.size())
	for n in _figures.size():
		var f: Dictionary = _figures[n]
		var src: Rect2 = f["src"]
		var w := src.size.x * SCALE
		var bob := absf(sin(_time * 2.4 * float(f["rate"]) * lerpf(0.7, 1.5, energy) + float(f["phase"]))) * amp
		var lift := _lift
		if _wave_from >= 0.0:
			# The wave reaches figures further from where it started a little later.
			var dist := absf(float(n) / count - _wave_from)
			lift *= clampf(1.0 - dist * 0.6, 0.35, 1.0)
		var dy := sag - bob - lift * 9.0
		var dx := sin(_time * 40.0 + n) * _shake * 2.0
		# A hair wider than its slice, so neighbours bobbing apart never open a seam.
		var rect := Rect2(float(f["x"]) + dx - 0.5, dy, w + 1.0, src.size.y * SCALE)
		draw_texture_rect_region(_art, rect, src, Color(light, light, light, 0.96))
