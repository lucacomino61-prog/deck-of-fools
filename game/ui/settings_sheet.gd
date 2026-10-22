class_name SettingsSheet
extends Sheet
## Every setting in one place, in two columns:
##   Sound: music and effects volume, each with a mute.
##   Display: graphics quality, frame rate, CRT effect, Reduce motion, suit colours, which
##   side Play and Discard sit on.
##   Play: game speed, screen shake, text and card size, vibration, the card back, the
##   first-run tips.
##   Account: who's signed in, the cloud save, and the way to log in, out, or to the profile.
## Every change is saved and applied at once.


func _init() -> void:
	title_text = "Settings"
	panel_size = Vector2(612, 346)
	wide = true


func _ready() -> void:
	super._ready()
	Online.account_changed.connect(func() -> void:
		if is_inside_tree():
			rebuild())


func _build() -> void:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	body.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2((panel_size.x - 40.0) / 2.0, 0)
	left.add_theme_constant_override("separation", 4)
	columns.add_child(left)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 4)
	columns.add_child(right)

	left.add_child(_heading("Sound"))
	left.add_child(_volume("Music", Settings.music_volume, Settings.music, func(v: float) -> void: Settings.music_volume = v, func() -> void: Settings.music = not Settings.music))
	left.add_child(_volume("Effects", Settings.sfx_volume, Settings.sound, func(v: float) -> void: Settings.sfx_volume = v, func() -> void: Settings.sound = not Settings.sound))
	left.add_child(_heading("Display"))
	left.add_child(_choice("Graphics", Settings.QUALITY_NAMES, Settings.quality, func(i: int) -> void:
		Settings.quality = i
		CardArt.clear()))
	left.add_child(_choice("Frame rate", Settings.FPS_CHOICES.map(func(f: int) -> String: return "%d fps" % f), Settings.FPS_CHOICES.find(Settings.fps), func(i: int) -> void: Settings.fps = Settings.FPS_CHOICES[i]))
	left.add_child(_choice("CRT effect", Settings.CRT_NAMES, Settings.crt, func(i: int) -> void: Settings.crt = i))
	left.add_child(_choice("Reduce motion", ["Off", "On"], 1 if Settings.reduce_motion else 0, func(i: int) -> void: Settings.reduce_motion = i == 1))
	left.add_child(_choice("Suit colours", ["Two", "Four"], 1 if Settings.high_contrast else 0, func(i: int) -> void:
		Settings.high_contrast = i == 1
		CardArt.clear()))
	left.add_child(_choice("Buttons", ["Play first", "Discard first"], 1 if Settings.left_handed else 0, func(i: int) -> void: Settings.left_handed = i == 1))

	right.add_child(_heading("Play"))
	right.add_child(_choice("Game speed", Settings.SPEEDS.map(func(s: float) -> String: return Settings.speed_name(s)), Settings.SPEEDS.find(Settings.speed), func(i: int) -> void: Settings.speed = Settings.SPEEDS[i]))
	right.add_child(_choice("Screen shake", Settings.SHAKE_NAMES, Settings.shake, func(i: int) -> void:
		Settings.shake = i
		Feel.shake(4.0)))
	right.add_child(_choice("Text & cards", Settings.SIZE_NAMES, Settings.size, func(i: int) -> void:
		Settings.size = i
		CardArt.clear()))
	right.add_child(_choice("Vibration", Settings.VIBRATION_NAMES, Settings.vibration_level, func(i: int) -> void:
		Settings.vibration_level = i
		Feel.buzz(30)))
	var back_row := HBoxContainer.new()
	back_row.add_theme_constant_override("separation", 6)
	var preview := CardView.new(Vector2(26, 36))
	preview.face_down = true
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_row.add_child(preview)
	var back_col := VBoxContainer.new()
	back_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var worn := CardView.worn_back()
	back_col.add_child(UiTheme.label("Card back: " + (UiTheme.name_of(worn) if worn != "" else Settings.CARD_BACKS[Settings.card_back]), 10, UiTheme.MUTED))
	back_col.add_child(UiTheme.button("Next design", func() -> void: _change(_next_back)))
	back_row.add_child(back_col)
	right.add_child(back_row)
	if Settings.tutorial_step < 0:
		right.add_child(UiTheme.button("Show the first-run tips again", func() -> void: _change(func() -> void: Settings.tutorial_step = 0)))

	right.add_child(_heading("Account"))
	if not Online.signed_in():
		right.add_child(UiTheme.label("Offline: progress is kept on this device.", 10, UiTheme.MUTED))
	else:
		var who := str(Online.user.get("name", ""))
		var how := "guest" if Online.is_guest() else str(Online.user.get("email", "")) if str(Online.user.get("email", "")) != "" else "Apple / Google"
		right.add_child(UiTheme.label("%s (%s)" % [who, how], 10, UiTheme.TEXT))
		right.add_child(UiTheme.label("Cloud save: " + ("up to date" if not Online.dirty else "saving soon"), 10, UiTheme.MUTED))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		if Online.is_guest():
			row.add_child(UiTheme.button("Save progress", func() -> void: _open(AccountSheet.new("signup")), 10, UiTheme.MULT))
			row.add_child(UiTheme.button("Log in", func() -> void: _open(AccountSheet.new("login"))))
		else:
			row.add_child(UiTheme.button("Sign out", func() -> void:
				await Online.logout()
				if is_inside_tree():
					rebuild()))
		row.add_child(UiTheme.button("Profile", func() -> void: _open(ProfileSheet.new())))
		right.add_child(row)


