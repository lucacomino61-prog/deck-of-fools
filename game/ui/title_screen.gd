class_name TitleScreen
extends Control
## The first screen: an Italian station's departures board, a split-flap board like the ones
## that clatter in every Italian station. The title flips into place, then the board greets
## the player with what's waiting for them (greeting()): a gift for coming back, the tour in
## progress, today's card, the nemesis, the Jester nearest its next star, the best show, the
## days played this week; a first visit gets a welcome. "All aboard" (or Enter) opens the
## menu, which is also the first tap that lets a browser start the music.
##
## In a browser the loading page (web/shell.html) draws this same board, cell for cell, while
## the game loads, with the lines this screen last left in localStorage. When the game is
## drawing, page_ready() lets the page go and this board carries on from the same letters:
## the lines that changed flip, and the loading counter becomes "All aboard". In the apps the
## board clatters in from blank. Every position below is copied in web/shell.html.

signal entered

const BG := Color("0e0b12")
const PANEL := Rect2(14, 14, 612, 332)
const HEADER_Y := 22.0
const TITLE := "DECK OF FOOLS"
const TITLE_AT := Vector2(49, 44)
const TITLE_CELL := Vector2(38, 54)
const TITLE_GAP := 4.0
const TITLE_SIZE := 38
const RULE_Y := 110.0
const INFO_AT := Vector2(24.75, 122)
const INFO_COLS := 32
const INFO_ROWS := 4
const INFO_CELL := Vector2(17, 26)
const INFO_GAP := 1.5
const INFO_PITCH := 32.0
const INFO_SIZE := 16
const GO_AT := Vector2(129, 278)
const GO_COLS := 16
const GO_CELL := Vector2(22, 32)
const GO_GAP := 2.0
const GO_SIZE := 20
const GO_TEXT := "  ALL ABOARD  > "
## Where the loading page leaves the last row while the game starts up.
const LOADED_TEXT := " DEPARTING SOON "
## Where the page finds the board's lines for the next visit.
const STORE_KEY := "foolsBoard"
## A first visit's lines (web/shell.html has the same).
const FIRST_LINES := [
	"WELCOME TO THE TOUR OF ITALY    ",
	"FIRST   BERGAMO, MATINEE        ",
	"GOAL    SCORE 300 POINTS        ",
	"TIP     MAKE POKER HANDS        ",
]

var board: FlapBoard
var _go: Button
var _left := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var stage := UiTheme.stage(self)
	var frame := Panel.new()
	var style := UiTheme.box(Color("151119"), Color("2b2233"), 12)
	style.set_border_width_all(1)
	frame.add_theme_stylebox_override("panel", style)
	frame.position = PANEL.position
	frame.size = PANEL.size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(frame)
	var head := UiTheme.label("PARTENZE  ·  DEPARTURES", 9, UiTheme.MUTED)
	head.position = Vector2(34, HEADER_Y)
	stage.add_child(head)
	var clock := UiTheme.label(_clock(), 9, UiTheme.GOLD)
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clock.position = Vector2(506, HEADER_Y)
	clock.size = Vector2(100, 14)
	stage.add_child(clock)
	var rule := ColorRect.new()
	rule.color = Color(UiTheme.GOLD, 0.45)
	rule.position = Vector2(34, RULE_Y)
	rule.size = Vector2(572, 1)
	stage.add_child(rule)

	board = FlapBoard.new()
	stage.add_child(board)
	board.add_row("title", TITLE_AT, TITLE.length(), TITLE_CELL, TITLE_GAP, TITLE_SIZE, UiTheme.GOLD)
	for i in INFO_ROWS:
		board.add_row("info%d" % i, INFO_AT + Vector2(0, i * INFO_PITCH), INFO_COLS, INFO_CELL, INFO_GAP, INFO_SIZE, UiTheme.TEXT)
	board.add_row("go", GO_AT, GO_COLS, GO_CELL, GO_GAP, GO_SIZE, UiTheme.GOLD)

	# "All aboard": the last row, framed, is the button.
	var go_w := GO_COLS * GO_CELL.x + (GO_COLS - 1) * GO_GAP
	_go = Button.new()
	_go.focus_mode = Control.FOCUS_NONE
	_go.position = GO_AT - Vector2(7, 7)
	_go.size = Vector2(go_w + 14, GO_CELL.y + 14)
	_go.pivot_offset = _go.size / 2.0
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var b := UiTheme.box(Color(0, 0, 0, 0), UiTheme.GOLD if state != "disabled" else Color(UiTheme.GOLD, 0.0), 8)
		b.set_border_width_all(2)
		if state == "hover":
			b.border_color = UiTheme.GOLD.lightened(0.3)
		_go.add_theme_stylebox_override(state, b)
	_go.disabled = true
	_go.pressed.connect(_enter)
	_go.button_down.connect(func() -> void: _go.scale = Vector2(0.97, 0.97))
	_go.button_up.connect(func() -> void: _go.scale = Vector2.ONE)
	stage.add_child(_go)

	_open()


