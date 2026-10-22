class_name UiTheme
extends RefCounted
## The look: colours, the pixel font, chunky buttons with a pressed-in bottom edge, framed
## panels with a drop shadow, outlined titles, and the centred 640×360 stage every screen
## lays itself out on.

const BG := Color("1b1026")
const PANEL := Color("2b1a3d")
const PANEL_DARK := Color("170d22")
const PANEL_LIGHT := Color("3d2756")
const OUTLINE := Color("140b1e")
const STAGE := Vector2(640, 360)
const GOLD := Color("f0b84a")
const POINTS := Color("3f8ed8")
const MULT := Color("e0503c")
const TEXT := Color("f3ead8")
const MUTED := Color("a99bbd")
const CARD := Color("f4ead6")
const RED_SUIT := Color("c8323c")
const BLACK_SUIT := Color("2a2433")
const GOOD := Color("6cc46a")

static var font: Font
## Buttons, and titles, scores and card names: the same family, heavier.
static var button_font: Font
static var title_font: Font
## Where sheets (account, profile, leaderboards…) open: above the screens, so a screen
## rebuilding itself doesn't take an open sheet with it. The main scene sets it.
static var sheet_host: Control


static func show_sheet(sheet: Control) -> void:
	if sheet_host != null:
		sheet_host.add_child(sheet)


## Whether a sheet is open over the screens (the screens then ignore keys).
static func sheet_open() -> bool:
	if sheet_host == null:
		return false
	for child in sheet_host.get_children():
		if child.has_signal("closed") and not child.is_queued_for_deletion():
			return true
	return false


static func build() -> Theme:
	# Outfit (SIL OFL), a clean modern sans, drawn at the screen's own resolution (stretch mode
	# canvas_items) so it's sharp on any phone; Latin Extended (ë, ç…) comes from its second
	# file. It's a variable font: one file gives every weight. (Distance-field text was tried:
	# more draw calls and slower on a weak GPU, so no.)
	var base: FontFile = load("res://fonts/outfit-latin.woff2")
	var extended: FontFile = load("res://fonts/outfit-latin-ext.woff2")
	# Letters sit at sub-pixel positions (snapping each to whole pixels left uneven gaps).
	for f: FontFile in [base, extended]:
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		f.hinting = TextServer.HINTING_NONE
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	base.fallbacks = [extended]
	font = _weight(base, 500)
	button_font = _weight(base, 600)
	title_font = _weight(base, 800)
	var t := Theme.new()
	t.default_font = font
	t.default_font_size = 10
	t.set_font("font", "Button", button_font)
	_style_button(t, null, PANEL_LIGHT)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", TEXT)
	t.set_color("font_pressed_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", MUTED.darkened(0.35))
	t.set_stylebox("panel", "PanelContainer", panel_box())
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.6))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)
	var field := box(PANEL_DARK, PANEL_LIGHT, 4)
	field.set_border_width_all(2)
	field.content_margin_left = 8
	field.content_margin_right = 8
	field.content_margin_top = 4
	field.content_margin_bottom = 4
	var focused := field.duplicate() as StyleBoxFlat
	focused.border_color = GOLD
	t.set_stylebox("normal", "LineEdit", field)
	t.set_stylebox("focus", "LineEdit", focused)
	t.set_stylebox("read_only", "LineEdit", field)
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", MUTED.darkened(0.15))
	t.set_color("caret_color", "LineEdit", GOLD)
	t.set_color("selection_color", "LineEdit", Color(GOLD, 0.35))
	t.set_font_size("font_size", "LineEdit", 11)
	var track := box(PANEL_DARK, PANEL_LIGHT, 3)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var filled := box(GOLD.darkened(0.25), GOLD.darkened(0.25), 3)
	filled.content_margin_top = 3
	filled.content_margin_bottom = 3
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", filled)
	t.set_stylebox("grabber_area_highlight", "HSlider", filled)
	return t


## The font at one weight (100 thin to 900 black) of its variable "wght" axis.
static func _weight(base: Font, weight: int) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = base
	v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return v


static func box(bg: Color, border: Color, radius := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 3
	s.content_margin_bottom = 3
	return s


## A framed panel: a 2px border and a hard shadow underneath.
static func panel_box(bg := PANEL, border := PANEL_LIGHT) -> StyleBoxFlat:
	var s := box(bg, border, 6)
	s.set_border_width_all(2)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 1
	s.shadow_offset = Vector2(0, 4)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 5
	s.content_margin_bottom = 5
	return s


## A chunky button face: a darker bottom edge that flattens when pressed, so it reads as a key.
static func button_box(colour: Color, pressed := false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = colour
	s.border_color = colour.darkened(0.5)
	s.border_width_bottom = 1 if pressed else 3
	s.set_corner_radius_all(4)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 4 if pressed else 2
	s.content_margin_bottom = 3 if pressed else 5
	return s


static func _style_button(t: Theme, b: Button, colour: Color) -> void:
	var styles := {
		"normal": button_box(colour), "hover": button_box(colour.lightened(0.15)),
		"pressed": button_box(colour.darkened(0.1), true), "disabled": button_box(colour.darkened(0.55)),
	}
	for state in styles:
		if t != null:
			t.set_stylebox(state, "Button", styles[state])
		else:
			b.add_theme_stylebox_override(state, styles[state])


## A font size after the Text & card size setting.
static func px(size: int) -> int:
	return maxi(7, roundi(size * Settings.text_scale()))


static func label(text: String, size := 10, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", px(size))
	l.add_theme_color_override("font_color", color)
	return l


## A row of buttons where one is chosen (Low / Medium / High…); `pick` gets the index.
static func segmented(names: Array, chosen: int, pick: Callable, size := 10) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	for i in names.size():
		var b := button(str(names[i]), pick.bind(i), size, GOLD.darkened(0.2) if i == chosen else PANEL_DARK)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	return row


## Display type: a thick dark outline and a drop shadow, readable over the swirling backdrop.
static func title(text: String, size := 16, color := GOLD) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", title_font)
	l.add_theme_constant_override("outline_size", maxi(3, size / 6))
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", maxi(2, size / 12))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	return l


## A button, in the theme's panel colour or in its own (Play is red, Continue blue…).
static func button(text: String, on_press: Callable, size := 10, colour := Color.TRANSPARENT) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", px(size))
	if colour.a > 0.0:
		_style_button(null, b, colour)
	b.pressed.connect(on_press)
	return b


## The 640×360 area a screen lays itself out on, centred however wide or tall the screen is.
static func stage(parent: Control) -> Control:
	var s := Control.new()
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.set_anchors_preset(Control.PRESET_CENTER)
	s.offset_left = -STAGE.x / 2.0
	s.offset_right = STAGE.x / 2.0
	s.offset_top = -STAGE.y / 2.0
	s.offset_bottom = STAGE.y / 2.0
	parent.add_child(s)
	return s


## Scores and targets as people read them: 1,234,567, and powers of ten once very large.
static func number(value: float) -> String:
	if absf(value) >= 1e11:
		var exponent := floori(log(absf(value)) / log(10.0))
		return "%.2fe%d" % [value / pow(10.0, exponent), exponent]
	var digits := str(int(value))
	var negative := digits.begins_with("-")
	if negative:
		digits = digits.substr(1)
	var out := ""
	while digits.length() > 3:
		out = "," + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return ("-" if negative else "") + digits + out


static func name_of(def_id: String) -> String:
	return TranslationServer.translate(def_id + ".name")


static func text_of(def_id: String) -> String:
	return TranslationServer.translate(def_id + ".text")