func _heading(text: String) -> Label:
	return UiTheme.title(text, 12, UiTheme.GOLD)


func _choice(caption: String, names: Array, chosen: int, pick: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var l := UiTheme.label(caption, 10, UiTheme.MUTED)
	l.custom_minimum_size = Vector2(78, 0)
	row.add_child(l)
	var buttons := UiTheme.segmented(names, chosen, func(i: int) -> void: _change(pick.bind(i)))
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(buttons)
	return row


func _volume(caption: String, value: float, on: bool, set_value: Callable, toggle: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var l := UiTheme.label(caption, 10, UiTheme.MUTED)
	l.custom_minimum_size = Vector2(78, 0)
	row.add_child(l)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(func(v: float) -> void:
		set_value.call(v)
		Settings.save()
		Feel.apply_settings())
	slider.drag_ended.connect(func(_changed: bool) -> void: Feel.play("select"))
	row.add_child(slider)
	row.add_child(UiTheme.button("On" if on else "Muted", func() -> void: _change(toggle), 10, UiTheme.PANEL_LIGHT if on else UiTheme.MULT.darkened(0.3)))
	return row


## Applies a change: save, apply, tell the screens, redraw this sheet.
## The next card back: the six designs, then any bought in the Wagon (batch 13), then round.
func _next_back() -> void:
	var owned: Array = WagonCards.COSMETICS["back"].map(func(c: Dictionary) -> String: return c["id"]) \
		.filter(func(id: String) -> bool: return Game.profile.cosmetics.has(id))
	var order: Array = range(Settings.CARD_BACKS.size()).map(func(i: int) -> String: return str(i)) + owned
	var now := CardView.worn_back() if CardView.worn_back() != "" else str(Settings.card_back)
	var next: String = order[(order.find(now) + 1) % order.size()]
	if next.is_valid_int():
		Settings.card_back = int(next)
		Game.profile.wear("back", "")
	else:
		Game.profile.wear("back", next)
	Game.save_profile()
	CardArt.clear()


func _change(apply: Callable) -> void:
	apply.call()
	Settings.save()
	Feel.apply_settings()
	Feel.play("select")
	Feel.settings_changed.emit()
	rebuild()


func _open(sheet: Control) -> void:
	Feel.play("click")
	UiTheme.show_sheet(sheet)
