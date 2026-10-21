class_name PauseSheet
extends Sheet
## The run, paused: Resume, Run info, Settings, How to play, Restart the run, Give up, or
## save and quit to the menu (the run waits there under Continue). Restart and Give up ask
## for a second tap, so they can't happen by accident.

var board: RunScreen
var _confirm := ""


func _init(run_screen: RunScreen) -> void:
	board = run_screen
	title_text = "Paused"
	panel_size = Vector2(300, 336)


func _build() -> void:
	var run := Game.run
	if run != null:
		var where := "Town %d - %s" % [run.town, RunScreen.SHOW_NAMES[run.show_index]]
		var what := UiTheme.name_of(run.challenge) if run.challenge != "" else "%s, Stake %d" % [UiTheme.name_of(run.deck_id), run.stake]
		body.add_child(words("%s\n%s" % [where, what], 10, UiTheme.MUTED))
	body.add_child(_wide(UiTheme.button("Resume", close, 14, UiTheme.POINTS)))
	body.add_child(_wide(UiTheme.button("Run info: hands and deck", func() -> void: _open(RunInfoSheet.new()), 11)))
	body.add_child(_wide(UiTheme.button("Settings", func() -> void: _open(SettingsSheet.new()), 11)))
	body.add_child(_wide(UiTheme.button("How to play", func() -> void: _open(HowToPlay.new()), 11)))
	var restart_text := "Tap again: restart this run" if _confirm == "restart" else "Restart the run"
	body.add_child(_wide(UiTheme.button(restart_text, _restart, 11, UiTheme.GOLD.darkened(0.35) if _confirm == "restart" else Color.TRANSPARENT)))
	var give_text := "Tap again: give up (counts as lost)" if _confirm == "give_up" else "Give up"
	body.add_child(_wide(UiTheme.button(give_text, _give_up, 11, UiTheme.MULT.darkened(0.3) if _confirm == "give_up" else Color.TRANSPARENT)))
	body.add_child(_wide(UiTheme.button("Save and quit to menu", func() -> void:
		close()
		board.back_to_menu.emit(), 11)))


func _wide(b: Button) -> Button:
	b.custom_minimum_size = Vector2(0, 26)
	return b


func _open(sheet: Control) -> void:
	Feel.play("click")
	UiTheme.show_sheet(sheet)


func _restart() -> void:
	if _confirm != "restart":
		Feel.play("error")
		_confirm = "restart"
		rebuild()
		return
	Feel.play("play")
	Game.restart()
	close()
	board.restart()


func _give_up() -> void:
	if _confirm != "give_up":
		Feel.play("error")
		_confirm = "give_up"
		rebuild()
		return
	Feel.play("lose")
	Game.give_up()
	close()
	board.refresh()
