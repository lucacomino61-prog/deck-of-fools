class_name MenuScreen
extends Control
## The title menu, compact and big, on the full width of the screen: the chosen deck's
## painting large on the left; beside it the deck (or challenge), the stake, each with what it
## does or how it unlocks, and a big Play; under Play, the tour in progress (or the campaign's
## next chapter) and the daily run; along the bottom one row of tiles for everything else.
## The player's name sits in the top right corner.

signal start

const PAD := 16.0
const TOP := 50.0
const CARD := Vector2(172, 241)
const TILE_Y := 316.0

var deck_ids: Array = []
var deck_index := 0
var stake := 1
var challenge_ids: Array = []
var challenge_index := 0
var mode := "deck"
## Today's daily run from the server, with this player's attempt (empty until it arrives).
var daily_info: Dictionary = {}
## Play was pressed once while a tour is saved: the next press replaces it.
var _confirm_new := false
## The menu's first build plays its entrance; rebuilds (cycling a deck…) don't.
var _shown := false
## The way the deck card slides in after cycling (-1, 0, 1).
var _slide := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deck_ids = ContentDB.pool("deck").map(func(d: ContentDef) -> String: return d.id)
	challenge_ids = ContentDB.pool("challenge").map(func(d: ContentDef) -> String: return d.id)
	_build()
	Online.account_changed.connect(_on_account_changed)
	Feel.settings_changed.connect(func() -> void:
		if is_inside_tree():
			_build())
	get_viewport().size_changed.connect(func() -> void:
		if is_inside_tree():
			_build())
	_fetch_daily()
	# Back from a cleared chapter: the campaign again, and the first time the Wagon too.
	if Game.open_campaign:
		Game.open_campaign = false
		UiTheme.show_sheet(CampaignSheet.new(_start_chapter))
		if not Game.profile.wagon_seen:
			Game.profile.wagon_seen = true
			Game.save_profile()
			UiTheme.show_sheet(WagonSheet.new("Your troupe's wagon! Spend the scudi every run earns on props, cosmetics and early unlocks."))
		return
	# After the first run, a guest is offered an account once.
	if Game.first_run_finished() and Online.signed_in() and Online.is_guest() and not Settings.asked_account:
		Settings.asked_account = true
		Settings.save()
		_open(AccountSheet.new("signup", "You finished your first run! Create an account so your runs, unlocks and cards are kept safe and follow you to any device."))


func _on_account_changed() -> void:
	if is_inside_tree():
		_build()
		_fetch_daily()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	Feel.backdrop(bg)
	Feel.mood("menu")
	var w := UiTheme.wide_width(self, 860.0)
	var stage := UiTheme.wide_stage(self, 860.0)

	var logo := UiTheme.title("DECK OF FOOLS", 26, UiTheme.GOLD)
	logo.position = Vector2(PAD, 8)
	stage.add_child(logo)
	_build_account_chip(stage, w)

	var card := _build_card(stage)
	var right := _build_setup(stage, w)
	var tiles := _build_tiles(stage, w)
	if not _shown:
		_shown = true
		_enter([card, right, tiles])
	elif _slide != 0:
		_slide_in(card, _slide)
	_slide = 0


# --- the deck card ---

## The deck (or the challenge's deck) as a big painted card on the left; a locked one dimmed.
func _build_card(stage: Control) -> Control:
	var v := CardView.new(CARD)
	v.kind = "deck"
	v.def_id = _shown_deck()
	v.dimmed = _locked()
	v.position = Vector2(PAD, TOP + 2)
	v.sway = 1
	v.tapped.connect(func(_view: CardView) -> void: _cycle(1))
	stage.add_child(v)
	return v


func _shown_deck() -> String:
	if mode == "deck":
		return deck_ids[deck_index]
	return str(ContentDB.get_def(challenge_ids[challenge_index]).data.get("deck", deck_ids[0]))


func _locked() -> bool:
	if mode == "deck":
		return not Game.profile.deck_unlocked(deck_ids[deck_index])
	return not Game.profile.challenge_unlocked(challenge_ids[challenge_index])


# --- beside it: deck, stake, Play, then Continue and the daily run ---

