class_name TitleScreen
extends Control
## The poster the game opens on: the key art full-bleed under two scrims, the logo, the
## tagline and Enter. On the web it takes over from the loading page (web/shell.html), which
## shows the same poster and logo at the same stage positions, with its progress bar where
## Enter appears, so the hand-over is seamless. Enter is also the first tap, which lets a
## browser start the music.

signal entered

## Where the logo, tagline and Enter sit on the 640x360 stage (web/shell.html uses the same;
## the logo's label box starts higher than the page's text box for the same letters).
const LOGO_AT := Vector2(34, 80)
const TAGLINE_AT := Vector2(36, 208)
const ENTER_AT := Vector2(36, 246)
const ENTER_SIZE := Vector2(176, 40)

var _poster: Texture2D
var _left := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_poster = load("res://art/poster/key.webp") if ResourceLoader.exists("res://art/poster/key.webp") else null
	var art := TextureRect.new()
	art.texture = _poster
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	add_child(_scrim(Vector2(1, 0), [0.0, 0.34, 0.58], [0.9, 0.55, 0.0]))
	add_child(_scrim(Vector2(0, -1), [0.0, 0.3], [0.75, 0.0]))

	var stage := UiTheme.stage(self)
	var logo := UiTheme.title("DECK\nOF FOOLS", 58, UiTheme.GOLD)
	logo.add_theme_constant_override("line_spacing", -19)
	logo.add_theme_constant_override("outline_size", 4)
	logo.position = LOGO_AT
	stage.add_child(logo)
	var tagline := UiTheme.title("A troupe of Jesters against the house", 14, UiTheme.TEXT)
	tagline.add_theme_constant_override("outline_size", 3)
	tagline.position = TAGLINE_AT
	stage.add_child(tagline)
	var enter := UiTheme.button("Enter", _enter, 18, UiTheme.MULT)
	enter.add_theme_font_override("font", UiTheme.title_font)
	enter.position = ENTER_AT
	enter.size = ENTER_SIZE
	enter.pivot_offset = ENTER_SIZE / 2.0
	stage.add_child(enter)

	if Settings.reduce_motion:
		return
	# The web loading page already showed the poster, logo and tagline in place: only Enter
	# arrives (where the progress bar was). Elsewhere the logo and tagline rise in first.
	var t := create_tween()
	if not OS.has_feature("web"):
		for node: Control in [logo, tagline]:
			node.modulate.a = 0.0
			node.position.y += 10.0
		t.set_parallel()
		t.tween_property(logo, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		t.tween_property(logo, "position:y", LOGO_AT.y, 0.45).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		t.tween_property(tagline, "modulate:a", 1.0, 0.45).set_delay(0.08).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		t.tween_property(tagline, "position:y", TAGLINE_AT.y, 0.45).set_delay(0.08).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		t.chain()
	enter.modulate.a = 0.0
	enter.scale = Vector2(0.96, 0.96)
	t.set_parallel()
	t.tween_property(enter, "modulate:a", 1.0, 0.3).set_delay(0.15)
	t.tween_property(enter, "scale", Vector2.ONE, 0.3).set_delay(0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# A slow push into the painting while the poster waits (it's a screen seen once a visit).
	art.pivot_offset = get_viewport_rect().size / 2.0
	var drift := art.create_tween().set_loops()
	drift.tween_property(art, "scale", Vector2(1.045, 1.045), 14.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	drift.tween_property(art, "scale", Vector2.ONE, 14.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## A full-screen dark gradient: `direction` (1, 0) runs left to right, (0, -1) bottom up;
## `stops` are offsets with the darkness at each.
func _scrim(direction: Vector2, stops: Array, alphas: Array) -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(stops)
	var colours := PackedColorArray()
	for a in alphas:
		colours.append(Color(0.078, 0.043, 0.118, a))
	g.colors = colours
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 256
	tex.height = 256
	if direction.y < 0.0:
		tex.fill_from = Vector2(0, 1)
		tex.fill_to = Vector2(0, 0)
	else:
		tex.fill_from = Vector2(0, 0)
		tex.fill_to = Vector2(1, 0)
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		_enter()


func _enter() -> void:
	if _left:
		return
	_left = true
	Feel.play("play")
	Feel.buzz(12)
	if Settings.reduce_motion:
		entered.emit()
		return
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	t.tween_callback(func() -> void: entered.emit())
