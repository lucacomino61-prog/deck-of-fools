class_name SeedSheet
extends Sheet
## Seeded run: type a seed (or roll one) to play an exact run with the deck and stake (or
## challenge) picked on the menu. The same seed and setup deal the same cards, shops and
## Patrons, so a run can be replayed or shared. Seeded runs don't count for leaderboards or
## unlocks (finding cards for the collection still does).

var start: Callable
var setup := ""
var _field: LineEdit
var _note: Label


## `on_start` gets the seed; `setup_text` names what will be played ("" if it's locked).
func _init(on_start: Callable, setup_text: String) -> void:
	start = on_start
	setup = setup_text
	title_text = "Seeded run"
	panel_size = Vector2(420, 236)


func _build() -> void:
	body.add_child(words("Play an exact run from its seed: the same seed with the same deck and stake deals the same cards, shops and Patrons. Replay a run you liked, or share one with a friend. Seeded runs don't count for leaderboards or unlocks.", 10, UiTheme.MUTED))
	body.add_child(pair("You'll play", setup if setup != "" else "a locked deck: pick another on the menu", UiTheme.GOLD if setup != "" else UiTheme.MULT))
	_field = field("A seed, like SK67HXC2")
	_field.max_length = 16
	_field.text_submitted.connect(func(_text: String) -> void: _play())
	body.add_child(_field)
	_note = UiTheme.label("Letters and numbers; the seed is shown in Run info and at the end of every run.", 9, UiTheme.MUTED)
	body.add_child(_note)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var roll := UiTheme.button("Random seed", func() -> void:
		Feel.play("reroll")
		_field.text = Game.random_seed(), 11)
	row.add_child(roll)
	var play := UiTheme.button("Play this seed", _play, 12, UiTheme.MULT)
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play.disabled = setup == ""
	row.add_child(play)
	body.add_child(row)


## The seed as typed, kept to capital letters and digits so it's easy to share.
func clean_seed(text: String) -> String:
	var out := ""
	for ch in text.to_upper():
		if (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9"):
			out += ch
	return out


func _play() -> void:
	var seed_text := clean_seed(_field.text)
	if seed_text == "" or setup == "":
		Feel.play("error")
		_note.text = "Type a seed first (or roll a random one)." if setup != "" else "Pick an unlocked deck on the menu first."
		_note.add_theme_color_override("font_color", UiTheme.MULT.lightened(0.3))
		return
	close()
	start.call(seed_text)