func _build_setup(stage: Control, w: float) -> Control:
	var x := PAD + CARD.x + 16.0
	var cw := w - x - PAD
	var col := VBoxContainer.new()
	col.position = Vector2(x, TOP)
	col.size = Vector2(cw, 0)
	col.add_theme_constant_override("separation", 4)
	stage.add_child(col)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	tabs.add_child(_tab("New run", "deck"))
	tabs.add_child(_tab("Challenges", "challenge"))
	var count := UiTheme.label(_count_text(), 10, UiTheme.MUTED)
	count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tabs.add_child(count)
	col.add_child(tabs)

	var locked := _locked()
	var id: String = deck_ids[deck_index] if mode == "deck" else challenge_ids[challenge_index]
	col.add_child(_picker(UiTheme.name_of(id), 24, _cycle, locked))
	var about := UiTheme.text_of(id)
	if locked:
		about = _deck_lock_reason(id) if mode == "deck" else _challenge_lock_reason()
	col.add_child(_words(about, 12, UiTheme.MULT.lightened(0.35) if locked else UiTheme.TEXT, cw, 30))

	if mode == "deck" and not locked:
		var top := Game.profile.max_stake(id)
		stake = clampi(stake, 1, top)
		var stake_def: ContentDef = ContentDB.pool("stake")[stake - 1]
		col.add_child(_picker("Stake %d: %s" % [stake, UiTheme.name_of(stake_def.id)], 16, _stake, false))
		var stake_words := UiTheme.text_of(stake_def.id)
		if top < Unlocks.TOP_STAKE and stake == top:
			stake_words += ". Win here to open Stake %d." % (top + 1)
		col.add_child(_words(stake_words, 11, UiTheme.MUTED, cw, 15))
	elif mode == "challenge":
		var deck := str(ContentDB.get_def(id).data.get("deck", ""))
		col.add_child(_words("Deck: %s. %s" % [UiTheme.name_of(deck), UiTheme.text_of(deck)], 11, UiTheme.MUTED, cw, 36))

	var play_text := "Locked" if locked else ("Play" if not _confirm_new else "Replace your saved tour?")
	var play := UiTheme.button(play_text, _on_start, 22 if not _confirm_new else 15, UiTheme.MULT)
	play.add_theme_font_override("font", UiTheme.title_font)
	play.disabled = locked
	play.custom_minimum_size = Vector2(cw, 44)
	col.add_child(play)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size = Vector2(cw, 0)
	row.add_child(_tour_card())
	row.add_child(_daily_card())
	col.add_child(row)
	return col


func _count_text() -> String:
	if mode == "deck":
		return "%d of %d decks unlocked" % [deck_ids.filter(func(d: String) -> bool: return Game.profile.deck_unlocked(d)).size(), deck_ids.size()]
	return "%d of %d challenges unlocked" % [challenge_ids.filter(func(c: String) -> bool: return Game.profile.challenge_unlocked(c)).size(), challenge_ids.size()]


## The tour in progress with Continue; without one, the campaign's next chapter.
func _tour_card() -> Control:
	var saved := Game.peek_saved_run()
	if saved != null:
		var chapter := ContentDB.get_def(saved.chapter)
		var heading := "Tour in progress" if chapter == null else "Chapter %d in progress" % int(chapter.data["n"])
		var what := UiTheme.name_of(saved.challenge) if saved.challenge != "" else "%s, Stake %d" % [UiTheme.name_of(saved.deck_id), saved.stake]
		var info := "Town %d, %s.  %s" % [saved.town, RunScreen.SHOW_NAMES[saved.show_index], what]
		return _card(heading, info, "Continue", _on_continue, UiTheme.POINTS)
	var cleared := Game.profile.chapters_cleared
	if cleared >= CampaignCards.COUNT:
		return _card("Il Lungo Giro", "All %d chapters cleared. Play any again." % CampaignCards.COUNT, "Open", func() -> void: _open(CampaignSheet.new(_start_chapter)), UiTheme.GOLD.darkened(0.35))
	var next := CampaignCards.chapters()[cleared]
	return _card("Campaign", "Chapter %d: %s" % [cleared + 1, UiTheme.name_of(next.id)], "Set out", func() -> void: _open(CampaignSheet.new(_start_chapter)), UiTheme.GOLD.darkened(0.35))


## The daily run: today's deck for everyone, one ranked try (it needs the server) and
## unlimited practice.
func _daily_card() -> Control:
	var setup := Online.daily_setup()
	var attempt: Variant = daily_info.get("attempt")
	var ranked_text := "Ranked"
	var can_rank := Online.online and Online.signed_in() and not daily_info.is_empty()
	if attempt is Dictionary:
		can_rank = false
		ranked_text = "Town %d" % int(attempt["town"]) if bool(attempt["finished"]) else "Started"
	var box := _box(UiTheme.GOOD.darkened(0.3))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 0)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_child(UiTheme.title("Daily run", 13, UiTheme.GOLD))
	words.add_child(UiTheme.label("%s, Stake 1%s" % [UiTheme.name_of(setup["deck"]), "" if can_rank or attempt is Dictionary else ". Offline"], 10, UiTheme.MUTED))
	row.add_child(words)
	var ranked := UiTheme.button(ranked_text, _start_daily.bind(true), 11, UiTheme.MULT)
	ranked.disabled = not can_rank
	ranked.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ranked)
	var practice := UiTheme.button("Practice", _start_daily.bind(false), 11, UiTheme.PANEL_LIGHT)
	practice.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(practice)
	return box.get_parent()


