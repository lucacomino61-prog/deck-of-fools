extends Control
## The app's root: applies the theme, puts the one swirling backdrop behind everything,
## switches between the station board, the menu and the run behind a wave of falling flaps,
## and owns the overlay layers — particles above the screens, the flaps above them, the CRT
## effect (Off, Light or Full) above everything.

var screens: Control
var wipe: FlapWipe


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.build()
	Feel.setup_backdrop(self)
	screens = Control.new()
	screens.set_anchors_preset(Control.PRESET_FULL_RECT)
	screens.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screens)
	var fx := CanvasLayer.new()
	fx.layer = 5
	add_child(fx)
	# Floating numbers need the game's font: a themed root under the effects layer.
	var fx_root := Control.new()
	fx_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_root.theme = theme
	fx.add_child(fx_root)
	wipe = FlapWipe.new()
	add_child(wipe)
	var crt_layer := CanvasLayer.new()
	crt_layer.layer = 10
	add_child(crt_layer)
	var crt := ColorRect.new()
	crt.set_anchors_preset(Control.PRESET_FULL_RECT)
	crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt_layer.add_child(crt)
	Feel.shake_target = screens
	Feel.effects = fx_root
	Feel.crt_rect = crt
	Feel.apply_settings()
	Feel.prepare_audio()
	UiTheme.sheet_host = self
	Online.conflict.connect(func(cloud: Dictionary) -> void: UiTheme.show_sheet(ConflictSheet.new(cloud)))
	if OS.has_feature("preview"):
		# Only the "Web preview" export has this tag: it opens the screen named in ?screen=.
		_show_menu()
		TitleScreen.page_ready()
		var preview: GDScript = load("res://tests/preview.gd")
		preview.open(self, preview.requested_screen())
	else:
		_show_title()
		Online.start()


## The station board, the first thing the game shows; then the menu. In a browser the loading
## page drew the same board and hands over to this one.
func _show_title() -> void:
	_clear()
	var title := TitleScreen.new()
	screens.add_child(title)
	title.entered.connect(wipe.sweep.bind(_show_menu))


func _show_menu() -> void:
	_clear()
	var menu := MenuScreen.new()
	screens.add_child(menu)
	menu.start.connect(wipe.sweep.bind(_show_run))


func _show_run() -> void:
	_clear()
	var board := RunScreen.new()
	screens.add_child(board)
	board.back_to_menu.connect(wipe.sweep.bind(_show_menu))


func _clear() -> void:
	for child in screens.get_children():
		child.queue_free()
