extends Node
## UI smoke test: drives the real screens through every phase of a run and rebuilds them
## at each step, so any script error in a screen shows up. The controls get real input
## events pushed through the viewport (taps, holds, drags and flicks on cards; keys), so
## an overlay that swallows taps shows up too. Run with:
##   godot --headless --path game res://tests/ui_smoke.tscn
## Prints "UI SMOKE OK" on success (tools/test.ps1 also fails on any engine error line).


func _ready() -> void:
	seed(7)
	# The whole game, whatever this machine's profile has played (the practice town is tested
	# on its own).
	Settings.step_by_step = false
	Settings.practice_done = true
	get_tree().create_timer(90.0).timeout.connect(func() -> void:
		push_error("UI SMOKE FAILED: timed out")
		get_tree().quit(1))
	var main: Control = load("res://ui/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	# The poster comes first; Enter (here the key) opens the menu.
	var title: Node = main.screens.get_child(0)
	_check(title is TitleScreen, "the game opens on the poster")
	_check_fills(title, "the poster")
	_key(KEY_ENTER)
	# The flaps fall shut over the board, then the menu is behind them.
	await get_tree().create_timer(FlapWipe.FLAP + (FlapWipe.COLS + FlapWipe.ROWS) * FlapWipe.STAGGER + 0.3).timeout
	await get_tree().process_frame
	var menu: Node = main.screens.get_children().filter(func(c: Node) -> bool: return not c.is_queued_for_deletion()).back()
	_check(menu is MenuScreen, "Enter opens the menu")
	_check_fills(menu, "the menu")
	_check(menu.find_children("*", "Button", true, false).any(func(b: Button) -> bool: return b.text == "Play"), "the menu's Play")
	_check(menu.find_children("*", "Button", true, false).any(func(b: Button) -> bool: return b.text == "Grand Tour"), "the menu's Grand Tour tab")
	Game.new_run("d_bergamo", 1)
	Settings.tutorial_step = 0
	Settings.speed = 1
	var board := RunScreen.new()
	main.add_child(board)
	_check_fills(board, "the run screen")
	var run := Game.run
	_check(board.coach.get_child_count() > 0, "the first-run guide shows its first tip")
	_step(board, {"a": "select_show"})
	_check(Settings.tutorial_step == 1, "the guide moved on when the show started")
	await _controls(board)
	await _settings(board)
	# Win the show at 4x speed, skipping the scoring with a tap.
	run.show_target = 1.0
	Settings.speed = 4
	board.selected_hand.assign([run.hand[0].id, run.hand[1].id])
	board.refresh()
	board._on_play()
	_check(is_equal_approx(Engine.time_scale, 4.0), "Game speed 4x speeds the scoring up")
	_click(board.get_global_rect().get_center())
	_check(board.skipping and Engine.time_scale > 4.0, "a tap during scoring skips it")
	while board.busy:
		await get_tree().create_timer(0.05).timeout
	_check(is_equal_approx(Engine.time_scale, 1.0), "the speed is back to normal after scoring")
	Settings.speed = 1
	await _encore(board)
	_check(run.phase == RunState.Phase.CASH_OUT, "the show was won")
	_key(KEY_ENTER)
	_check(run.phase == RunState.Phase.SHOP, "Enter cashes out")
	run.ducats = 200
	await _drag_to_act(board)
	_merge(board)
	for kind in ["pk_tarocchi_small", "pk_card_big", "pk_zanni_small"]:
		run.shop.packs.assign([{"id": kind, "cost": 4, "sold": false}])
		_step(board, {"a": "buy_pack", "slot": 0})
		board.selection = {"zone": "pack_item", "index": 0}
		board.refresh()
		_step(board, {"a": "skip_pack"})
	_step(board, {"a": "reroll"})
	_step(board, {"a": "leave_shop"})
	_step(board, {"a": "skip_show"})
	# A skipped show's Favor can open a pack first.
	while run.phase == RunState.Phase.PACK:
		_step(board, {"a": "skip_pack"})
	_step(board, {"a": "select_show"})
	run.hands_left = 1
	run.show_target = 1e12
	board.selected_hand.assign([run.hand[0].id])
	board._on_play()
	while board.busy:
		await get_tree().create_timer(0.05).timeout
	_check(run.phase == RunState.Phase.LOST or run.phase == RunState.Phase.CASH_OUT, "the run ended or the show passed")
	board.refresh()
	await _map(board)
	await _pause_menu(board)
	await _progression(board)
	Game.new_run("d_bergamo", 1)
	await _practice(board)
	_check(Game.continue_run(), "a saved run continues")
	print("UI SMOKE OK")
	get_tree().quit()


## The practice town: its tips, the best-hand button picking a hand, the receipt after it, and
## the saved tour still there afterwards (the practice isn't saved).
func _practice(board: RunScreen) -> void:
	Game.start_practice()
	var run := Game.run
	board._practice_seen.clear()
	board.refresh()
	_check(_has_text(board.coach, "practice town"), "the practice town's first tip")
	_step(board, {"a": "select_show"})
	_check(_has_text(board.coach, "poker hand"), "the tip about making a poker hand")
	var best := board._best_hand()
	_check(not best.is_empty() and _press_button(board.middle, "Best here: " + str(best["label"])), "the best-hand button")
	_check(board.selected_hand.size() == (best["ids"] as Array).size(), "it picked that hand")
	board._on_play()
	while board.busy:
		await get_tree().create_timer(0.05).timeout
	board.refresh()
	_check(board.info_name.text.begins_with("How your last hand scored") or run.phase != RunState.Phase.IN_SHOW, "the receipt in the side panel")
	_check(board._receipt.size() >= 2 and board._receipt[-1].begins_with("="), "the receipt ends with the sum")
	_check(not FileAccess.file_exists(Game.RUN_PATH) or not RunState.from_dict(JSON.parse_string(FileAccess.get_file_as_string(Game.RUN_PATH))).practice, "the practice isn't saved over the tour")


## Cards and keys: number keys pick cards, the preview names a score, S sorts, a tap
## selects, a hold opens the details, a drag reorders the hand, I and Esc open and close
## sheets, a flick down discards.
func _controls(board: RunScreen) -> void:
	var run := Game.run
	_key(KEY_1)
	_key(KEY_2)
	_check(board.selected_hand.size() == 2, "number keys pick cards (%d picked)" % board.selected_hand.size())
	_check(_has_text(board.middle, "Scores about"), "the score preview shows")
	_key(KEY_S)
	_check(board.sort_by == "suit", "S sorts by suit")
	board.selected_hand.clear()
	board.refresh()
	await get_tree().process_frame
	var first := _hand_view(board, 0)
	_click(first.get_global_rect().get_center())
	_check(board.selected_hand.size() == 1, "a tap on a card selects it")
	# The tap rebuilt the hand while the card's hold timer was running; it must not fire.
	await get_tree().create_timer(0.5).timeout
	_check(not UiTheme.sheet_open(), "a tap doesn't open the details later")
	var held := _hand_view(board, 2)
	_press(held.get_global_rect().get_center())
	await get_tree().create_timer(0.55).timeout
	_release(held.get_global_rect().get_center())
	_check(_top_sheet() is DetailSheet, "holding a card opens its details")
	_key(KEY_ESCAPE)
	_check(not UiTheme.sheet_open(), "Esc closes the details")
	await get_tree().process_frame
	var dragged := _hand_view(board, 0)
	var dragged_id := int(dragged.tag["id"])
	var from := dragged.get_global_rect().get_center()
	_press(from)
	for i in 6:
		_move(from + Vector2(30 * (i + 1), 0))
	_release(from + Vector2(180, 0))
	_check(board.sort_by == "custom" and board.custom_order.find(dragged_id) > 0, "dragging a card reorders the hand")
	_key(KEY_I)
	var info := _top_sheet()
	_check(info is RunInfoSheet, "I opens Run info")
	if info is RunInfoSheet:
		for tab in ["deck", "run", "hands"]:
			info.tab = tab
			info.rebuild()
	_key(KEY_ESCAPE)
	_check(not UiTheme.sheet_open(), "Esc closes Run info")
	await get_tree().process_frame
	var discards := run.discards_left
	var flicked := _hand_view(board, 3)
	var at := flicked.get_global_rect().get_center()
	_press(at)
	_move(at + Vector2(0, 20))
	_move(at + Vector2(0, 40))
	_release(at + Vector2(0, 40))
	while board.busy:
		await get_tree().create_timer(0.05).timeout
	_check(run.discards_left == discards - 1, "a flick down discards")
	board.selected_hand.clear()
	board.refresh()


## Drag to act, in the shop: a card dragged up to the Jesters' row is bought, a Jester
## dragged down off the row is sold, a Sign dragged onto the table is used.
func _drag_to_act(board: RunScreen) -> void:
	var run := Game.run
	await get_tree().process_frame
	var offer := _view(board.middle, "offer", 0)
	_check(offer != null, "a shop card to drag")
	if offer != null:
		_drag(offer.get_global_rect().get_center(), board.top_row.get_global_rect().get_center())
		_check(run.shop.offers[0]["sold"], "dragging a shop card up to the Jesters buys it")
	run.zanni.append(ItemCard.make("z_zanni", 2))
	run.consumables.clear()
	run.consumables.append(ItemCard.make("s_aries", 3))
	board.refresh()
	await get_tree().process_frame
	var jesters := run.zanni.size()
	var jester := _view(board.top_row, "zanni", jesters - 1)
	if jester != null:
		_drag(jester.get_global_rect().get_center(), board.middle.get_global_rect().get_center())
	_check(run.zanni.size() == jesters - 1, "dragging a Jester down off its row sells it")
	await get_tree().process_frame
	var sign := _view(board.top_row, "consumable", 0)
	if sign != null:
		_drag(sign.get_global_rect().get_center(), board.middle.get_global_rect().get_center())
	_check(run.consumables.is_empty(), "dragging a Sign onto the table uses it")
	_check(not board.drop_hint.visible, "the drop hint is gone after a drop")


## The tour (batch 12), part 1: a show won with a happy crowd brings an Encore. The audience
## chants, Encore! deals a hand, and a hand that lands doubles the cash-out.
func _encore(board: RunScreen) -> void:
	var run := Game.run
	_check(run.phase == RunState.Phase.ENCORE, "a happy crowd demands an Encore (phase %d, mood %d)" % [run.phase, run.mood])
	if run.phase != RunState.Phase.ENCORE:
		return
	_check(board.audience.visible, "the audience is there")
	_check(_has_text(board.middle, "Bis!"), "the Encore panel shows")
	_check(_press_button(board.buttons, "Encore!"), "an Encore! button")
	await get_tree().process_frame
	_check(_hand_view(board, 0) != null, "the Encore deals a hand")
	board.selected_hand.assign([run.hand[0].id, run.hand[1].id])
	board.refresh()
	board._on_play()
	while board.busy:
		await get_tree().create_timer(0.05).timeout
	board.refresh()
	_check(_has_text(board.middle, "Encore! (x2)"), "the cash-out shows the Encore's double")


## Part 2, in the Market: two Jesters of a duo get a Merge button that makes their Lazzo.
func _merge(board: RunScreen) -> void:
	var run := Game.run
	run.zanni.assign([ItemCard.make("z_isabella", 3), ItemCard.make("z_flavio", 4)])
	board.selection = {"zone": "zanni", "index": 0}
	board.refresh()
	_check(_press_button(board.buttons, "Merge: Isabella e Flavio"), "a Merge button")
	board.refresh()
	_check(run.zanni.size() == 1 and run.zanni[0].def_id == "lz_isabella_flavio", "the duo merged")
	_check(_view(board.top_row, "zanni", 0) != null and _view(board.top_row, "zanni", 0).kind == "lazzo", "the duo card shows")


## Part 3: after the Patron's Market the map opens; a tap on a glowing city picks it,
## Travel goes there, and the next show offers its Scenario to Perform.
func _map(board: RunScreen) -> void:
	Game.new_run("d_bergamo", 1)
	var run := Game.run
	run.show_index = Shows.PATRON
	run.phase = RunState.Phase.SHOP
	run.shop = ShopState.new()
	board.refresh()
	_step(board, {"a": "leave_shop"})
	_check(run.phase == RunState.Phase.MAP, "the map after the Patron")
	await get_tree().process_frame
	var map: MapView = null
	for child in board.middle.get_children():
		if child is MapView:
			map = child
	_check(map != null, "the map shows")
	if map == null:
		return
	var col: int = run.roads()[run.roads().size() - 1]
	var dest: String = (run.route[1] as Array)[col]["city"]
	_click(map.get_global_transform() * map.city_point(dest))
	_check(board.selection == {"zone": "city", "index": col}, "a tap picks a city (%s)" % [board.selection])
	var options: Array = ContentDB.get_def(dest).data.get("options", [])
	_check(_press_button(board.buttons, "Travel to" if options.is_empty() else UiTheme.name_of(dest)), "a Travel button")
	# The wagon rolls along the road first (batch 13).
	_check(board.busy, "the wagon rolls before the troupe arrives")
	while board.busy:
		await get_tree().create_timer(0.05).timeout
	_check(run.phase == RunState.Phase.CHOOSE_SHOW and run.city == dest, "travelled to %s" % dest)
	_check(_has_text(board.hand_row, "Tonight's Scenario"), "the Scenario on offer shows")
	_check(_press_button(board.buttons, "Perform the Scenario"), "a Perform button")
	_check(run.scenario_on, "performing the Scenario")
	board.refresh()
	_check(_has_text(board.middle, "Crowd"), "the crowd's mood shows")
	run.phase = RunState.Phase.CHOOSE_SHOW


## Part 4 (batch 13): the Wagon sells a prop, a paint and a deck; the Campaign sets out on
## chapter 1; a Maestro wears its frame; a Patron speaks; a cleared chapter keeps the Jester
## picked to carry on. The profile is put back as it was afterwards.
func _progression(board: RunScreen) -> void:
	var kept := Game.profile.to_dict()
	Game.profile = Profile.new()
	Game.profile.scudi = 500
	Game.profile.fame["z_zanni"] = Fame.MAESTRO + 5
	var wagon := WagonSheet.new()
	UiTheme.show_sheet(wagon)
	await get_tree().process_frame
	_check(_press_button(wagon.body, "Buy 40"), "a prop to buy")
	await get_tree().process_frame
	_check(Game.profile.props_owned.size() == 1 and Game.profile.carried.size() == 1, "bought and carried")
	_check(_press_button(wagon.body, "Wardrobe"), "the Wardrobe tab")
	await get_tree().process_frame
	_check(_press_button(wagon.body, "Rosso"), "a paint to try on")
	await get_tree().process_frame
	_check(_press_button(wagon.body, "Buy 20"), "a paint to buy")
	await get_tree().process_frame
	_check(Game.profile.worn.get("paint", "") == "paint_rosso", "the wagon wears it")
	_check(_press_button(wagon.body, "Notice board"), "the Notice board tab")
	await get_tree().process_frame
	_check(_press_button(wagon.body, "Buy 80"), "a deck to buy early")
	await get_tree().process_frame
	_check(Game.profile.bought.size() == 1, "a deck bought")
	_check(Game.profile.scudi == 500 - 40 - 20 - 80, "paid in scudi (%d left)" % Game.profile.scudi)
	wagon.close()

	var started := []
	var campaign := CampaignSheet.new(func(chapter: String, deck: String) -> void:
		started.append(chapter)
		Game.start_chapter(chapter, deck))
	UiTheme.show_sheet(campaign)
	await get_tree().process_frame
	_check(_has_text(campaign.body, "Il Biglietto"), "the first chapter shows")
	_check(_press_button(campaign.body, "Set out"), "a Set out button")
	await get_tree().process_frame
	_check(started == ["ch_01"] and Game.run.chapter == "ch_01", "chapter 1 starts")
	_check(Game.run.is_maestro(ItemCard.make("z_zanni", 2)) and Game.run.props.size() == 1, "with the Maestro and the prop")

	var run := Game.run
	run.zanni.assign([ItemCard.make("z_zanni", 2), ItemCard.make("z_lampionaio", 3)])
	board.refresh()
	await get_tree().process_frame
	var jester := _view(board.top_row, "zanni", 0)
	_check(jester != null and jester.maestro, "the Maestro wears its frame")
	run.show_index = Shows.PATRON
	_step(board, {"a": "select_show"})
	await get_tree().process_frame
	_check(board.stage.get_children().any(func(c: Node) -> bool: return c is SpeechBubble), "the Patron speaks")

	run.won = true
	run.phase = RunState.Phase.SHOP
	run.shop = ShopState.new()
	Game.win_seen = false
	board.refresh()
	await get_tree().process_frame
	_check(_has_text(board.overlay, "Chapter 1 cleared!"), "the chapter's end screen")
	var second: CardView = null
	for v in _all_views(board.overlay):
		if v.def_id == "z_lampionaio":
			second = v
	_check(second != null, "the troupe to choose from")
	if second != null:
		second.tapped.emit(second)
		await get_tree().process_frame
	_check(_press_button(board.overlay, "On to the campaign"), "On to the campaign")
	_check(Game.profile.chapters_cleared == 1 and Game.profile.carry.get("id", "") == "z_lampionaio", "cleared, carrying the Jester picked")
	_check(Game.open_campaign, "the menu will open the campaign")
	Game.open_campaign = false
	Game.profile = Profile.from_dict(kept)
	Game.save_profile()


func _all_views(node: Node) -> Array:
	var out := []
	for child in node.get_children():
		if child is CardView and not child.is_queued_for_deletion():
			out.append(child)
		out.append_array(_all_views(child))
	return out


func _drag(from: Vector2, to: Vector2) -> void:
	_press(from)
	for i in 8:
		_move(from.lerp(to, (i + 1) / 8.0))
	_release(to)


func _view(parent: Node, zone: String, index: int) -> CardView:
	for child in parent.get_children():
		if child is CardView and not child.is_queued_for_deletion() and child.tag.get("zone") == zone and int(child.tag.get("index", -1)) == index:
			return child
	return null


## Every setting rebuilds the screen without errors; a wide phone screen gets a wider stage
## and bigger cards.
func _settings(board: RunScreen) -> void:
	var sheet := SettingsSheet.new()
	UiTheme.show_sheet(sheet)
	await get_tree().process_frame
	for q in 3:
		Settings.quality = q
		_settings_changed()
		await get_tree().process_frame
	for c in 3:
		Settings.crt = c
		_settings_changed()
	for b in Settings.CARD_BACKS.size():
		Settings.card_back = b
		_settings_changed()
		await get_tree().process_frame
	Settings.card_back = 0
	Settings.size = 2
	_settings_changed()
	_check(board.hand_card.x > RunScreen.HAND_CARD.x, "Large makes the cards bigger")
	Settings.size = 1
	Settings.quality = 2
	_settings_changed()
	sheet.close()
	var window := get_tree().root
	var old_size := window.size
	window.size = Vector2i(1688, 780)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(board.stage_w > 700.0, "a wide phone screen gets a wider stage (%d)" % board.stage_w)
	_check(_hand_view(board, 0) != null, "the hand is there after the resize")
	window.size = old_size
	await get_tree().process_frame


func _settings_changed() -> void:
	Feel.apply_settings()
	CardArt.clear()
	Feel.settings_changed.emit()


## Pause: Restart asks twice and starts over; Give up asks twice and ends the run; the end
## screen's New run starts another.
func _pause_menu(board: RunScreen) -> void:
	if Game.run.phase == RunState.Phase.LOST:
		_press_button(board.overlay, "New run")
	_check(Game.run.phase == RunState.Phase.CHOOSE_SHOW, "a run to pause (phase %d)" % Game.run.phase)
	var before := Game.run
	_key(KEY_ESCAPE)
	var pause := _top_sheet()
	_check(pause is PauseSheet, "Esc pauses")
	if not pause is PauseSheet:
		return
	pause._restart()
	_check(Game.run == before, "Restart asks first")
	pause._restart()
	_check(Game.run != before and Game.run.phase == RunState.Phase.CHOOSE_SHOW, "Restart starts the run over")
	await get_tree().process_frame
	_key(KEY_ESCAPE)
	pause = _top_sheet()
	pause._give_up()
	pause._give_up()
	_check(Game.run.phase == RunState.Phase.LOST, "Give up ends the run")
	_check(board.overlay.mouse_filter == Control.MOUSE_FILTER_STOP, "the end screen shows")
	_check(_has_text(board.overlay, "Towns reached"), "the end screen lists the run's numbers")
	_check(_has_text(board.overlay, "You gave up"), "the end screen says why the run ended")
	_press_button(board.overlay, "One more run")
	_check(Game.run.phase == RunState.Phase.CHOOSE_SHOW, "One more run starts another")


# --- input ---

func _key(keycode: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = keycode
	e.pressed = true
	get_viewport().push_input(e)
	var up := e.duplicate()
	up.pressed = false
	get_viewport().push_input(up)


func _press(at: Vector2) -> void:
	_mouse(at, true)


func _release(at: Vector2) -> void:
	_mouse(at, false)


func _click(at: Vector2) -> void:
	_mouse(at, true)
	_mouse(at, false)


func _mouse(at: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.position = at
	e.global_position = at
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	get_viewport().push_input(e, true)


func _move(at: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = at
	e.global_position = at
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(e, true)


# --- finding things ---

## The nth hand card as laid out (left to right).
func _hand_view(board: RunScreen, n: int) -> CardView:
	var views := board.hand_row.get_children().filter(func(c: Node) -> bool: return c is CardView and not c.is_queued_for_deletion())
	views.sort_custom(func(a: CardView, b: CardView) -> bool: return a.position.x < b.position.x)
	return views[n] if n < views.size() else null


func _top_sheet() -> Node:
	var host := UiTheme.sheet_host
	for i in range(host.get_child_count() - 1, -1, -1):
		var child := host.get_child(i)
		if child.has_signal("closed") and not child.is_queued_for_deletion():
			return child
	return null


func _has_text(node: Node, text: String) -> bool:
	if node is Label and (node as Label).text.contains(text):
		return true
	for child in node.get_children():
		if _has_text(child, text):
			return true
	return false


func _press_button(node: Node, text: String) -> bool:
	if node is Button and (node as Button).text.begins_with(text) and not node.is_queued_for_deletion():
		(node as Button).pressed.emit()
		return true
	for child in node.get_children():
		if _press_button(child, text):
			return true
	return false


func _step(board: RunScreen, action: Dictionary) -> void:
	var result := Game.act(action)
	_check(result["ok"], "%s: %s" % [action["a"], result.get("error", "")])
	board.refresh()


## A screen whose rect collapses still draws its children but not its full-screen backdrop.
func _check_fills(screen: Control, what: String) -> void:
	_check(screen.size == get_viewport().get_visible_rect().size, "%s fills the screen (size %s)" % [what, screen.size])


func _check(condition: bool, what: String) -> void:
	if not condition:
		push_error("UI SMOKE FAILED: " + what)