## A small card: a heading, one line about it and one button on the right.
func _card(heading: String, info: String, action: String, on_press: Callable, colour: Color) -> Control:
	var box := _box(colour)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 0)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_child(UiTheme.title(heading, 13, UiTheme.GOLD))
	var l := UiTheme.label(info, 10, UiTheme.MUTED)
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.custom_minimum_size = Vector2(60, 0)
	words.add_child(l)
	row.add_child(words)
	var b := UiTheme.button(action, on_press, 12, colour)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(b)
	return box.get_parent()


func _box(border: Color) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_box(Color(UiTheme.PANEL, 0.94), border))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.0
	var inner := VBoxContainer.new()
	panel.add_child(inner)
	return inner


func _tab(text: String, tab_mode: String) -> Button:
	var b := UiTheme.button(text, func() -> void:
		Feel.play("click")
		mode = tab_mode
		_confirm_new = false
		_build(), 11, UiTheme.GOLD.darkened(0.35) if mode == tab_mode else UiTheme.PANEL_DARK)
	b.custom_minimum_size = Vector2(96, 0)
	return b


## A name in display type, with its < and > arrows together on the right.
func _picker(text: String, font_size: int, step: Callable, locked: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var name_label := UiTheme.title(("Locked: " if locked else "") + text, font_size, UiTheme.MUTED if locked else UiTheme.TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(name_label)
	for arrow in [["<", -1], [">", 1]]:
		var b := UiTheme.button(arrow[0], func() -> void: step.call(arrow[1]), 13)
		b.custom_minimum_size = Vector2(34, 0)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(b)
	return row


func _words(text: String, font_size: int, colour: Color, width: float, min_height := 0.0) -> Label:
	var l := UiTheme.label(text, font_size, colour)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, min_height)
	return l


func _deck_lock_reason(id: String) -> String:
	var parts := str(Unlocks.DECK_RULES.get(id, "")).split(":")
	if parts[0] == "discover":
		return "Locked. Discover %s different cards across your runs (you have %d), or buy it in the Wagon." % [parts[1], Game.profile.discovered.size()]
	return "Locked. Win a run with %s, or buy it in the Wagon." % UiTheme.name_of(parts[1])


func _challenge_lock_reason() -> String:
	var wins_needed := challenge_index / Unlocks.CHALLENGES_PER_WIN + 1 - Game.profile.total_wins
	return "Locked. Win %d more run%s, or buy it in the Wagon." % [wins_needed, "" if wins_needed == 1 else "s"]


# --- along the bottom: everything else ---

func _build_tiles(stage: Control, w: float) -> Control:
	var row := HBoxContainer.new()
	row.position = Vector2(PAD, TILE_Y)
	row.size = Vector2(w - 2.0 * PAD, 30)
	row.add_theme_constant_override("separation", 5)
	stage.add_child(row)
	var entries := [
		["Wagon  %d" % Game.profile.scudi, func() -> void: _open(WagonSheet.new()), UiTheme.GOLD.darkened(0.4)],
		["Collection", func() -> void: _open(CollectionSheet.new()), UiTheme.POINTS.darkened(0.2)],
		["Profile", func() -> void: _open(ProfileSheet.new()), UiTheme.POINTS.darkened(0.2)],
		["Leaderboards", func() -> void: _open(LeaderboardSheet.new()), UiTheme.POINTS.darkened(0.2)],
		["How to play", func() -> void: _open(HowToPlay.new()), UiTheme.POINTS.darkened(0.2)],
		["Seeded run", func() -> void: _open(SeedSheet.new(_start_seeded, _setup_text())), UiTheme.POINTS.darkened(0.2)],
		["Settings", func() -> void: _open(SettingsSheet.new()), UiTheme.PANEL_LIGHT],
	]
	# With a tour saved the Campaign card isn't shown above, so it gets a tile.
	if Game.has_saved_run():
		entries.push_front(["Campaign", func() -> void: _open(CampaignSheet.new(_start_chapter)), UiTheme.GOLD.darkened(0.4)])
	# The longest label ("Leaderboards") fits on one line at every width.
	var tile_w := (row.size.x - 5.0 * (entries.size() - 1)) / entries.size()
	var font_size := 11 if tile_w >= 96.0 else (10 if tile_w >= 80.0 else 9)
	for e in entries:
		var b := UiTheme.button(e[0], e[1], font_size, e[2])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 30)
		b.clip_text = true
		row.add_child(b)
	return row


