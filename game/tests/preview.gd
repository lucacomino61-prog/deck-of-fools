extends Node
## Opens one screen in a set state, for screenshots.
## Web: the "Web preview" export (feature tag "preview") opens /preview/?screen=<name>; see
## tools/export_web.ps1 and tools/shoot.mjs. Desktop: godot --path game res://tests/preview.tscn -- --screen=show
## Screens: menu, settings, backs, collection, seed, faces (draws 202 card faces, then logs
## their memory), help, choose, coach (the first-run guide), coach2 (its tip with cards
## picked), show (cards picked: preview and Jester badges), contrast (show with four suit
## colours), notallowed (a Patron refuses the picked hand), tip (a Jester tapped), detail (a
## card held), pause, hands, deck (Run info), scoring, timing (logs what each piece of
## playing a hand costs, and memory), shop, drag (a shop card dragged over its drop zone),
## end (a run given up), lost (beaten by the Patron), won, gallery1–gallery4 (every Jester,
## 40 to a page, at shop size), art1–art6 (the other painted cards; the cities on art5, court cards last), the tour (batch 12):
## perform (a Scenario being performed, the crowd), encore, map, duo (a Lazzo tapped); group 2
## (batch 13): wagon, wardrobe, board (the Wagon's three tabs), campaign, between (How to
## play, page 3), maestri (the collection with fame), maestro (Maestro and starred Jesters, the
## Maestro tapped), bubble (a Patron speaking), rivals (the map with a nemesis, a rematch and a
## painted wagon), chapter (a chapter cleared, choosing who to carry), nemesis (lost to a
## Patron: it becomes the nemesis); and online, account, profile, leaderboards (these sign in to
## the local API first). URL settings for tools/perf.mjs: quality, crt, fps, fx, swirl,
## cardfx. Left out of the real "Web" export.


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


## A page of the other painted cards (Tarocchi, Signs, Omens, Patrons, packs, Warrants, Favors,
## decks, then the court cards), 40 to a page like the Jester gallery.
static func _art(main: Control, page: int) -> void:
	var cards := []
	for kind in ["tarocchi", "sign", "omen", "patron", "pack", "warrant", "favor", "deck", "city"]:
		for d in ContentDB.pool(kind):
			cards.append([kind, d.id, null])
	for s in 4:
		for r in range(11, 14):
			cards.append(["card", "", PlayingCard.make(-1, r, s)])
	var sheet := ColorRect.new()
	sheet.color = UiTheme.BG
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.add_child(sheet)
	var stage := UiTheme.stage(sheet)
	var first := (maxi(1, page) - 1) * 40
	for i in range(first, mini(first + 40, cards.size())):
		var v := CardView.new(Vector2(56, 78))
		v.kind = cards[i][0]
		v.def_id = cards[i][1]
		if cards[i][2] != null:
			v.card = cards[i][2]
		var k := i - first
		v.position = Vector2(8 + (k % 10) * 63, 6 + (k / 10) * 88)
		stage.add_child(v)


## A long session's worth of card faces (every Jester at shop size, then a deck at hand
## size), shown a page at a time like the collection, for the card-art memory figures.
static func _faces(main: Control) -> void:
	var sheet := ColorRect.new()
	sheet.color = UiTheme.BG
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.add_child(sheet)
	var stage := UiTheme.stage(sheet)
	var views := []
	for d in ContentDB.pool("zanni"):
		var v := CardView.new(Vector2(60, 84))
		v.kind = "zanni"
		v.def_id = d.id
		views.append(v)
	for s in 4:
		for r in range(2, 15):
			var v := CardView.new(Vector2(70, 98))
			v.card = PlayingCard.make(-1, r, s)
			views.append(v)
	for i in views.size():
		var v: CardView = views[i]
		v.position = Vector2(8 + (i % 10) * 63, 6 + ((i / 10) % 4) * 88)
		stage.add_child(v)
		if i % 40 == 39 or i == views.size() - 1:
			for f in 6:
				await main.get_tree().process_frame
			for old in views.slice(i - (i % 40), i + 1):
				(old as Node).queue_free()
	for f in 10:
		await main.get_tree().process_frame
	CardArt._trim()
	await main.get_tree().process_frame
	_memory_report()


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


