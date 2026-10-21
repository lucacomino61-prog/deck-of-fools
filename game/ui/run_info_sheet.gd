class_name RunInfoSheet
extends Sheet
## What the run holds, in three tabs:
##   Poker hands: each hand with its level, its Points x Mult now, and how often it's been played.
##   Deck: the cards still to draw, as a grid of suits by ranks (the deck tracker).
##   Run: the deck and stake and their rules, this town's Patron, the Warrants, the seed.

const SUIT_ORDER := [PlayingCard.Suit.SPADES, PlayingCard.Suit.HEARTS, PlayingCard.Suit.CLUBS, PlayingCard.Suit.DIAMONDS]
const RANKS := [14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2]

var tab := "hands"


func _init(start := "hands") -> void:
	tab = start
	title_text = "Run info"
	panel_size = Vector2(500, 340)


func _build() -> void:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	for t in [["hands", "Poker hands"], ["deck", "Deck"], ["run", "Run"]]:
		var b := UiTheme.button(t[1], func() -> void:
			Feel.play("click")
			tab = t[0]
			rebuild(), 10, UiTheme.PANEL_LIGHT.lightened(0.15) if tab == t[0] else UiTheme.PANEL_DARK)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
	body.add_child(tabs)
	var run := Game.run
	if run == null:
		return
	match tab:
		"hands":
			_build_hands(run)
		"deck":
			_build_deck(run)
		"run":
			_build_run(run)


func _build_hands(run: RunState) -> void:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 1)
	for heading in ["Hand", "Level", "Points x Mult", "Played"]:
		grid.add_child(UiTheme.label(heading, 9, UiTheme.MUTED))
	for hand_type in HandTable.ORDER:
		if not run.hand_levels.is_visible(hand_type):
			continue
		var name_label := UiTheme.label(TranslationServer.translate("hand." + hand_type), 10, UiTheme.TEXT)
		name_label.custom_minimum_size = Vector2(150, 0)
		grid.add_child(name_label)
		var level := run.hand_levels.level(hand_type)
		grid.add_child(UiTheme.label("lv.%d" % level, 10, UiTheme.GOLD if level > 1 else UiTheme.TEXT))
		var pm := HBoxContainer.new()
		pm.add_child(UiTheme.label(UiTheme.number(run.hand_levels.points(hand_type)), 10, UiTheme.POINTS.lightened(0.3)))
		pm.add_child(UiTheme.label(" x ", 10, UiTheme.MUTED))
		pm.add_child(UiTheme.label(UiTheme.number(run.hand_levels.mult(hand_type)), 10, UiTheme.MULT.lightened(0.2)))
		grid.add_child(pm)
		grid.add_child(UiTheme.label(str(run.hand_levels.times_played(hand_type)), 10, UiTheme.MUTED))
	body.add_child(grid)


## The deck tracker: how many of each card are still in the draw pile.
func _build_deck(run: RunState) -> void:
	var counts := {}
	for c in run.draw_pile:
		var key := "%d %d" % [c.suit, c.rank]
		counts[key] = int(counts.get(key, 0)) + 1
	var stone := run.draw_pile.filter(func(c: PlayingCard) -> bool: return not c.has_rank()).size()
	body.add_child(UiTheme.label("Still to draw: %d of %d cards%s" % [run.draw_pile.size(), run.full_deck.size(), ", %d Marble" % stone if stone > 0 else ""], 10, UiTheme.TEXT))
	var grid := GridContainer.new()
	grid.columns = RANKS.size() + 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 3)
	grid.add_child(Control.new())
	for rank in RANKS:
		grid.add_child(_cell(str(RunScreen.RANK_SHORT.get(rank, rank)), UiTheme.MUTED))
	grid.add_child(_cell("All", UiTheme.MUTED))
	for suit in SUIT_ORDER:
		grid.add_child(_suit_icon(suit))
		var total := 0
		for rank in RANKS:
			var n := int(counts.get("%d %d" % [suit, rank], 0))
			total += n
			grid.add_child(_cell(str(n) if n > 0 else "-", UiTheme.TEXT if n > 0 else UiTheme.MUTED.darkened(0.3)))
		grid.add_child(_cell(str(total), UiTheme.GOLD))
	body.add_child(grid)
	var enhanced := run.draw_pile.filter(func(c: PlayingCard) -> bool: return c.enhancement != "" or c.edition != "" or c.seal != "").size()
	body.add_child(UiTheme.label("Special cards still to draw: %d (enhanced, with an edition, or sealed)" % enhanced, 9, UiTheme.MUTED))


func _cell(text: String, colour: Color) -> Label:
	var l := UiTheme.label(text, 10, colour)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(16, 0)
	return l


func _suit_icon(suit: int) -> Control:
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(16, 14)
	var colour := UiTheme.RED_SUIT.lightened(0.25) if suit == PlayingCard.Suit.HEARTS or suit == PlayingCard.Suit.DIAMONDS else UiTheme.TEXT
	icon.draw.connect(func() -> void: CardView.draw_suit(icon, Vector2(8, 7), 5.0, suit, colour))
	return icon


func _build_run(run: RunState) -> void:
	var lines := []
	if run.challenge != "":
		lines.append(["Challenge", "%s: %s" % [UiTheme.name_of(run.challenge), UiTheme.text_of(run.challenge)]])
	lines.append(["Deck", "%s: %s" % [UiTheme.name_of(run.deck_id), UiTheme.text_of(run.deck_id)]])
	var stake_def: ContentDef = ContentDB.pool("stake")[run.stake - 1]
	lines.append(["Stake", "%d, %s: %s" % [run.stake, UiTheme.name_of(stake_def.id), UiTheme.text_of(stake_def.id)]])
	if run.town_patron != "":
		lines.append(["This town's Patron", "%s: %s" % [UiTheme.name_of(run.town_patron), UiTheme.text_of(run.town_patron)]])
	if not run.warrants.is_empty():
		lines.append(["Warrants", ", ".join(run.warrants.map(func(w: String) -> String: return UiTheme.name_of(w)))])
	lines.append(["Seed", run.seed_text + ("  (daily run)" if Game.run_meta.has("daily_date") else "")])
	for line in lines:
		body.add_child(UiTheme.label(line[0], 9, UiTheme.MUTED))
		body.add_child(words(line[1], 10, UiTheme.TEXT))