## The player's name in the corner: tap it for the profile.
func _build_account_chip(stage: Control, w: float) -> void:
	var name_text := str(Online.user.get("name", "Offline")) if Online.signed_in() else "Offline"
	var label := name_text + ("  -  save progress" if Online.signed_in() and Online.is_guest() else "")
	var chip := UiTheme.button(label, func() -> void: _open(ProfileSheet.new()), 10, UiTheme.PANEL_DARK)
	chip.clip_text = true
	chip.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	chip.position = Vector2(w - PAD - 200, 12)
	chip.custom_minimum_size = Vector2(200, 22)
	chip.size = Vector2(200, 22)
	chip.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stage.add_child(chip)


# --- motion ---

## The menu's arrival: the card, the setup and the tiles rise in one after another (fast,
## ease-out); opacity only for the tiles, which are tap targets.
func _enter(groups: Array) -> void:
	if Settings.reduce_motion:
		return
	for i in groups.size():
		var node: Control = groups[i]
		var to := node.position
		node.modulate.a = 0.0
		if i < 2:
			node.position.y += 10.0
		var t := node.create_tween().set_parallel()
		t.tween_property(node, "modulate:a", 1.0, 0.32).set_delay(i * 0.06).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		if i < 2:
			t.tween_property(node, "position:y", to.y, 0.32).set_delay(i * 0.06).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


## After cycling, the new deck slides in from the side it came from.
func _slide_in(card: Control, direction: int) -> void:
	if Settings.reduce_motion:
		return
	var to := card.position.x
	card.position.x += 14.0 * direction
	card.modulate.a = 0.0
	var t := card.create_tween().set_parallel()
	t.tween_property(card, "position:x", to, 0.18).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	t.tween_property(card, "modulate:a", 1.0, 0.14)


# --- actions ---

## Fetches today's daily run and this player's attempt, then redraws.
func _fetch_daily() -> void:
	var res := await Online.daily()
	if res["ok"] and is_inside_tree():
		daily_info = res["data"]
		_build()


func _start_daily(ranked: bool) -> void:
	var setup := Online.daily_setup()
	var meta := {"daily_date": setup["date"]}
	if ranked:
		var res := await Online.start_daily()
		if not res["ok"]:
			Feel.play("error")
			_fetch_daily()
			return
		setup = res["data"]
		meta["daily_date"] = setup["date"]
	else:
		meta["practice"] = true
	Feel.play("play")
	Game.new_run(str(setup["deck"]), int(setup["stake"]), "", str(setup["seed"]), meta)
	start.emit()


func _open(sheet: Control) -> void:
	Feel.play("click")
	UiTheme.show_sheet(sheet)


func _cycle(step: int) -> void:
	Feel.play("select")
	_confirm_new = false
	_slide = step
	if mode == "deck":
		deck_index = posmod(deck_index + step, deck_ids.size())
	else:
		challenge_index = posmod(challenge_index + step, challenge_ids.size())
	_build()


func _stake(step: int) -> void:
	Feel.play("select")
	stake = clampi(stake + step, 1, Game.profile.max_stake(deck_ids[deck_index]))
	_build()


## Play; with a tour saved, the first press asks (it would end that tour) and the second starts.
func _on_start() -> void:
	if Game.has_saved_run() and not _confirm_new:
		Feel.play("click")
		_confirm_new = true
		_build()
		return
	_confirm_new = false
	Feel.play("play")
	if mode == "deck":
		Game.new_run(deck_ids[deck_index], stake)
	else:
		Game.new_run("", 1, challenge_ids[challenge_index])
	start.emit()


## What the left panel has picked, for the Seeded run sheet ("" when the deck is locked).
func _setup_text() -> String:
	if mode != "deck":
		var challenge: String = challenge_ids[challenge_index]
		return "Challenge: " + UiTheme.name_of(challenge) if Game.profile.challenge_unlocked(challenge) else ""
	var deck: String = deck_ids[deck_index]
	if not Game.profile.deck_unlocked(deck):
		return ""
	return "%s deck, Stake %d" % [UiTheme.name_of(deck), stake]


## A run from a typed seed, with the deck and stake (or the challenge) picked on the left.
## It doesn't count for leaderboards or unlocks.
func _start_seeded(seed_text: String) -> void:
	Feel.play("play")
	if mode == "deck":
		Game.new_run(deck_ids[deck_index], stake, "", seed_text, {"seeded": true})
	else:
		Game.new_run("", 1, challenge_ids[challenge_index], seed_text, {"seeded": true})
	start.emit()


## A campaign chapter, from the Campaign sheet.
func _start_chapter(chapter_id: String, deck_id: String) -> void:
	Feel.play("play")
	Game.start_chapter(chapter_id, deck_id)
	start.emit()


func _on_continue() -> void:
	Feel.play("play")
	if Game.continue_run():
		start.emit()