## A profile a few weeks in (batch 13): scudi, props, cosmetics worn, three chapters
## cleared with a Jester carried, and fame (Zanni a Maestro, Arlecchino two stars,
## Il Capitano one).
static func _progress_profile() -> void:
	var p := Game.profile
	p.scudi = 340
	p.props_owned = {"p_salvadanaio": true, "p_claque": true, "p_lanterna": true}
	p.carried.assign(["p_claque"])
	p.cosmetics = {"paint_azzurro": true, "trim_flags": true, "trim_lanterns": true, "cloth_viola": true, "back_corte": true}
	p.worn = {"paint": "paint_azzurro", "trims": ["trim_flags", "trim_lanterns"]}
	p.chapters_cleared = 3
	p.carry = {"id": "z_colombina", "parts": []}
	p.fame = {"z_zanni": 131, "z_arlecchino": 74, "z_capitano": 31, "z_isabella": 12}


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
			"texture_mb": snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, 0.1),
			"viewports": main.get_tree().root.find_children("*", "SubViewport", true, false).size(),
		})))


## Logs every frame over 40 ms to the page console with what happened in it: card faces
## drawn, nodes made, and the engine's own frame time split. For tools/perf.mjs.
static func watch_frames(main: Control) -> void:
	if not OS.has_feature("web"):
		return
	var last := [Time.get_ticks_usec(), 0, 0]
	main.get_tree().process_frame.connect(func() -> void:
		var now := Time.get_ticks_usec()
		var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var ms := (now - int(last[0])) / 1000.0
		if ms > 40.0 and int(last[1]) > 0:
			JavaScriptBridge.eval("console.log(%s)" % JSON.stringify("LONG FRAME %.0f ms: %d faces drawn, %+d nodes (now %d), process %.1f ms, viewports %d" % [
				ms, CardArt.baked - int(last[2]), nodes - int(last[1]), nodes,
				Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
				main.get_tree().root.find_children("*", "SubViewport", true, false).size()]))
		last[0] = now
		last[1] = nodes
		last[2] = CardArt.baked)


## Logs where texture memory goes ("TIMING ..." lines): the font's glyph pages, the card
## faces CardArt keeps, the backdrop.
static func _memory_report() -> void:
	var faces := 0
	var face_bytes := 0
	for v in CardArt.get_children():
		if v is SubViewport:
			faces += 1
			face_bytes += (v as SubViewport).size.x * (v as SubViewport).size.y * 4
	var font := UiTheme.font as FontFile
	var sizes := 0
	var pages := 0
	var glyph_bytes := 0
	for c in font.get_cache_count():
		for s: Vector2i in font.get_size_cache_list(c):
			sizes += 1
			for t in font.get_texture_count(c, s):
				var image := font.get_texture_image(c, s, t)
				if image != null:
					glyph_bytes += image.get_data_size()
					pages += 1
	JavaScriptBridge.eval("console.log(%s)" % JSON.stringify("TIMING textures %.1f MB in all; card faces %d = %.1f MB; font glyphs %d sizes, %d pages = %.1f MB" % [
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, faces, face_bytes / 1048576.0, sizes, pages, glyph_bytes / 1048576.0]))


## Times the pieces of playing a hand, each run 5 times, and logs them ("TIMING ...").
static func _time_pieces(board: RunScreen) -> void:
	var run := Game.run
	var ids := board._selected_ids()
	var pieces := {
		"save the run (JSON + file)": func() -> void: Game._save_run(),
		"run.to_dict + stringify": func() -> void: JSON.stringify(run.to_dict()),
		"score preview": func() -> void: run.preview(ids),
		"refresh the run screen": func() -> void: board.refresh(),
		"build the hand": func() -> void: board._build_hand(),
		"build the top row": func() -> void: board._build_top(),
		"side panel": func() -> void: board._update_side(),
		"score a copy (Scorer)": func() -> void:
			var copy := RunState.from_dict(run.to_dict())
			copy.apply({"a": "play", "cards": ids}),
	}
	for name in pieces:
		var start := Time.get_ticks_usec()
		for i in 5:
			pieces[name].call()
		var ms := (Time.get_ticks_usec() - start) / 5000.0
		JavaScriptBridge.eval("console.log(%s)" % JSON.stringify("TIMING %s: %.2f ms" % [name, ms]))
	# A late run: a full tour logs about 300 actions.
	var entry: Dictionary = run.action_log[run.action_log.size() - 1]
	while run.action_log.size() < 300:
		run.action_log.append(entry.duplicate(true))
	var t0 := Time.get_ticks_usec()
	for i in 5:
		Game._save_run()
	JavaScriptBridge.eval("console.log(%s)" % JSON.stringify("TIMING save with 300 logged actions: %.2f ms" % ((Time.get_ticks_usec() - t0) / 5000.0)))
	t0 = Time.get_ticks_usec()
	for i in 5:
		run.preview(ids)
	JavaScriptBridge.eval("console.log(%s)" % JSON.stringify("TIMING preview with 300 logged actions: %.2f ms" % ((Time.get_ticks_usec() - t0) / 5000.0)))


