class_name CampaignSheet
extends Sheet
## The campaign, Il Lungo Giro (batch 13): the sixteen chapters around Italy on the left
## (cleared in gold, the next one lit, the rest still ahead), and the chosen chapter on the
## right: its city, the road there, its rule, its story Patron, the first-clear reward, the
## story so far, and a deck to set out with. Only the next chapter and cleared ones can be
## played; a cleared one plays again without its reward.

var on_start: Callable
var chosen := 1
var deck_index := 0


func _init(start: Callable) -> void:
	on_start = start
	title_text = "Il Lungo Giro"
	panel_size = Vector2(600, 344)
	wide = true
	chosen = mini(Game.profile.chapters_cleared + 1, CampaignCards.COUNT)


func _build() -> void:
	var cleared := Game.profile.chapters_cleared
	title_text = "Il Lungo Giro  -  %d of %d chapters" % [cleared, CampaignCards.COUNT]
	if not Game.profile.titles.is_empty():
		title_text += "  -  " + ", ".join(Game.profile.titles)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(row)

	var list := GridContainer.new()
	list.columns = 2
	list.add_theme_constant_override("h_separation", 3)
	list.add_theme_constant_override("v_separation", 3)
	row.add_child(list)
	for d in CampaignCards.chapters():
		var n := int(d.data["n"])
		var open := n <= cleared + 1
		var colour := UiTheme.GOLD.darkened(0.45) if n <= cleared else (UiTheme.MULT if n == cleared + 1 else UiTheme.PANEL_DARK)
		if n == chosen:
			colour = colour.lightened(0.25)
		var label := "%d  %s%s" % [n, UiTheme.name_of(d.id), "  OK" if n <= cleared else ""]
		var b := UiTheme.button(label, func() -> void:
			Feel.play("select")
			chosen = n
			rebuild(), 10, colour)
		b.custom_minimum_size = Vector2(_list_width(), 0)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if not open:
			b.modulate = Color(1, 1, 1, 0.55)
		list.add_child(b)

	row.add_child(_details(CampaignCards.chapters()[chosen - 1], cleared))


func _details(d: ContentDef, cleared: int) -> Control:
	var n := int(d.data["n"])
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	col.add_child(head)
	var card := CardView.new(Vector2(58, 81))
	card.kind = "city"
	card.def_id = str(d.data["city"])
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(card)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 1)
	head.add_child(names)
	names.add_child(UiTheme.label("Chapter %d of %d  -  Stake %d" % [n, CampaignCards.COUNT, int(d.data["stake"])], 8, UiTheme.MUTED))
	names.add_child(UiTheme.title(UiTheme.name_of(d.id), 16, UiTheme.GOLD))
	var road := "From %s to %s" % [UiTheme.name_of(d.data["start"]), UiTheme.name_of(d.data["city"])]
	if d.data["start"] == d.data["city"]:
		road = "Out from %s and back" % UiTheme.name_of(d.data["city"])
	names.add_child(UiTheme.label(road + ", 8 towns", 9, UiTheme.TEXT))
	var patron := str(d.data["patron"])
	var w := panel_size.x - 2.0 * _list_width() - 30.0
	names.add_child(_line("Waiting in town 8: %s" % UiTheme.name_of(patron), 10, UiTheme.MULT.lightened(0.3), w - 70.0))
	col.add_child(_line("Rule: " + UiTheme.text_of(d.id), 9, UiTheme.TEXT, w))
	var story := _line(TranslationServer.translate(d.id + ".before"), 9, Color("f3e3c0"), w)
	col.add_child(story)
	col.add_child(_line(_reward_text(d, n <= cleared), 9, UiTheme.GOLD, w))
	if n == cleared + 1 and not Game.profile.carry.is_empty():
		col.add_child(_line("Carried in from the last chapter: %s" % UiTheme.name_of(Game.profile.carry["id"]), 9, UiTheme.GOOD, w))

	if n > cleared + 1:
		col.add_child(_line("Clear chapter %d first." % (cleared + 1), 10, UiTheme.MUTED, w))
		return col
	var decks := _decks(d)
	deck_index = clampi(deck_index, 0, decks.size() - 1)
	var deck: String = decks[deck_index]
	var picker := HBoxContainer.new()
	picker.add_child(UiTheme.button("<", func() -> void: _cycle(-1, decks.size()), 10))
	var deck_name := UiTheme.label("Deck: %s%s" % [UiTheme.name_of(deck), " (suggested)" if deck == d.data["deck"] else ""], 10, UiTheme.TEXT)
	deck_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	picker.add_child(deck_name)
	picker.add_child(UiTheme.button(">", func() -> void: _cycle(1, decks.size()), 10))
	col.add_child(picker)
	var go := UiTheme.button("Set out" if n == cleared + 1 else "Play it again (no reward)", func() -> void:
		var start := on_start
		close()
		start.call(d.id, deck), 13, UiTheme.MULT)
	col.add_child(go)
	if Game.has_saved_run():
		col.add_child(UiTheme.label("Setting out ends the tour in progress.", 8, UiTheme.MUTED))
	return col


## Each chapter button in the two-column list.
func _list_width() -> float:
	return clampf(floorf(panel_size.x * 0.2), 124.0, 160.0)


func _cycle(step: int, count: int) -> void:
	Feel.play("select")
	deck_index = posmod(deck_index + step, count)
	rebuild()


## The unlocked decks, the chapter's suggestion first when it's open.
func _decks(d: ContentDef) -> Array:
	var open: Array = ContentDB.pool("deck").map(func(x: ContentDef) -> String: return x.id) \
		.filter(func(id: String) -> bool: return Game.profile.deck_unlocked(id))
	var suggested := str(d.data["deck"])
	if open.has(suggested):
		open.erase(suggested)
		open.push_front(suggested)
	return open


func _reward_text(d: ContentDef, done: bool) -> String:
	var reward: Dictionary = d.data["reward"]
	var parts := ["%d scudi" % int(reward.get("scudi", 0))]
	if reward.has("deck"):
		parts.append("the %s deck" % UiTheme.name_of(reward["deck"]))
	if reward.has("cosmetic"):
		parts.append(UiTheme.name_of(reward["cosmetic"]) + " for the Wagon")
	if reward.has("title"):
		parts.append("the title " + str(reward["title"]))
	return ("Cleared: " if done else "First clear: ") + ", ".join(parts)


func _line(text: String, font_size: int, colour: Color, width: float) -> Label:
	var l := UiTheme.label(text, font_size, colour)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	return l