## The board fills in: in a browser from where the loading page left it, in the apps from blank.
func _open() -> void:
	var lines := greeting(Game.profile, Game.today(), Game.peek_saved_run())
	if OS.has_feature("web"):
		board.set_text("title", TITLE, true)
		var stored := _stored_lines()
		for i in INFO_ROWS:
			board.set_text("info%d" % i, stored[i], true)
		board.set_text("go", LOADED_TEXT, true)
		_store_lines(lines)
		# The first frames compile shaders and can stall the page: once they're drawn, the page
		# lets go (when its own board has settled) and this one carries on.
		for i in 3:
			await get_tree().process_frame
		if not is_inside_tree():
			return
		page_ready()
		var waited := 0.0
		while waited < 4.0 and bool(JavaScriptBridge.eval("document.getElementById('status') ? 1 : 0", true)):
			await get_tree().process_frame
			waited += get_process_delta_time()
		if not is_inside_tree():
			return
		for i in INFO_ROWS:
			board.set_text("info%d" % i, lines[i], false, i * 0.12)
		board.set_text("go", GO_TEXT, false, 0.5)
	else:
		board.set_text("title", TITLE, false, 0.25, 0.05)
		for i in INFO_ROWS:
			board.set_text("info%d" % i, lines[i], false, 0.8 + i * 0.15)
		board.set_text("go", GO_TEXT, false, 1.5)
	_go.disabled = false


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
	entered.emit()


## The board's four lines for this player: what's waiting for them, most pressing first.
static func greeting(p: Profile, today: String, saved: RunState) -> Array[String]:
	var out: Array[String] = []
	if p.runs_played() == 0 and saved == null:
		out.assign(FIRST_LINES)
		return out
	if str(p.welcome.get("date", "")) == today:
		out.append(line("WELCOME", "BACK! A GIFT OF SCUDI", "+%d" % int(p.welcome.get("scudi", 0))))
	if saved != null:
		var where := "TOWN %d" % saved.town
		if saved.city != "":
			where += "  " + _plain(UiTheme.name_of(saved.city))
		out.append(line("ON TOUR", where, "GO ON"))
	var card := Profile.card_of_the_day(today)
	if card != "":
		out.append(line("TODAY", _plain(UiTheme.name_of(card)), "FREE"))
	if not p.nemesis.is_empty():
		out.append(line("NEMESIS", _plain(UiTheme.name_of(str(p.nemesis["patron"]))), "TOWN %d" % int(p.nemesis["town"])))
	var nearest := ""
	var gap := 1 << 30
	for id in p.fame:
		var need := Fame.to_next(int(p.fame[id]))
		if need > 0 and need < gap:
			gap = need
			nearest = str(id)
	if nearest != "":
		out.append(line("FAME", _plain(UiTheme.name_of(nearest)), "%d MORE" % gap))
	var best := 0.0
	for key in p.show_best:
		best = maxf(best, float(p.show_best[key]))
	if best > 0.0:
		out.append(line("RECORD", UiTheme.number(best) + " IN A SHOW", ""))
	var week := p.days_this_week(today)
	if week >= 2:
		out.append(line("DIARY", "%d DAYS THIS WEEK" % week, ""))
	for filler in [line("TONIGHT", "THE TOUR GOES ON", ""), line("NEXT", "A NEW TOWN, A NEW CROWD", ""), line("", "", ""), line("", "", "")]:
		if out.size() >= INFO_ROWS:
			break
		out.append(filler)
	return out.slice(0, INFO_ROWS)


## One line of the board: a label, its value, and something short on the right.
static func line(label: String, value: String, extra: String) -> String:
	var head := (label + " ".repeat(8)).substr(0, 8) + value
	var room := INFO_COLS - (extra.length() + 1 if extra != "" else 0)
	head = FlapBoard.fit(head, room)
	return (head + (" " + extra if extra != "" else "")).to_upper()


## A name as a station board would print it: no leading article.
static func _plain(name: String) -> String:
	for article in ["Il ", "La ", "Lo ", "Le ", "Gli ", "I ", "L'"]:
		if name.begins_with(article):
			return name.substr(article.length())
	return name


static func _clock() -> String:
	var t := Time.get_time_dict_from_system()
	return "%02d:%02d" % [int(t["hour"]), int(t["minute"])]


## In a browser, tells the loading page the game is drawing, so it can let go of its board.
static func page_ready() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.foolsBoardReady && window.foolsBoardReady()")


## The lines the loading page showed (what this screen left last time, or a first visit's).
func _stored_lines() -> Array[String]:
	var out: Array[String] = []
	out.assign(FIRST_LINES)
	var raw: Variant = JavaScriptBridge.eval("(function(){try{return localStorage.getItem('%s')||''}catch(e){return ''}})()" % STORE_KEY, true)
	var data: Variant = JSON.parse_string(str(raw)) if typeof(raw) == TYPE_STRING and str(raw) != "" else null
	if data is Array and (data as Array).size() == INFO_ROWS:
		for i in INFO_ROWS:
			out[i] = FlapBoard.fit(str(data[i]), INFO_COLS)
	return out


func _store_lines(lines: Array[String]) -> void:
	var json := JSON.stringify(JSON.stringify(lines))
	JavaScriptBridge.eval("(function(){try{localStorage.setItem('%s', %s)}catch(e){}})()" % [STORE_KEY, json], true)