## A setting from the page URL (?quality=0&crt=1&fps=30), for tools/perf.mjs; -1 if absent.
static func _url_setting(name: String) -> int:
	if not OS.has_feature("web"):
		return -1
	return int(JavaScriptBridge.eval("Number(new URLSearchParams(location.search).get('%s') ?? -1)" % name, true))


static func open(main: Control, screen: String) -> void:
	report_performance(main)
	watch_frames(main)
	seed(7)
	if _url_setting("quality") >= 0:
		Settings.quality = _url_setting("quality")
	if _url_setting("crt") >= 0:
		Settings.crt = _url_setting("crt")
	if _url_setting("fps") >= 0:
		Settings.fps = _url_setting("fps")
	Feel.apply_settings()
	# Experiments for tools/perf.mjs: fx=0 drops floating numbers and particles, swirl=0 stops
	# redrawing the backdrop, cardfx=0 stops the cards' pointer tilt.
	if _url_setting("fx") == 0:
		Feel.effects = null
	if _url_setting("swirl") == 0:
		Feel._backdrop_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
		Feel.set_process(false)
	if _url_setting("cardfx") == 0:
		var timer := Timer.new()
		timer.wait_time = 0.1
		timer.autostart = true
		main.add_child(timer)
		timer.timeout.connect(func() -> void:
			for node in main.find_children("*", "CardView", true, false):
				node.set_process(false))
	Settings.seen_help = screen != "help"
	Settings.tutorial_step = 0 if screen.begins_with("coach") else -1
	if screen == "menu":
		return
	if screen == "title":
		main._show_title()
		return
	if screen == "grand_menu":
		main._show_menu()
		var menu: Node = main.screens.get_children().back()
		menu.mode = "grand"
		menu._build()
		return
	if screen == "grand_map":
		# A Grand Tour halfway: the map from Palermo, the troupe in town 6.
		Game.new_run("d_bergamo", 1, "", "PREVIEW", {"grand": true})
		var long_run := Game.run
		for i in 5:
			long_run.town += 1
			long_run.route_row += 1
			long_run.path.append(0)
			long_run.route_col = 0
			long_run.city = str(long_run.route[long_run.route_row][0]["city"])
		long_run.phase = RunState.Phase.MAP
		main._show_run()
		return
	if screen == "board":
		# The station board for a returning player: a gift, today's card, a nemesis, fame, a
		# record and the diary.
		_progress_profile()
		var p := Game.profile
		p.total_wins = 2
		p.welcome = {"date": Game.today(), "scudi": Profile.WELCOME_SCUDI, "away": 4}
		p.nemesis = {"patron": "pt_badessa", "town": 3}
		p.show_best = {"1/1/0": 1240.0, "1/2/2": 41200.0}
		main._show_title()
		return
	if screen == "menu_saved":
		# The menu with a tour in progress and some progress made.
		_progress_profile()
		Game.new_run("d_venezia", 1)
		main._show_menu()
		return
	if screen == "settings":
		UiTheme.show_sheet(SettingsSheet.new())
		return
	if screen == "backs":
		_backs(main)
		return
	if screen == "faces":
		_faces(main)
		return
	if screen == "collection":
		for d in ContentDB.pool("zanni").slice(0, 40):
			Game.profile.discovered[d.id] = true
		UiTheme.show_sheet(CollectionSheet.new())
		return
	if screen == "lazzi":
		UiTheme.show_sheet(CollectionSheet.new("lazzo"))
		return
	if screen == "tour":
		var help := HowToPlay.new()
		help.page = 1
		UiTheme.show_sheet(help)
		return
	if screen == "seed":
		UiTheme.show_sheet(SeedSheet.new(func(_s: String) -> void: pass, "Bergamo deck, Stake 1"))
		return
	if screen == "contrast":
		Settings.high_contrast = true
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
	if screen.begins_with("art"):
		_art(main, int(screen.substr(3)))
		return
	if screen in ["wagon", "wardrobe", "board", "campaign", "between", "maestri", "maestro", "rivals", "chapter"]:
		_progress_profile()
	match screen:
		"wagon", "wardrobe", "board":
			var wagon := WagonSheet.new()
			wagon.tab = "props" if screen == "wagon" else screen
			if screen == "wardrobe":
				wagon.picked = "trim_awning"
			UiTheme.show_sheet(wagon)
			return
		"campaign":
			UiTheme.show_sheet(CampaignSheet.new(func(_c: String, _d: String) -> void: pass))
			return
		"between":
			var help := HowToPlay.new()
			help.page = 2
			UiTheme.show_sheet(help)
			return
		"maestri":
			for d in ContentDB.pool("zanni").slice(0, 40):
				Game.profile.discovered[d.id] = true
			UiTheme.show_sheet(CollectionSheet.new())
			return
		"rivals":
			Game.profile.nemesis = {"patron": "pt_censore", "town": 2}
	Game.new_run("d_bergamo", 1)
	var run := Game.run
	var n := 100
	for id in ["z_zanni", "z_arlecchino", "z_capitano", "z_isabella"]:
		run.zanni.append(ItemCard.make(id, n))
		n += 1
	for id in ["t_matto", "s_aries"]:
		run.consumables.append(ItemCard.make(id, n))
		n += 1
	if screen == "duo":
		var duo := ItemCard.make("lz_vecchi", 10)
		duo.parts.assign([ItemCard.make("z_pantalone", 5), ItemCard.make("z_dottore", 4)])
		run.zanni[3] = duo
	main._show_run()
	var board: RunScreen = main.screens.get_child(main.screens.get_child_count() - 1)
	if screen in ["help", "choose", "coach"]:
		return
	if screen == "rivals":
		run.show_index = Shows.PATRON
		run.phase = RunState.Phase.SHOP
		run.shop = ShopState.new()
		Game.act({"a": "leave_shop"})
		# A rematch drawn for the same town shows its ribbon only when it isn't the nemesis's;
		# here the map marks the nemesis, and the panel shows the city tapped.
		Game.changed.emit()
		return
	if screen == "chapter":
		Game.start_chapter("ch_04", "d_genova")
		run = Game.run
		for id in ["z_zanni", "z_arlecchino", "z_colombina", "z_lampionaio"]:
			run.zanni.append(ItemCard.make(id, 3))
		run.fame = {"z_zanni": 9, "z_arlecchino": 7, "z_colombina": 5}
		run.counters["shows_won"] = 24
		run.counters["encores"] = 3
		run.won = true
		run.town = 8
		run.show_index = Shows.PATRON
		run.phase = RunState.Phase.SHOP
		run.shop = ShopState.new()
		Game.win_seen = false
		main._show_run()
		return
	if screen == "map":
		run.show_index = Shows.PATRON
		run.phase = RunState.Phase.SHOP
		run.shop = ShopState.new()
		Game.act({"a": "leave_shop"})
		Game.changed.emit()
		return
	if screen == "bubble":
		SpeechBubble.hold = true
		run.show_index = Shows.PATRON
		run.town_patron = "pt_gabelliere"
	if screen == "nemesis":
		run.show_index = Shows.PATRON
		run.town = 3
		run.town_patron = "pt_duca"
	Game.act({"a": "select_show", "perform": screen == "perform"})
	match screen:
		"maestro":
			board.selection = {"zone": "zanni", "index": 0}
			board.refresh()
			return
		"bubble":
			return
		"nemesis":
			run.show_score = 41200.0
			run.phase = RunState.Phase.LOST
			Game.finish_run()
			board.refresh()
			return
		"encore":
			run.show_target = 1.0
			Game.act({"a": "play", "cards": [run.hand[0].id, run.hand[1].id]})
			Game.changed.emit()
			return
		"duo":
			board.selection = {"zone": "zanni", "index": 3}
			board.refresh()
			return
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
		"lost":
			run.show_index = Shows.PATRON
			run.show_score = 1840.0
			run.phase = RunState.Phase.LOST
			Game.finish_run()
			board.refresh()
			return
		"notallowed":
			run.show_counters["patron"] = "pt_ciambellano"
		"drag":
			run.show_target = 1.0
			Game.act({"a": "play", "cards": [run.hand[0].id]})
			Game.act({"a": "bow"})
			Game.act({"a": "cash_out"})
			Game.changed.emit()
			await main.get_tree().process_frame
			var offer: Control = board.middle.get_children().filter(func(c: Node) -> bool: return c is CardView)[0]
			offer.global_position = board.top_row.get_global_rect().get_center() - offer.size / 2.0
			offer.z_index = 2
			board._show_hint("top", "Drop to buy for 6", true, offer)
			return
		"shop", "won":
			run.show_target = 1.0
			Game.act({"a": "play", "cards": [run.hand[0].id]})
			Game.act({"a": "bow"})
			Game.act({"a": "cash_out"})
			run.ducats = 40
			if screen == "won":
				run.won = true
				run.town = 9
				Game.win_seen = false
			Game.changed.emit()
			return
	if screen == "ghost":
		# A best of 240 at this show: the ghost mark sits just short of the target.
		Game.profile.show_best[Profile.show_key(run)] = 240.0
	board.selected_hand.assign([run.hand[0].id, run.hand[1].id, run.hand[2].id])
	board.refresh()
	if screen == "timing":
		await main.get_tree().create_timer(2.0).timeout
		_memory_report()
		_time_pieces(board)
		return
	if screen == "scoring":
		# Long enough for Feel.prepare_audio() to finish, as it would on the menu.
		await main.get_tree().create_timer(3.0).timeout
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window.foolsScoring = performance.now()")
		board._on_play()
