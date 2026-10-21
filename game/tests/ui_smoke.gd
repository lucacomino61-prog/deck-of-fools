extends Node
## UI smoke test: drives the real screens through every phase of a run and rebuilds them
## at each step, so any script error in a screen shows up. Run with:
##   godot --headless --path game res://tests/ui_smoke.tscn
## Prints "UI SMOKE OK" on success (tools/test.ps1 also fails on any engine error line).


func _ready() -> void:
	seed(7)
	get_tree().create_timer(60.0).timeout.connect(func() -> void:
		push_error("UI SMOKE FAILED: timed out")
		get_tree().quit(1))
	var main: Control = load("res://ui/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	_check_fills(main.screens.get_child(0), "the menu")
	Game.new_run("d_bergamo", 1)
	var board := RunScreen.new()
	main.add_child(board)
	_check_fills(board, "the run screen")
	var run := Game.run
	_step(board, {"a": "select_show"})
	run.show_target = 1.0
	board.selected_hand.assign([run.hand[0].id, run.hand[1].id])
	board.refresh()
	board._on_play()
	while board.busy:
		await get_tree().create_timer(0.05).timeout
	_check(run.phase == RunState.Phase.CASH_OUT, "the show was won")
	_step(board, {"a": "cash_out"})
	run.ducats = 200
	board.selection = {"zone": "offer", "index": 0}
	board.refresh()
	_step(board, {"a": "buy", "slot": 0})
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
	Game.new_run("d_bergamo", 1)
	_check(Game.continue_run(), "a saved run continues")
	print("UI SMOKE OK")
	get_tree().quit()


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
