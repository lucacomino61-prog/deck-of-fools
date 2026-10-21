extends Node
## Opens one screen in a set state, for screenshots.
## Web: the "Web preview" export (feature tag "preview") opens /preview/?screen=<name>; see
## tools/export_web.ps1 and tools/shoot.mjs. Desktop: godot --path game res://tests/preview.tscn -- --screen=show
## Screens: menu, settings, help, choose, coach (the first-run guide), coach2 (its tip with
## cards picked), show, tip (a Jester tapped), detail (a card held), pause, hands, deck (Run
## info), scoring, shop, end (a lost run), won, gallery1–gallery4 (every Jester, 40 to a
## page, at shop size), and online, account, profile, leaderboards (these sign in to the
## local API first). Left out of the real "Web" export.


func _ready() -> void:
	var main: Control = load("res://ui/main.tscn").instantiate()
	add_child(main)
	open(main, requested_screen())


## A page of Jesters laid out in a grid over the menu, in card order.
static func _gallery(main: Control, page: int) -> void:
	var ids: Array = ContentDB.pool("zanni").map(func(d: ContentDef) -> String: return d.id)
	var sheet := ColorRect.new()
	sheet.color = UiTheme.BG
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.add_child(sheet)
	var stage := UiTheme.stage(sheet)
	var first := (maxi(1, page) - 1) * 40
	for i in range(first, mini(first + 40, ids.size())):
		var v := CardView.new(Vector2(56, 78))
		v.kind = "zanni"
		v.def_id = ids[i]
		var k := i - first
		v.position = Vector2(8 + (k % 10) * 63, 6 + (k / 10) * 88)
		stage.add_child(v)


## The six card backs side by side, each drawn while it's the chosen one.
static func _backs(main: Control) -> void:
	var sheet := ColorRect.new()
	sheet.color = UiTheme.BG
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.add_child(sheet)
	var stage := UiTheme.stage(sheet)
	for i in Settings.CARD_BACKS.size():
		Settings.card_back = i
		var v := CardView.new(Vector2(92, 128))
		v.face_down = true
		v.position = Vector2(12 + i * 104, 90)
		stage.add_child(v)
		var l := UiTheme.label(Settings.CARD_BACKS[i], 10, UiTheme.TEXT)
		l.position = Vector2(12 + i * 104, 226)
		stage.add_child(l)
		await v.get_tree().process_frame
		while v._face.texture == null:
			await v.get_tree().process_frame
	Settings.card_back = 0


static func requested_screen() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screen="):
			return arg.get_slice("=", 1)
	if OS.has_feature("web"):
		return str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('screen') || 'menu'", true))
	return "menu"


## Reports the engine's frame cost to the page every half second, for tools/shoot.mjs:
## window.foolsPerf = {fps, process_ms, draw_calls, objects}.
static func report_performance(main: Control) -> void:
	if not OS.has_feature("web"):
		return
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	main.add_child(timer)
	timer.timeout.connect(func() -> void:
		JavaScriptBridge.eval("window.foolsPerf = %s;" % JSON.stringify({
			"fps": Engine.get_frames_per_second(),
			"process_ms": snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.01),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		})))


static func open(main: Control, screen: String) -> void:
	report_performance(main)
	seed(7)
	Settings.seen_help = screen != "help"
	Settings.tutorial_step = 0 if screen.begins_with("coach") else -1
	if screen == "menu":
		return
	if screen == "settings":
		UiTheme.show_sheet(SettingsSheet.new())
		return
	if screen == "backs":
		_backs(main)
		return
	if screen == "conflict":
		var cloud := {"version": 4, "device": "Android", "updated_at": Time.get_unix_time_from_system() - 3 * 3600,
			"data": {"profile": {"total_wins": 3, "runs_lost": 9, "discovered": range(40)}, "run": {"town": 5}}}
		UiTheme.show_sheet(ConflictSheet.new(cloud))
		return
	if screen in ["online", "account", "profile", "leaderboards"]:
		await Online.start()
		match screen:
			"account":
				UiTheme.show_sheet(AccountSheet.new("signup", "You finished your first run! Create an account so your runs, unlocks and cards are kept safe and follow you to any device."))
			"profile":
				UiTheme.show_sheet(ProfileSheet.new())
			"leaderboards":
				UiTheme.show_sheet(LeaderboardSheet.new("best_hand"))
		return
	if screen.begins_with("gallery"):
		_gallery(main, int(screen.substr(7)))
		return
	Game.new_run("d_bergamo", 1)
	var run := Game.run
	var n := 100
	for id in ["z_zanni", "z_arlecchino", "z_capitano", "z_isabella"]:
		run.zanni.append(ItemCard.make(id, n))
		n += 1
	for id in ["t_matto", "s_aries"]:
		run.consumables.append(ItemCard.make(id, n))
		n += 1
	main._show_run()
	var board: RunScreen = main.screens.get_child(main.screens.get_child_count() - 1)
	if screen in ["help", "choose", "coach"]:
		return
	Game.act({"a": "select_show"})
	match screen:
		"tip":
			board.selection = {"zone": "zanni", "index": 1}
			board.refresh()
			return
		"pause":
			UiTheme.show_sheet(PauseSheet.new(board))
			return
		"hands", "deck":
			UiTheme.show_sheet(RunInfoSheet.new(screen))
			return
		"detail":
			board._show_detail(board.jester_views[2])
			return
		"end":
			Game.give_up()
			board.refresh()
			return
		"shop", "won":
			run.show_target = 1.0
			Game.act({"a": "play", "cards": [run.hand[0].id]})
			Game.act({"a": "cash_out"})
			run.ducats = 40
			if screen == "won":
				run.won = true
				run.town = 9
				Game.win_seen = false
			Game.changed.emit()
			return
	board.selected_hand.assign([run.hand[0].id, run.hand[1].id, run.hand[2].id])
	board.refresh()
	if screen == "scoring":
		await main.get_tree().create_timer(1.0).timeout
		board._on_play()
