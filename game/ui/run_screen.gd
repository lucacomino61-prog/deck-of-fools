class_name RunScreen
extends Control
## The run, in landscape, 360 tall and as wide as the screen allows (up to 920): the left
## panel (town, target, score, Points × Mult, counters, what you tapped, Pause / Run info /
## help), Jesters and consumables on top, the middle area for the current phase (choosing a
## show, scoring, cash-out, shop, pack), the hand at the bottom and the action buttons.
## Cards: tap to select, hold for details, drag sideways to reorder, flick up to play or
## down to discard. Keys: Enter plays, D discards, S sorts, 1–8 pick cards, I run info,
## Esc pauses; a tap or key during scoring skips to the result.
## Every change goes through Game.act().

signal back_to_menu

const SHOW_NAMES := ["Matinee", "Evening show", "Patron"]
const SHOW_COLOURS := [Color("3f8ed8"), Color("2e9c8f"), Color("e0503c")]
const SUITS := ["Spades", "Hearts", "Clubs", "Diamonds"]
const RANK_NAMES := {11: "Jack", 12: "Queen", 13: "King", 14: "Ace"}
const RANK_SHORT := {11: "J", 12: "Q", 13: "K", 14: "A"}
const AREA_X := 156.0
## Card sizes at Normal; Text & card size and the room on screen scale them.
const HAND_CARD := Vector2(66, 92)
const JESTER_CARD := Vector2(54, 76)
const ITEM_CARD := Vector2(48, 66)
const SHOP_CARD := Vector2(60, 84)
const MAX_STAGE_WIDTH := 920.0
## The sound each action makes when it goes through.
## (A discard sounds as its cards fly away; the refill sounds as it's dealt.)
const ACTION_CUES := {
	"select_show": "show", "skip_show": "discard", "cash_out": "cash", "buy": "buy",
	"buy_warrant": "buy", "buy_pack": "pack", "pick": "deal", "skip_pack": "click",
	"sell": "sell", "use": "pack", "reroll": "reroll", "leave_shop": "click",
	"swap_patron": "reroll", "reorder_zanni": "deal",
}
## What each kind of card is, under its own text when it's tapped.
const KIND_HELP := {
	"zanni": "Jester: stays with you and works on every hand. Slots are limited (top left); sell one to make room.",
	"tarocchi": "Tarocchi: a one-use card. If it changes cards, select them in your hand first, then tap Use.",
	"sign": "Sign: a one-use card that levels up a poker hand, so it scores more from now on.",
	"omen": "Omen: a powerful one-use card.",
	"pack": "Pack: buy it to open it, then choose the cards you keep.",
	"warrant": "Warrant: a lasting upgrade for the rest of the run.",
}
## Each event of type… plays this sound while the score is replayed.
const EVENT_CUES := {
	"points": "points", "mult": "mult", "xmult": "xmult", "ducats": "buy", "swap": "reroll",
	"not_allowed": "error", "shattered": "discard",
}

var run: RunState:
	get:
		return Game.run

var selected_hand: Array[int] = []
## What's selected outside the hand: {zone: zanni|consumable|offer|pack|warrant|pack_item, index}.
var selection: Dictionary = {}
var sort_by := "rank"
var busy := false
var held_while_scoring: Array = []
## Where each hand card was last laid out (card id → position), so the next layout can
## glide cards from there and deal in the ones that are new.
var hand_layout: Dictionary = {}
var message := ""

## The layout, worked out from the screen in _layout().
var stage_w := 640.0
var area_w := 480.0
var hand_card := HAND_CARD
var jester_card := JESTER_CARD
var item_card := ITEM_CARD
## Hand cards in the player's own order, after dragging (sort_by "custom").
var custom_order: Array[int] = []
## True while a played hand is being scored; a tap or key then fast-forwards it (skipping).
var scoring := false
var skipping := false
## What Enter does right now (the main button), or nothing.
var primary := Callable()

var stage: Control
var lbl_place: Label
var lbl_target_caption: Label
var lbl_target: Label
var lbl_score: Label
var lbl_hand: Label
var lbl_points: Label
var lbl_mult: Label
var lbl_hands: Label
var lbl_discards: Label
var lbl_ducats: Label
var info_name: Label
var info_text: Label
var top_row: Control
var middle: Control
var hand_row: Control
var buttons: HBoxContainer
var overlay: Control
## The big card shown under a tapped Jester or one-use card.
var tip: Control
## The first-run guide's tip card.
var coach: Control
var jester_views: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_screen()
	Game.changed.connect(refresh)
	Feel.settings_changed.connect(_rebuild_screen)
	get_viewport().size_changed.connect(_rebuild_screen)
	refresh()
	if not Settings.seen_help and Settings.tutorial_step < 0:
		UiTheme.show_sheet(HowToPlay.new())


func _exit_tree() -> void:
	Engine.time_scale = 1.0


## Works out the layout from the room on screen and the Text & card size setting: the
## stage is 360 tall and as wide as the screen (640 to 920); phones get bigger cards.
func _layout() -> void:
	var room := get_viewport_rect().size.x - 8.0
	stage_w = clampf(room, 640.0, MAX_STAGE_WIDTH)
	area_w = stage_w - AREA_X - 4.0
	var k := Settings.card_scale()
	var widen := clampf(area_w / 480.0, 1.0, 1.15)
	hand_card = (HAND_CARD * k * widen).floor()
	hand_card.y = minf(hand_card.y, 108.0)
	jester_card = (JESTER_CARD * minf(k, 1.0)).floor()
	item_card = (ITEM_CARD * minf(k, 1.06)).floor()


func _build_screen() -> void:
	_layout()
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	Feel.backdrop(bg)
	stage = Control.new()
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.set_anchors_preset(Control.PRESET_CENTER)
	stage.offset_left = -stage_w / 2.0
	stage.offset_right = stage_w / 2.0
	stage.offset_top = -180.0
	stage.offset_bottom = 180.0
	add_child(stage)
	_build_side()
	top_row = _area(Vector2(AREA_X, 4), Vector2(area_w, 80))
	middle = _area(Vector2(AREA_X, 86), Vector2(area_w, 104))
	hand_row = _area(Vector2(AREA_X, 190), Vector2(area_w, 134))
	buttons = HBoxContainer.new()
	buttons.position = Vector2(AREA_X, 326)
	buttons.size = Vector2(area_w, 30)
	buttons.add_theme_constant_override("separation", 6)
	stage.add_child(buttons)
	tip = Control.new()
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(tip)
	coach = Control.new()
	coach.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(coach)
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)


## After a resize or a settings change: build the screen again at the new size.
func _rebuild_screen() -> void:
	if busy or not is_inside_tree():
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	hand_layout = {}
	_build_screen()
	refresh()


## After the pause menu restarts the run.
func restart() -> void:
	selected_hand.clear()
	selection = {}
	custom_order.clear()
	hand_layout = {}
	refresh()


func _area(pos: Vector2, area_size: Vector2) -> Control:
	var c := Control.new()
	c.position = pos
	c.size = area_size
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	stage.add_child(c)
	return c


func _build_side() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(4, 4)
	panel.size = Vector2(146, 352)
	stage.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)
	lbl_place = UiTheme.label("", 11, UiTheme.GOLD)
	lbl_place.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(lbl_place)
	var target := _block(col, UiTheme.PANEL_DARK, UiTheme.GOLD.darkened(0.35))
	lbl_target_caption = UiTheme.label("", 8, UiTheme.MUTED)
	target.add_child(lbl_target_caption)
	lbl_target = UiTheme.title("", 16, UiTheme.GOLD)
	target.add_child(lbl_target)
	var score := _block(col, UiTheme.PANEL_DARK, UiTheme.PANEL_LIGHT)
	score.add_child(UiTheme.label("Show score", 8, UiTheme.MUTED))
	lbl_score = UiTheme.title("0", 18, UiTheme.TEXT)
	score.add_child(lbl_score)
	lbl_hand = UiTheme.title("", 12, UiTheme.TEXT)
	lbl_hand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_hand.custom_minimum_size = Vector2(0, 16)
	col.add_child(lbl_hand)
	var pm := HBoxContainer.new()
	pm.add_theme_constant_override("separation", 2)
	lbl_points = _score_box(UiTheme.POINTS)
	lbl_mult = _score_box(UiTheme.MULT)
	pm.add_child(lbl_points.get_parent())
	var times := UiTheme.title("x", 14, UiTheme.TEXT)
	pm.add_child(times)
	pm.add_child(lbl_mult.get_parent())
	col.add_child(pm)
	var counters := HBoxContainer.new()
	counters.add_theme_constant_override("separation", 3)
	lbl_hands = _counter(counters, "Hands", UiTheme.POINTS)
	lbl_discards = _counter(counters, "Discards", UiTheme.MULT)
	lbl_ducats = _counter(counters, "Ducats", UiTheme.GOLD)
	col.add_child(counters)
	var info := _block(col, UiTheme.PANEL_DARK, UiTheme.PANEL_LIGHT)
	info.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_name = UiTheme.label("", 10, UiTheme.GOLD)
	info_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_name.custom_minimum_size = Vector2(122, 0)
	info_text = UiTheme.label("", 10)
	info_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_text.custom_minimum_size = Vector2(122, 0)
	info.add_child(info_name)
	info.add_child(info_text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	var pause := UiTheme.button("Pause", _pause, 11, UiTheme.PANEL_LIGHT)
	pause.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(pause)
	row.add_child(UiTheme.button("Info", func() -> void: _open(RunInfoSheet.new()), 11, UiTheme.POINTS.darkened(0.15)))
	row.add_child(UiTheme.button("?", func() -> void: _open(HowToPlay.new()), 11, UiTheme.POINTS))
	col.add_child(row)


func _pause() -> void:
	if not busy:
		_open(PauseSheet.new(self))


func _open(sheet: Control) -> void:
	Feel.play("click")
	UiTheme.show_sheet(sheet)


## A framed box in the side panel; returns the column its contents go in.
func _block(parent: Control, bg: Color, border: Color) -> VBoxContainer:
	var box := PanelContainer.new()
	var style := UiTheme.box(bg, border, 4)
	style.content_margin_top = 2
	style.content_margin_bottom = 3
	box.add_theme_stylebox_override("panel", style)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 0)
	box.add_child(inner)
	parent.add_child(box)
	return inner


func _score_box(colour: Color) -> Label:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiTheme.button_box(colour))
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var l := UiTheme.title("0", 16, UiTheme.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)
	return l


## One of the three counters under Points x Mult: a big number over a small caption.
func _counter(parent: Control, caption: String, colour: Color) -> Label:
	var inner := _block(parent, UiTheme.PANEL_DARK, colour.darkened(0.2))
	inner.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var number := UiTheme.title("0", 13, colour)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(number)
	var l := UiTheme.label(caption, 8, UiTheme.MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(l)
	return number


# --- refresh ---

func refresh() -> void:
	if busy or run == null:
		return
	_drop_stale_selection()
	Feel.mood(_mood(), run.town)
	Feel.intensity(_heat())
	_update_side()
	_build_top()
	_build_middle()
	_build_hand()
	_build_buttons()
	_build_tip()
	_build_coach()
	_build_overlay()


# --- the first-run guide ---

## Each tip: the phase it shows in, its words, and whether it waits for "Got it" (the
## others move on when the player does what they say).
const COACH := [
	[RunState.Phase.CHOOSE_SHOW, "Welcome to the tour! Every town has three shows. Score a show's target to win it. Tap Play Matinee to begin.", false],
	[RunState.Phase.IN_SHOW, "These are your cards. Tap up to 5 to make a poker hand: a pair, two pair, a flush, a straight... Hold any card to read it.", false],
	[RunState.Phase.IN_SHOW, "The left panel shows the hand's Points x Mult, and the middle what it will score. Press Play hand (or flick a card up).", false],
	[RunState.Phase.IN_SHOW, "Score = Points x Mult. Reach the target before your Hands run out. Discard swaps cards for new ones (or flick one down).", true],
	[RunState.Phase.CASH_OUT, "Show won! Unused hands pay extra ducats. Cash out to visit the Market.", false],
	[RunState.Phase.SHOP, "In the Market, Jesters stay with you and boost every hand. Buy one if you can, then press Next show.", true],
]


## Moves the guide on when the player has done what the tip asked.
func _advance_coach() -> void:
	var s := Settings.tutorial_step
	if s < 0 or s >= COACH.size():
		return
	var played := int(run.counters.get("hands_played", 0)) > 0
	if s == 0 and run.phase != RunState.Phase.CHOOSE_SHOW:
		s = 1
	if s == 1 and (not selected_hand.is_empty() or played):
		s = 2
	if s == 2 and played:
		s = 3
	if s == 3 and (run.phase == RunState.Phase.CASH_OUT or run.phase == RunState.Phase.SHOP):
		s = 4
	if s == 4 and run.phase == RunState.Phase.SHOP:
		s = 5
	if s != Settings.tutorial_step:
		Settings.tutorial_step = s
		Settings.save()


func _build_coach() -> void:
	_clear(coach)
	_advance_coach()
	var s := Settings.tutorial_step
	if busy or s < 0 or s >= COACH.size() or run.phase != COACH[s][0]:
		return
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_box(Color(UiTheme.PANEL_DARK, 0.96), UiTheme.GOLD))
	panel.position = Vector2(AREA_X + 2.0, 4.0)
	panel.size = Vector2(minf(area_w - 112.0, 420.0), 0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	panel.add_child(col)
	var top := HBoxContainer.new()
	var step_label := UiTheme.label("First run  -  tip %d of %d" % [s + 1, COACH.size()], 8, UiTheme.GOLD)
	step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(step_label)
	if COACH[s][2]:
		top.add_child(UiTheme.button("Got it", func() -> void: _coach_to(s + 1), 9, UiTheme.POINTS))
	top.add_child(UiTheme.button("Skip tips", func() -> void: _coach_to(-1), 9))
	col.add_child(top)
	col.add_child(_wrapped(COACH[s][1], 10, panel.size.x - 16.0))
	coach.add_child(panel)
	if not Settings.reduce_motion:
		panel.modulate.a = 0.0
		panel.create_tween().tween_property(panel, "modulate:a", 1.0, 0.2)


func _coach_to(step: int) -> void:
	Feel.play("click")
	Settings.tutorial_step = step if step < COACH.size() else -1
	Settings.save()
	_build_coach()


## The backdrop's colours: teal for shows, crimson for the Patron and for a lost run, green
## in the shop and its packs.
func _mood() -> String:
	match run.phase:
		RunState.Phase.SHOP, RunState.Phase.PACK:
			return "shop"
		RunState.Phase.LOST:
			return "patron"
	return "patron" if run.show_index == Shows.PATRON else "show"


## How heated the music is: calm between shows, building as the show score nears the
## target, hotter still on the last hand (and at a Patron), full when the show is won.
func _heat() -> float:
	match run.phase:
		RunState.Phase.IN_SHOW:
			var k := 0.2 + 0.6 * clampf(run.show_score / maxf(1.0, run.show_target), 0.0, 1.0)
			if run.hands_left <= 1:
				k += 0.25
			if run.show_index == Shows.PATRON:
				k += 0.15
			return k
		RunState.Phase.CASH_OUT:
			return 1.0
	return 0.0


## Forgets a selection whose card is gone (sold, used, a pack closed, a hand played).
func _drop_stale_selection() -> void:
	selected_hand.assign(selected_hand.filter(func(id: int) -> bool: return _hand_card(id) != null))
	if selection.is_empty():
		return
	var i := int(selection.get("index", -1))
	var shop := run.shop
	var still_there := false
	match str(selection.get("zone", "")):
		"zanni":
			still_there = i < run.zanni.size()
		"consumable":
			still_there = i < run.consumables.size()
		"offer":
			still_there = shop != null and i < shop.offers.size() and not shop.offers[i]["sold"]
		"pack":
			still_there = shop != null and i < shop.packs.size() and not shop.packs[i]["sold"]
		"warrant":
			still_there = shop != null and (run.town_warrant != "" and not run.warrant_bought if i == 0 else shop.extra_warrant != "" and not shop.extra_bought)
		"pack_item":
			still_there = run.phase == RunState.Phase.PACK and i < (run.pack.get("items", []) as Array).size()
	if not still_there:
		selection = {}


func _update_side() -> void:
	var r := run
	var daily := "" if not Game.run_meta.has("daily_date") else ("Daily practice: " if Game.run_meta.get("practice", false) else "Daily: ")
	lbl_place.text = daily + "Town %d - %s" % [r.town, SHOW_NAMES[r.show_index]]
	if r.phase == RunState.Phase.IN_SHOW:
		lbl_target_caption.text = "Score at least"
		lbl_target.text = UiTheme.number(r.show_target)
		lbl_score.text = UiTheme.number(r.show_score)
		lbl_hands.text = str(r.hands_left)
		lbl_discards.text = str(r.discards_left)
	else:
		lbl_target_caption.text = "Next show's target"
		lbl_target.text = UiTheme.number(r.target_for_show(r.show_index))
		lbl_score.text = "0"
		lbl_hands.text = str(r.stat("hands"))
		lbl_discards.text = str(r.stat("discards"))
	lbl_ducats.text = str(r.ducats)
	var preview := _selected_cards()
	if preview.is_empty():
		lbl_hand.text = ""
		lbl_points.text = "0"
		lbl_mult.text = "0"
	else:
		var hand_type := HandEvaluator.evaluate(preview, r.eval_options()).type
		lbl_hand.text = "%s lv.%d" % [_hand_name(hand_type), r.hand_levels.level(hand_type)]
		lbl_points.text = UiTheme.number(r.hand_levels.points(hand_type))
		lbl_mult.text = UiTheme.number(r.hand_levels.mult(hand_type))
	_update_info()


func _update_info() -> void:
	if message != "":
		info_name.text = ""
		info_text.text = message
		return
	if not selection.is_empty():
		var id := _selected_def_id()
		info_name.text = UiTheme.name_of(id) if id != "" else ""
		info_text.text = _describe_selection(id)
	elif selected_hand.size() == 1:
		var card := _hand_card(selected_hand[0])
		info_name.text = _card_name(card)
		info_text.text = _describe_card(card)
	else:
		info_name.text = ""
		info_text.text = _phase_hint()


func _phase_hint() -> String:
	match run.phase:
		RunState.Phase.CHOOSE_SHOW:
			return "Play this show, or skip it to take its Favor."
		RunState.Phase.IN_SHOW:
			return "Select up to 5 cards, then Play or Discard."
		RunState.Phase.CASH_OUT:
			return "The show is won. Collect your ducats."
		RunState.Phase.SHOP:
			return "Tap a card to read it, then Buy."
		RunState.Phase.PACK:
			return "Choose %d. Tarocchi and Omens use the cards you select below." % int(run.pack.get("picks", 1))
	return ""


# --- top: Jesters and consumables ---

func _build_top() -> void:
	_clear(top_row)
	jester_views.clear()
	var r := run
	var step := minf(57.0, (area_w - 110.0 - jester_card.x) / maxf(1.0, r.zanni.size() - 1))
	for i in r.zanni.size():
		var z := r.zanni[i]
		var v := _named_view("zanni", z.def_id, jester_card, {"zone": "zanni", "index": i})
		v.edition = z.edition
		v.dimmed = z.debuffed
		v.face_down = z.face_down
		v.sticker = "eternal" if z.state.get("eternal", false) else ("perishable" if z.state.has("perish") else ("rented" if z.state.get("rented", false) else ""))
		v.position = Vector2(i * step, 0)
		v.sway = i + 3
		v.draggable = not busy and r.zanni.size() > 1
		v.drag_moved.connect(func(view: CardView, at: Vector2) -> void:
			view.position.x = clampf(at.x - top_row.global_position.x - jester_card.x / 2.0, 0.0, area_w - 110.0 - jester_card.x))
		v.drag_ended.connect(_on_jester_drop)
		top_row.add_child(v)
		jester_views.append(v)
	var count := UiTheme.label("Jesters %d/%d" % [r.zanni.size(), r.stat("zanni_slots")], 8, UiTheme.MUTED)
	count.position = Vector2(0, 72)
	top_row.add_child(count)
	for i in r.consumables.size():
		var c := r.consumables[i]
		var v := _named_view(c.def().kind, c.def_id, item_card, {"zone": "consumable", "index": i})
		v.edition = c.edition
		v.position = Vector2(area_w - 100 + i * 50, 4)
		v.sway = i + 9
		top_row.add_child(v)
	var ccount := UiTheme.label("One-use cards %d/%d" % [r.consumables.size(), r.stat("consumable_slots")], 8, UiTheme.MUTED)
	ccount.position = Vector2(area_w - 100, 72)
	top_row.add_child(ccount)


## Under a tapped Jester or one-use card: the card at full size, its name, what kind of
## card it is (and a Jester's rarity), and its effect.
func _build_tip() -> void:
	_clear(tip)
	var zone := str(selection.get("zone", ""))
	if busy or not (zone == "zanni" or zone == "consumable"):
		return
	var i := int(selection["index"])
	var item: ItemCard = run.zanni[i] if zone == "zanni" else run.consumables[i]
	var def := item.def()
	var panel := PanelContainer.new()
	var border: Color = CardView.RARITY_COLOURS[clampi(def.rarity, 0, 3)] if def.kind == "zanni" else CardView.KIND_COLOURS.get(def.kind, UiTheme.PANEL_LIGHT)
	panel.add_theme_stylebox_override("panel", UiTheme.panel_box(UiTheme.PANEL_DARK, border.lightened(0.2)))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var big := CardView.new(Vector2(80, 112))
	big.kind = def.kind
	big.def_id = def.id
	big.edition = item.edition
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(big)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	row.add_child(col)
	col.add_child(UiTheme.title(UiTheme.name_of(def.id), 13, UiTheme.GOLD))
	var what: String = KIND_HELP.get(def.kind, "").get_slice(":", 0)
	if def.kind == "zanni":
		what = CardView.RARITY_NAMES[clampi(def.rarity, 0, 3)] + " " + what
	col.add_child(UiTheme.label(what, 8, border.lightened(0.35)))
	var text := UiTheme.label(UiTheme.text_of(def.id), 10)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(176, 0)
	col.add_child(text)
	tip.add_child(panel)
	var x: float = AREA_X + ((jester_views[i] as Control).position.x if zone == "zanni" else area_w - 100 + i * 50)
	panel.position = Vector2(clampf(x - 20.0, AREA_X, AREA_X + area_w - 290.0), 84.0)
	if not Settings.reduce_motion:
		panel.modulate.a = 0.0
		panel.create_tween().tween_property(panel, "modulate:a", 1.0, 0.12)


func _named_view(kind: String, def_id: String, view_size: Vector2, tag: Dictionary) -> CardView:
	var v := CardView.new(view_size)
	v.kind = kind
	v.def_id = def_id
	v.tag = tag
	v.selected = _same(selection, tag)
	v.tapped.connect(_on_tap)
	v.long_pressed.connect(_show_detail)
	return v


## Dropping a dragged Jester: the Jesters take the order they now stand in (it matters:
## they score left to right).
func _on_jester_drop(view: CardView, _at: Vector2) -> void:
	var order := range(jester_views.size())
	order.sort_custom(func(a: int, b: int) -> bool: return (jester_views[a] as CardView).position.x < (jester_views[b] as CardView).position.x)
	if order == range(jester_views.size()):
		refresh()
		return
	_act({"a": "reorder_zanni", "order": order})
	selection = {"zone": "zanni", "index": order.find(int(view.tag["index"]))}
	refresh()


## Holding a card: show it big with everything about it.
func _show_detail(view: CardView) -> void:
	Feel.play("select")
	Feel.buzz(12)
	var big := CardView.new(Vector2(110, 154))
	big.kind = view.kind
	big.card = view.card
	big.def_id = view.def_id
	big.edition = view.edition
	big.sticker = view.sticker
	big.face_down = false
	var heading := ""
	var lines := []
	if view.kind == "card":
		heading = _card_name(view.card)
		lines = ["Playing card", _describe_card(view.card)]
	else:
		var def := ContentDB.get_def(view.def_id)
		heading = UiTheme.name_of(view.def_id)
		var what: String = KIND_HELP.get(view.kind, "")
		if def != null and view.kind == "zanni":
			what = CardView.RARITY_NAMES[clampi(def.rarity, 0, 3)] + " " + what
		lines = [what.get_slice(":", 0), UiTheme.text_of(view.def_id)]
		var gloss := TranslationServer.translate(view.def_id + ".gloss")
		if gloss != view.def_id + ".gloss":
			lines.append("(" + gloss + ")")
		if view.edition != "":
			lines.append("%s: %s" % [UiTheme.name_of(view.edition), UiTheme.text_of(view.edition)])
		if what.contains(":"):
			var how := what.get_slice(":", 1).strip_edges()
			lines.append(how.left(1).to_upper() + how.substr(1))
	UiTheme.show_sheet(DetailSheet.new(big, heading, lines))


# --- middle: the phase area ---

func _build_middle() -> void:
	_clear(middle)
	match run.phase:
		RunState.Phase.CHOOSE_SHOW:
			_middle_shows()
		RunState.Phase.IN_SHOW:
			_middle_show_info()
		RunState.Phase.CASH_OUT:
			_middle_payout()
		RunState.Phase.SHOP:
			_middle_shop()
		RunState.Phase.PACK:
			_middle_pack()


func _middle_shows() -> void:
	var r := run
	var w := floorf((area_w - 18.0) / 3.0)
	for i in 3:
		var panel := PanelContainer.new()
		var active := i == r.show_index
		var colour: Color = SHOW_COLOURS[i]
		panel.add_theme_stylebox_override("panel", UiTheme.panel_box(UiTheme.PANEL_DARK, UiTheme.GOLD if active else colour.darkened(0.3)))
		panel.position = Vector2(i * (w + 9.0), 0)
		panel.size = Vector2(w, 104)
		panel.modulate = Color(1, 1, 1, 1.0 if i >= r.show_index else 0.4)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 1)
		panel.add_child(col)
		col.add_child(UiTheme.title(SHOW_NAMES[i], 13, colour.lightened(0.3)))
		col.add_child(UiTheme.label("Score at least", 8, UiTheme.MUTED))
		col.add_child(UiTheme.title(UiTheme.number(r.target_for_show(i)), 16, UiTheme.GOLD))
		if i < Shows.PATRON:
			var favor := r.town_favors[i]
			if favor != "":
				col.add_child(_wrapped("Skip for: " + UiTheme.name_of(favor), 10, w - 14.0))
				col.add_child(_wrapped(_favor_text(i), 8, w - 14.0))
		else:
			col.add_child(_wrapped(UiTheme.name_of(r.town_patron), 10, w - 14.0))
			col.get_child(col.get_child_count() - 1).add_theme_color_override("font_color", UiTheme.MULT.lightened(0.2))
			col.add_child(_wrapped(UiTheme.text_of(r.town_patron), 8, w - 14.0))
		middle.add_child(panel)


func _favor_text(slot: int) -> String:
	var text := UiTheme.text_of(run.town_favors[slot])
	var note := run.town_favor_notes[slot]
	return text if note == "" else "%s (%s)" % [text, _hand_name(note)]


## During a show the middle says what to do next, or names the hand the selected cards make.
func _middle_show_info() -> void:
	var col := VBoxContainer.new()
	col.position = Vector2(0, 6)
	col.size = Vector2(area_w, 100)
	col.add_theme_constant_override("separation", 6)
	middle.add_child(col)
	var patron := run.current_patron()
	if patron != "":
		var l := _wrapped("%s: %s" % [UiTheme.name_of(patron), UiTheme.text_of(patron)], 10, area_w)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_color", UiTheme.MULT.lightened(0.25))
		col.add_child(l)
	var preview := _selected_cards()
	if preview.is_empty():
		col.add_child(_centred(UiTheme.title("Tap up to 5 cards, then press Play hand", 12, UiTheme.TEXT)))
	else:
		var hand_type := HandEvaluator.evaluate(preview, run.eval_options()).type
		col.add_child(_centred(UiTheme.title(_hand_name(hand_type), 24, UiTheme.GOLD)))
		var guess := run.preview(_selected_ids())
		if guess >= 0.0:
			var wins := guess >= run.show_target - run.show_score
			var line := "Scores about %s%s" % [UiTheme.number(guess), "  -  enough to win the show!" if wins else ""]
			col.add_child(_centred(UiTheme.label(line, 12, UiTheme.GOOD if wins else UiTheme.TEXT)))


func _middle_payout() -> void:
	var col := VBoxContainer.new()
	col.position = Vector2(area_w / 2.0 - 100.0, 4)
	middle.add_child(col)
	if run.won and not Game.win_seen:
		col.add_child(UiTheme.label("The tour is won!", 14, UiTheme.GOLD))
	var total := 0
	for p in run.payout:
		total += int(p["v"])
		col.add_child(UiTheme.label("%s   %+d" % [_payout_name(str(p["src"])), int(p["v"])], 10))
	col.add_child(UiTheme.label("Total   %+d ducats" % total, 12, UiTheme.GOLD))


func _payout_name(src: String) -> String:
	match src:
		"show":
			return "Show reward"
		"hands":
			return "Unused hands"
		"discards":
			return "Unused discards"
		"interest":
			return "Interest"
	if src.begins_with("zanni:"):
		return UiTheme.name_of(src.get_slice(":", 1).get_slice("#", 0))
	if src.begins_with("card:"):
		return "Gilt card"
	return src


## The shop fills the table (there's no hand to show): a framed market with the cards on
## top and the packs and Warrants below, all at full card size.
func _middle_shop() -> void:
	var r := run
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_box(Color(UiTheme.PANEL_DARK, 0.92), UiTheme.GOOD.darkened(0.35)))
	panel.size = Vector2(area_w, 236)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle.add_child(panel)
	var heading := _centred(UiTheme.title("The Market", 18, UiTheme.GOLD))
	heading.position = Vector2(0, 4)
	heading.size = Vector2(area_w, 24)
	middle.add_child(heading)
	middle.add_child(_section("Cards", 14, 28))
	var x := 14.0
	for i in r.shop.offers.size():
		var o: Dictionary = r.shop.offers[i]
		if o["sold"]:
			continue
		var v: CardView
		if o["kind"] == "card":
			v = CardView.new(SHOP_CARD)
			v.card = _card_from(o["card"])
			v.tag = {"zone": "offer", "index": i}
			v.selected = _same(selection, v.tag)
			v.tapped.connect(_on_tap)
			v.long_pressed.connect(_show_detail)
		else:
			v = _named_view(o["kind"], o["id"], SHOP_CARD, {"zone": "offer", "index": i})
			v.edition = o["edition"]
			v.sticker = str(o.get("sticker", "rented" if o.get("rented", false) else ""))
		v.price_text = str(r.offer_price(o))
		v.position = Vector2(x, 42)
		v.sway = i
		middle.add_child(v)
		x += 70
	middle.add_child(_section("Packs", 14, 132))
	x = 14.0
	for i in r.shop.packs.size():
		var p: Dictionary = r.shop.packs[i]
		if p["sold"]:
			continue
		var v := _named_view("pack", p["id"], SHOP_CARD, {"zone": "pack", "index": i})
		v.price_text = str(r.offer_price(p))
		v.position = Vector2(x, 146)
		v.sway = i + 4
		middle.add_child(v)
		x += 70
	x = maxf(x + 24, 200)
	middle.add_child(_section("Warrant", x, 132))
	var warrants := [[r.town_warrant, r.warrant_bought, 0], [r.shop.extra_warrant, r.shop.extra_bought, 1]]
	for w in warrants:
		if w[0] == "" or w[1]:
			continue
		var v := _named_view("warrant", w[0], SHOP_CARD, {"zone": "warrant", "index": w[2]})
		v.price_text = str(ContentDB.get_def(w[0]).cost)
		v.position = Vector2(x, 146)
		v.sway = int(w[2]) + 7
		middle.add_child(v)
		x += 70


func _middle_pack() -> void:
	var items: Array = run.pack.get("items", [])
	middle.add_child(_section("%s: choose %d" % [UiTheme.name_of(run.pack["id"]), int(run.pack["picks"])], 0))
	for i in items.size():
		var entry: Dictionary = items[i]
		var v: CardView
		if entry["kind"] == "card":
			v = CardView.new(item_card)
			v.card = _card_from(entry["card"])
			v.tag = {"zone": "pack_item", "index": i}
			v.selected = _same(selection, v.tag)
			v.tapped.connect(_on_tap)
			v.long_pressed.connect(_show_detail)
		else:
			v = _named_view(entry["kind"], entry["id"], item_card, {"zone": "pack_item", "index": i})
			v.edition = str(entry.get("edition", ""))
		v.position = Vector2(i * 56, 16)
		middle.add_child(v)


func _section(text: String, x: float, y := 0.0) -> Label:
	var l := UiTheme.label(text, 10, UiTheme.MUTED)
	l.position = Vector2(x, y)
	return l


# --- hand ---

## The hand, laid out across the bottom. Cards already on screen glide from where they were
## (selecting, sorting, the hand closing up after a play); new ones are dealt in from the
## right, one after another.
func _build_hand() -> void:
	_clear(hand_row)
	if not busy and run.phase != RunState.Phase.IN_SHOW and run.phase != RunState.Phase.PACK:
		hand_layout = {}
		return
	var previous := hand_layout
	hand_layout = {}
	var cards := _sorted_hand()
	var step := _hand_step(cards.size())
	var left := (area_w - (step * (cards.size() - 1) + hand_card.x)) / 2.0
	var rest_y := hand_row.size.y - hand_card.y - 6.0
	var forced := int(run.show_counters.get("forced", -1)) if run.phase == RunState.Phase.IN_SHOW else -1
	var dealt := 0
	for i in cards.size():
		var card: PlayingCard = cards[i]
		var v := CardView.new(hand_card)
		v.card = card
		v.edition = card.edition
		v.face_down = card.face_down
		v.dimmed = card.debuffed
		v.selected = selected_hand.has(card.id) or card.id == forced
		v.tag = {"zone": "hand", "id": card.id}
		var to := Vector2(left + i * step, rest_y - 20.0 if v.selected else rest_y)
		hand_layout[card.id] = to
		v.sway = i
		v.draggable = not busy
		v.swipeable = not busy and run.phase == RunState.Phase.IN_SHOW
		v.tapped.connect(_on_tap)
		v.long_pressed.connect(_show_detail)
		v.drag_moved.connect(_on_hand_drag)
		v.drag_ended.connect(_on_hand_drop)
		v.swiped.connect(_on_swipe)
		hand_row.add_child(v)
		if Settings.reduce_motion:
			v.position = to
		elif previous.has(card.id):
			v.position = previous[card.id]
			if v.position != to:
				v.create_tween().tween_property(v, "position", to, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			v.position = Vector2(area_w + 30, rest_y)
			v.modulate.a = 0.0
			var t := v.create_tween().set_parallel()
			t.tween_property(v, "position", to, 0.28).set_delay(dealt * 0.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			t.tween_property(v, "modulate:a", 1.0, 0.12).set_delay(dealt * 0.05)
			dealt += 1
	if dealt > 0 and not previous.is_empty():
		Feel.play("deal", 1.1)


## The gap between hand cards: a little air when there's room, overlapping when there isn't.
func _hand_step(count: int) -> float:
	return minf(hand_card.x + 6.0, (area_w - hand_card.x) / maxf(1.0, count - 1))


## While a hand scores, the hand row shows only the cards that stayed in hand: the refill
## arrives after the score, not before it. Sorted by rank, by suit, or in the player's own
## order after a drag (new cards go on the right).
func _sorted_hand() -> Array:
	var cards: Array = (held_while_scoring if busy else run.hand).duplicate()
	if sort_by == "rank":
		cards.sort_custom(func(a: PlayingCard, b: PlayingCard) -> bool:
			return a.rank > b.rank if a.rank != b.rank else a.suit < b.suit)
	elif sort_by == "suit":
		cards.sort_custom(func(a: PlayingCard, b: PlayingCard) -> bool:
			return a.suit < b.suit if a.suit != b.suit else a.rank > b.rank)
	else:
		var rank_of := func(c: PlayingCard) -> int:
			var at := custom_order.find(c.id)
			return at if at >= 0 else 1000 + c.id
		cards.sort_custom(func(a: PlayingCard, b: PlayingCard) -> bool: return rank_of.call(a) < rank_of.call(b))
	return cards


## Dragging a hand card: it follows the finger, and the cards it passes slide aside.
func _on_hand_drag(view: CardView, at: Vector2) -> void:
	var local_x := at.x - hand_row.global_position.x - hand_card.x / 2.0
	view.position.x = clampf(local_x, -10.0, area_w - hand_card.x + 10.0)
	var order := _drag_order(view)
	var step := _hand_step(order.size())
	var left := (area_w - (step * (order.size() - 1) + hand_card.x)) / 2.0
	for child in hand_row.get_children():
		if child is CardView and child != view and not child.is_queued_for_deletion():
			var slot := order.find(int(child.tag["id"]))
			child.position.x = lerpf(child.position.x, left + slot * step, 0.35)


## Dropping it: the hand keeps this order from now on (Sort puts it back by rank or suit).
func _on_hand_drop(view: CardView, _at: Vector2) -> void:
	custom_order.assign(_drag_order(view))
	sort_by = "custom"
	Feel.play("deal")
	refresh()


## The hand's ids in order, with the dragged card where it is now.
func _drag_order(view: CardView) -> Array:
	var views := hand_row.get_children().filter(func(c: Node) -> bool: return c is CardView and not c.is_queued_for_deletion())
	views.sort_custom(func(a: CardView, b: CardView) -> bool:
		var ax := a.position.x if a != view else view.position.x
		var bx := b.position.x if b != view else view.position.x
		return ax < bx)
	return views.map(func(c: CardView) -> int: return int(c.tag["id"]))


## A flick up plays the selected cards (or the flicked one), a flick down discards them.
func _on_swipe(view: CardView, direction: int) -> void:
	if busy or run.phase != RunState.Phase.IN_SHOW:
		return
	var id := int(view.tag["id"])
	if not selected_hand.has(id) and selected_hand.size() < maxi(5, run.stat("max_play")):
		selected_hand.append(id)
	if direction > 0 and run.hands_left > 0:
		_on_play()
	elif direction < 0 and run.discards_left > 0:
		_on_discard()
	else:
		Feel.play("error")
		refresh()


## Selected hand cards in the order they're shown, which is the order they score in.
func _selected_cards() -> Array[PlayingCard]:
	var out: Array[PlayingCard] = []
	for card in _sorted_hand():
		if selected_hand.has(card.id):
			out.append(card)
	return out


func _selected_ids() -> Array:
	return _selected_cards().map(func(c: PlayingCard) -> int: return c.id)


# --- buttons ---

func _build_buttons() -> void:
	_clear(buttons)
	primary = Callable()
	var r := run
	match r.phase:
		RunState.Phase.CHOOSE_SHOW:
			_add_button("Play " + SHOW_NAMES[r.show_index], func() -> void: _act({"a": "select_show"}), false, UiTheme.MULT, true)
			if r.show_index < Shows.PATRON:
				_add_button("Skip for the Favor", func() -> void: _act({"a": "skip_show"}))
			if r.town_swaps < r.stat("patron_swaps"):
				_add_button("Swap Patron (10)", func() -> void: _act({"a": "swap_patron"}))
		RunState.Phase.IN_SHOW:
			var picked := selected_hand.size()
			_add_button("Play hand", _on_play, picked == 0 or picked > r.stat("max_play"), UiTheme.POINTS, true)
			_add_button("Discard", _on_discard, picked == 0, UiTheme.MULT)
			_add_button("Sort by suit" if sort_by == "rank" else "Sort by rank", _toggle_sort)
		RunState.Phase.CASH_OUT:
			var total := 0
			for p in r.payout:
				total += int(p["v"])
			_add_button("Cash out %+d" % total, func() -> void: _act({"a": "cash_out"}), false, UiTheme.GOLD.darkened(0.25), true)
		RunState.Phase.SHOP:
			_add_button("Next show", func() -> void: _act({"a": "leave_shop"}), false, UiTheme.MULT)
			_add_button("Reroll %d" % r.reroll_price(), func() -> void: _act({"a": "reroll"}), false, UiTheme.GOOD.darkened(0.3))
		RunState.Phase.PACK:
			if selection.get("zone", "") == "pack_item":
				_add_button("Pick", func() -> void: _act({"a": "pick", "index": selection["index"], "cards": _selected_ids()}), false, UiTheme.POINTS, true)
			_add_button("Skip pack", func() -> void: _act({"a": "skip_pack"}))
	_contextual_buttons()
	if r.phase == RunState.Phase.IN_SHOW:
		_add_deck_pile()


## At the right of the buttons: the draw pile, face down, with how many cards are left in
## it; it opens the deck tracker.
func _add_deck_pile() -> void:
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(gap)
	var pile := CardView.new(Vector2(20, 28))
	pile.face_down = true
	pile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buttons.add_child(pile)
	_add_button("Deck %d" % run.draw_pile.size(), func() -> void: _open(RunInfoSheet.new("deck")))


func _contextual_buttons() -> void:
	var zone := str(selection.get("zone", ""))
	var i := int(selection.get("index", -1))
	match zone:
		"zanni":
			var z := run.zanni[i]
			if not z.state.get("eternal", false):
				_add_button("Sell +%d" % z.sell_value(), func() -> void: _act({"a": "sell", "zone": "zanni", "index": i}))
			_add_button("<", func() -> void: _move_jester(i, -1), i == 0)
			_add_button(">", func() -> void: _move_jester(i, 1), i == run.zanni.size() - 1)
		"consumable":
			_add_button("Use", func() -> void: _act({"a": "use", "index": i, "cards": _selected_ids()}))
			_add_button("Sell +%d" % run.consumables[i].sell_value(), func() -> void: _act({"a": "sell", "zone": "consumable", "index": i}))
		"offer":
			_add_button("Buy", func() -> void: _act({"a": "buy", "slot": i}), false, UiTheme.GOLD.darkened(0.25), true)
		"pack":
			_add_button("Buy & open", func() -> void: _act({"a": "buy_pack", "slot": i}), false, UiTheme.GOLD.darkened(0.25), true)
		"warrant":
			_add_button("Buy", func() -> void: _act({"a": "buy_warrant", "index": i}), false, UiTheme.GOLD.darkened(0.25), true)


## `main` marks the button Enter presses (the first enabled one).
func _add_button(text: String, on_press: Callable, disabled := false, colour := Color.TRANSPARENT, main := false) -> void:
	var b := UiTheme.button(text, on_press, 11, colour)
	b.disabled = disabled or busy
	b.custom_minimum_size.y = 30
	buttons.add_child(b)
	if main and not b.disabled and not primary.is_valid():
		primary = on_press


# --- overlay: the end of a run ---

func _build_overlay() -> void:
	_clear(overlay)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var r := run
	var lost := r.phase == RunState.Phase.LOST
	var just_won := r.won and not Game.win_seen and r.phase == RunState.Phase.SHOP
	if not lost and not just_won:
		return
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var accent := UiTheme.MULT if lost else UiTheme.GOLD
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_box(UiTheme.PANEL, accent.darkened(0.2)))
	panel.position = Vector2(110, 34)
	panel.size = Vector2(420, 0)
	UiTheme.stage(overlay).add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	col.add_child(_centred(UiTheme.title("The show is over" if lost else "All 8 towns conquered!", 24, accent)))
	var what := UiTheme.name_of(r.challenge) if r.challenge != "" else "%s, Stake %d" % [UiTheme.name_of(r.deck_id), r.stake]
	col.add_child(_centred(UiTheme.label("Town %d - %s   |   %s" % [r.town, SHOW_NAMES[r.show_index], what], 10, UiTheme.MUTED)))
	col.add_child(_end_stats(r))
	if not r.zanni.is_empty():
		col.add_child(UiTheme.label("Your Jesters", 9, UiTheme.MUTED))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		for z in r.zanni:
			var v := CardView.new(Vector2(40, 56))
			v.kind = "zanni"
			v.def_id = z.def_id
			v.edition = z.edition
			v.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(v)
		col.add_child(row)
	var daily := Game.run_meta.has("daily_date")
	var ranked: bool = daily and not Game.run_meta.get("practice", false)
	if ranked:
		col.add_child(_centred(UiTheme.label("Your daily run is handed in." if Online.signed_in() else "Log in to rank your daily runs.", 10, UiTheme.GOOD)))
	var buttons_row := HBoxContainer.new()
	buttons_row.add_theme_constant_override("separation", 6)
	buttons_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(buttons_row)
	if lost:
		buttons_row.add_child(UiTheme.button("Practise this daily" if daily else "New run", func() -> void:
			Feel.play("play")
			Game.restart()
			restart(), 13, UiTheme.MULT))
	else:
		buttons_row.add_child(UiTheme.button("Keep touring", func() -> void:
			Game.win_seen = true
			refresh(), 13, UiTheme.MULT))
	if daily:
		buttons_row.add_child(UiTheme.button("Leaderboards", func() -> void: _open(LeaderboardSheet.new("daily")), 12, UiTheme.GOLD.darkened(0.3)))
	buttons_row.add_child(UiTheme.button("Main menu", func() -> void:
		Game.finish_run()
		back_to_menu.emit(), 12, UiTheme.POINTS))
	if not Settings.reduce_motion:
		panel.pivot_offset = panel.size / 2.0
		panel.scale = Vector2(0.9, 0.9)
		panel.modulate.a = 0.0
		var t := panel.create_tween().set_parallel()
		t.tween_property(panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(panel, "modulate:a", 1.0, 0.18)


## The numbers of a finished run, in two columns.
func _end_stats(r: RunState) -> GridContainer:
	var most := ""
	for hand_type in HandTable.ORDER:
		if r.hand_levels.times_played(hand_type) > (r.hand_levels.times_played(most) if most != "" else 0):
			most = hand_type
	var stats := [
		["Towns conquered", str(r.town - 1)] if r.won else ["Towns reached", str(r.town)],
		["Best hand", UiTheme.number(float(r.counters.get("best_hand", 0)))],
		["Shows won", str(int(r.counters.get("shows_won", 0)))],
		["Hands played", str(int(r.counters.get("hands_played", 0)))],
		["Most played", _hand_name(most) if most != "" else "-"],
		["Cards bought", str(int(r.counters.get("purchases", 0)))],
		["Ducats", str(r.ducats)],
		["Seed", r.seed_text],
	]
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 2)
	for s in stats:
		var key := UiTheme.label(s[0], 10, UiTheme.MUTED)
		key.custom_minimum_size = Vector2(92, 0)
		grid.add_child(key)
		var value := UiTheme.label(s[1], 11, UiTheme.TEXT)
		value.custom_minimum_size = Vector2(100, 0)
		grid.add_child(value)
	return grid


func _centred(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


# --- input ---

func _on_tap(view: CardView) -> void:
	if busy:
		return
	message = ""
	Feel.play("deselect" if view.selected else "select")
	Feel.buzz(8)
	var tag := view.tag
	if tag["zone"] == "hand":
		var id: int = tag["id"]
		if selected_hand.has(id):
			selected_hand.erase(id)
		elif selected_hand.size() < maxi(5, run.stat("max_play")):
			selected_hand.append(id)
	elif _same(selection, tag):
		selection = {}
	else:
		selection = tag.duplicate()
	refresh()


func _act(action: Dictionary) -> void:
	var result := Game.act(action, true)
	message = "" if result["ok"] else _sentence(str(result["error"]))
	if result["ok"]:
		selected_hand.clear()
		selection = {}
		Feel.play(ACTION_CUES.get(action["a"], ""))
		if run.phase == RunState.Phase.LOST:
			Feel.play("lose")
	else:
		Feel.play("error")
	Game.changed.emit()


## Throws the selected cards away (they fly up and fade), then discards them; the
## replacements are dealt in by the next layout.
func _on_discard() -> void:
	var ids := _selected_ids()
	Feel.play("discard")
	if not Settings.reduce_motion:
		busy = true
		_build_buttons()
		for child in hand_row.get_children():
			if not child.is_queued_for_deletion() and ids.has(int(child.tag["id"])):
				child.set_process(false)
				var t := child.create_tween().set_parallel()
				t.tween_property(child, "position", child.position + Vector2(40, -60), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
				t.tween_property(child, "rotation", 0.4, 0.2)
				t.tween_property(child, "modulate:a", 0.0, 0.2)
		await _wait(0.2)
		busy = false
	_act({"a": "discard", "cards": ids})


func _toggle_sort() -> void:
	sort_by = "suit" if sort_by == "rank" else "rank"
	refresh()


func _move_jester(index: int, step: int) -> void:
	var order := range(run.zanni.size())
	order[index] = index + step
	order[index + step] = index
	_act({"a": "reorder_zanni", "order": order})
	selection = {"zone": "zanni", "index": index + step}
	refresh()


## Plays the selected cards: they fly to the table, the score is replayed step by step (each
## card or Jester pops with its number floating up, the Points and Mult boxes punch), the
## total slams down and flies into the show score, the cards fly off, and only then is the
## hand refilled.
func _on_play() -> void:
	var played := _selected_cards()
	var ids := _selected_ids()
	var before := run.show_score
	var held := run.hand.filter(func(c: PlayingCard) -> bool: return not ids.has(c.id))
	var from := _hand_positions()
	var result := Game.act({"a": "play", "cards": ids}, true)
	if not result["ok"]:
		message = _sentence(str(result["error"]))
		refresh()
		return
	busy = true
	scoring = true
	skipping = false
	Engine.time_scale = float(Settings.speed)
	held_while_scoring = held
	selected_hand.clear()
	selection = {}
	_clear(middle)
	_clear(tip)
	_clear(coach)
	_build_hand()
	_build_buttons()
	var views := {}
	for child in hand_row.get_children():
		if not child.is_queued_for_deletion():
			views[int(child.tag["id"])] = child
	var scoring_ids: Array = result.get("scoring", [])
	var played_views: Array[CardView] = []
	var gap := minf(hand_card.x + 4.0, (area_w - hand_card.x) / maxf(1.0, played.size() - 1))
	var left := (area_w - (gap * (played.size() - 1) + hand_card.x)) / 2.0
	for i in played.size():
		var v := CardView.new(hand_card)
		v.card = played[i]
		v.edition = played[i].edition
		middle.add_child(v)
		var scores := scoring_ids.has(played[i].id)
		if not scores:
			v.modulate = Color(1, 1, 1, 0.6)
		_fly(v, from.get(played[i].id, Vector2.ZERO), Vector2(left + i * gap, 4 if scores else 14), i * 0.05)
		views[played[i].id] = v
		played_views.append(v)
	Feel.play("play")
	await _wait(0.2 + played.size() * 0.05)
	lbl_hand.text = _hand_name(str(result["hand"]))
	var events: Array = result["events"]
	var step := clampf(2.2 / maxf(1.0, events.size()), 0.08, 0.3)
	for n in events.size():
		var e: Dictionary = events[n]
		lbl_points.text = UiTheme.number(float(e["points"]))
		lbl_mult.text = UiTheme.number(float(e["mult"]))
		if e["t"] == "not_allowed":
			message = "The Patron doesn't allow that hand: it scores nothing."
		var target: Control = null
		var card_id := int(e["card"])
		if views.has(card_id):
			target = views[card_id]
		elif str(e["src"]).begins_with("zanni:"):
			var index := int(str(e["src"]).get_slice("#", 1))
			if index < jester_views.size():
				target = jester_views[index]
		_feel_event(e, target, n)
		await _wait(step)
	var total := float(result["total"])
	await _slam(total, run.phase == RunState.Phase.CASH_OUT)
	for i in played_views.size():
		_fly_off(played_views[i], i * 0.04)
	await _count_up(lbl_score, before, before + total)
	if run.phase == RunState.Phase.CASH_OUT:
		Feel.play("win")
		Feel.play("applause")
		Feel.intensity(1.0)
		Feel.buzz(40)
		Feel.shake(4.0)
		Feel.kick(2.0)
		Feel.burst(lbl_score.get_global_rect().get_center(), UiTheme.GOLD, 40)
		await _banner("SHOW WON!", UiTheme.GOLD)
	elif run.phase == RunState.Phase.LOST:
		Feel.play("lose")
		await _wait(0.4)
	scoring = false
	skipping = false
	Engine.time_scale = 1.0
	busy = false
	Game.changed.emit()


## A tap, click or key while a hand is scoring fast-forwards to the result.
func _input(event: InputEvent) -> void:
	if not scoring or skipping:
		return
	var press: bool = (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventKey and event.pressed and not event.echo)
	if press:
		skipping = true
		Engine.time_scale = 12.0
		get_viewport().set_input_as_handled()


## Keys: Enter or Space presses the main button (Play hand, Play the show, Cash out, Buy,
## Pick), D discards, S sorts, 1–9 pick hand cards, I opens Run info, Esc or P pauses.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if busy or run == null or UiTheme.sheet_open() or overlay.mouse_filter == Control.MOUSE_FILTER_STOP:
		return
	var key: int = (event as InputEventKey).keycode
	match key:
		KEY_ESCAPE, KEY_P:
			_pause()
		KEY_I:
			_open(RunInfoSheet.new())
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if primary.is_valid():
				primary.call()
		KEY_D:
			if run.phase == RunState.Phase.IN_SHOW and not selected_hand.is_empty() and run.discards_left > 0:
				_on_discard()
		KEY_S:
			if run.phase == RunState.Phase.IN_SHOW:
				_toggle_sort()
		_:
			if key < KEY_1 or key > KEY_9:
				return
			_toggle_hand_card(key - KEY_1)
	get_viewport().set_input_as_handled()


## Number keys: the nth card of the hand as it's shown, tapped.
func _toggle_hand_card(index: int) -> void:
	var cards := _sorted_hand()
	if index >= cards.size():
		return
	for child in hand_row.get_children():
		if child is CardView and not child.is_queued_for_deletion() and int(child.tag["id"]) == cards[index].id:
			_on_tap(child)
			return


## Scoring step kinds that aren't a number, and what to say when they happen.
const EVENT_WORDS := {
	"swap": "Swap!", "shattered": "Shattered!", "masked": "Masked!", "halved": "Halved",
	"balanced": "Balanced!", "debuffed": "Debuffed", "not_allowed": "Not allowed!", "ducats_lost": "Ducats lost",
}


## One scoring step's feel: its number floating out of the card or Jester that caused it,
## the card popping, its sound (pitch climbing as the hand goes on), a tick of vibration,
## sparks, the Points or Mult box punching, the backdrop spinning up, a shake for ×Mult.
func _feel_event(e: Dictionary, target: Control, index: int) -> void:
	var kind := str(e["t"])
	var amount := float(e["v"])
	if EVENT_CUES.has(kind) and not skipping:
		Feel.play(EVENT_CUES[kind], minf(2.0, 1.0 + index * 0.05))
		Feel.buzz(6)
	var text: String = EVENT_WORDS.get(kind, "")
	var colour := UiTheme.GOLD
	var size := 13
	match kind:
		"points":
			text = "+" + UiTheme.number(amount)
			colour = UiTheme.POINTS.lightened(0.25)
		"mult":
			text = "+%s Mult" % _short(amount)
			colour = UiTheme.MULT.lightened(0.15)
		"xmult":
			text = "x%s Mult" % _short(amount)
			colour = Color("ff6a3a")
			size = 17
		"ducats":
			text = "%+d ducats" % int(amount)
		"base":
			_punch(lbl_points.get_parent())
			_punch(lbl_mult.get_parent())
	if kind == "points" or kind == "swap":
		_punch(lbl_points.get_parent())
	if kind == "mult" or kind == "xmult" or kind == "swap":
		_punch(lbl_mult.get_parent())
	if target != null:
		_pop(target)
		var rect := target.get_global_rect()
		var at := rect.get_center() - Vector2(0, rect.size.y * 0.62)
		if target in jester_views:
			at = rect.get_center() + Vector2(0, rect.size.y * 0.66)
		if text != "":
			Feel.float_text(text, at, colour, size)
		Feel.burst(rect.get_center(), colour, 16 if kind == "xmult" else 8)
	elif text != "":
		Feel.float_text(text, lbl_mult.get_parent().get_global_rect().get_center() - Vector2(0, 18), colour, size)
	Feel.kick({"points": 0.12, "mult": 0.25, "xmult": 0.9}.get(kind, 0.0))
	if kind == "xmult":
		Feel.shake(2.0)
		Feel.flash(Color("ff6a3a"), 0.45)
	elif kind == "mult":
		Feel.flash(UiTheme.MULT, 0.15)


## 4 for 4.0, 1.5 for 1.5: Mult amounts as people write them.
func _short(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(roundf(amount)))
	return ("%.2f" % amount).rstrip("0")


## The hand's total slams down over the played cards, sized and shaken by how big it is,
## gold when it wins the show, then flies into the show score.
func _slam(total: float, won: bool) -> void:
	var l := UiTheme.title(UiTheme.number(total), 30, UiTheme.GOLD if won else UiTheme.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(area_w, 44)
	l.position = Vector2(0, 30)
	l.pivot_offset = l.size / 2.0
	middle.add_child(l)
	_punch(lbl_points.get_parent())
	_punch(lbl_mult.get_parent())
	var share := total / maxf(1.0, float(run.show_target))
	Feel.play("jackpot" if share >= 1.0 else "slam")
	Feel.buzz(25)
	Feel.shake(clampf(log(total + 10.0) / log(10.0), 1.5, 6.0))
	Feel.kick(1.2)
	Feel.flash(UiTheme.GOLD if won else UiTheme.MULT, clampf(0.25 + share * 0.5, 0.25, 0.9))
	Feel.burst(l.get_global_rect().get_center(), UiTheme.GOLD if won else UiTheme.MULT, 30)
	if Settings.reduce_motion:
		await _wait(0.6)
		l.queue_free()
		return
	l.scale = Vector2(2.6, 2.6)
	var t := l.create_tween()
	t.tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.45)
	var target := lbl_score.get_global_rect().get_center() - l.size / 2.0
	t.tween_property(l, "global_position", target, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(l, "scale", Vector2(0.4, 0.4), 0.25)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.25)
	await t.finished
	l.queue_free()


## A big word across the table that bounces in, rains confetti and fades: "SHOW WON!".
func _banner(text: String, colour: Color) -> void:
	var l := UiTheme.title(text, 38, colour)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(stage_w, 56)
	l.position = Vector2(0, 120)
	l.pivot_offset = l.size / 2.0
	stage.add_child(l)
	var area := stage.get_global_rect()
	for i in 6:
		Feel.burst(area.position + Vector2(area.size.x * (0.15 + 0.14 * i), area.size.y * 0.4), [UiTheme.GOLD, UiTheme.MULT, UiTheme.POINTS, UiTheme.GOOD][i % 4], 18)
	if not Settings.reduce_motion:
		l.scale = Vector2(0.2, 0.2)
		l.rotation = -0.2
		var t := l.create_tween().set_parallel()
		t.tween_property(l, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(l, "rotation", 0.0, 0.3)
	await _wait(1.0)
	var out := l.create_tween()
	out.tween_property(l, "modulate:a", 0.0, 0.25)
	await out.finished
	l.queue_free()


## Where each hand card is on screen right now, so played cards can fly from there.
func _hand_positions() -> Dictionary:
	var out := {}
	for child in hand_row.get_children():
		if not child.is_queued_for_deletion():
			out[int(child.tag["id"])] = child.global_position
	return out


## Sends a card from where it was on screen to its place, with a little spin.
func _fly(v: Control, from_global: Vector2, to: Vector2, delay: float) -> void:
	if Settings.reduce_motion or from_global == Vector2.ZERO:
		v.position = to
		return
	v.global_position = from_global
	v.rotation = randf_range(-0.25, 0.25)
	var t := v.create_tween().set_parallel()
	t.tween_property(v, "position", to, 0.24).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(v, "rotation", 0.0, 0.24).set_delay(delay)


## Sends a played card off the table to the right once it has scored.
func _fly_off(v: Control, delay: float) -> void:
	var t := v.create_tween().set_parallel()
	if not Settings.reduce_motion:
		t.tween_property(v, "position", v.position + Vector2(area_w, -30), 0.3).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		t.tween_property(v, "rotation", 0.5, 0.3).set_delay(delay)
	t.tween_property(v, "modulate:a", 0.0, 0.3).set_delay(delay)


## A card or Jester that just scored jumps and rocks (a rocking card in the hand only jumps).
func _pop(v: Control) -> void:
	v.pivot_offset = v.size / 2.0
	if Settings.reduce_motion:
		return
	var t := v.create_tween()
	t.tween_property(v, "scale", Vector2(1.22, 1.22), 0.06)
	t.tween_property(v, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if v is CardView and (v as CardView).sway < 0:
		var r := v.create_tween()
		r.tween_property(v, "rotation", 0.12, 0.05)
		r.tween_property(v, "rotation", -0.08, 0.06)
		r.tween_property(v, "rotation", 0.0, 0.06)


## The Points or Mult box punches out and flashes.
func _punch(box: Control) -> void:
	_pulse(box)
	box.modulate = Color(1.7, 1.7, 1.7)
	var t := box.create_tween()
	t.tween_property(box, "modulate", Color.WHITE, 0.18)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## Counts a label up to its new value with ticks that rise in pitch (at once with Reduce
## motion).
func _count_up(label: Label, from: float, to: float) -> void:
	if Settings.reduce_motion or to <= from:
		label.text = UiTheme.number(to)
		return
	var ticks := [0]
	var t := create_tween()
	t.tween_method(func(v: float) -> void:
		label.text = UiTheme.number(floorf(v))
		var step := int((v - from) / (to - from) * 10.0)
		if step > ticks[0]:
			ticks[0] = step
			Feel.play("tick", 1.0 + step * 0.06), from, to, 0.45)
	await t.finished


func _pulse(v: Control) -> void:
	v.pivot_offset = v.size / 2.0
	var t := create_tween()
	t.tween_property(v, "scale", Vector2(1.15, 1.15), 0.06)
	t.tween_property(v, "scale", Vector2.ONE, 0.08)


# --- descriptions ---

func _selected_def_id() -> String:
	var i := int(selection.get("index", -1))
	match str(selection.get("zone", "")):
		"zanni":
			return run.zanni[i].def_id
		"consumable":
			return run.consumables[i].def_id
		"offer":
			return str(run.shop.offers[i]["id"])
		"pack":
			return str(run.shop.packs[i]["id"])
		"warrant":
			return run.town_warrant if i == 0 else run.shop.extra_warrant
		"pack_item":
			return str(run.pack["items"][i].get("id", ""))
	return ""


func _describe_selection(id: String) -> String:
	var zone := str(selection.get("zone", ""))
	var i := int(selection.get("index", -1))
	if id == "":
		var desc: Dictionary = run.shop.offers[i]["card"] if zone == "offer" else run.pack["items"][i]["card"]
		var card := _card_from(desc)
		return _card_name(card) + "\n" + _describe_card(card)
	var lines := [UiTheme.text_of(id)]
	var gloss := TranslationServer.translate(id + ".gloss")
	if gloss != id + ".gloss":
		lines.push_front("(" + gloss + ")")
	var def := ContentDB.get_def(id)
	if def != null and KIND_HELP.has(def.kind):
		var what: String = KIND_HELP[def.kind]
		if def.kind == "zanni":
			what = CardView.RARITY_NAMES[clampi(def.rarity, 0, 3)] + " " + what
		lines.append("")
		lines.append(what)
	if zone == "zanni":
		var z := run.zanni[i]
		if z.edition != "":
			lines.append("%s: %s" % [UiTheme.name_of(z.edition), UiTheme.text_of(z.edition)])
		if z.state.get("eternal", false):
			lines.append("Eternal: can't be sold or destroyed.")
		if z.state.has("perish"):
			lines.append("Perishable: %d shows left." % int(z.state["perish"]))
		if z.state.get("rented", false):
			lines.append("Rented: -3 ducats at every cash-out.")
	return "\n".join(lines)


func _card_name(card: PlayingCard) -> String:
	if not card.has_rank():
		return "Marble card"
	return "%s of %s" % [RANK_NAMES.get(card.rank, str(card.rank)), SUITS[card.suit]]


func _describe_card(card: PlayingCard) -> String:
	var lines := ["%d Points" % (card.base_points() + card.bonus_points)]
	for mod in [card.enhancement, card.edition, card.seal]:
		if mod != "":
			lines.append("%s: %s" % [UiTheme.name_of(mod), UiTheme.text_of(mod)])
	if card.debuffed:
		lines.append("Debuffed: scores nothing this show.")
	return "\n".join(lines)


func _hand_name(hand_type: String) -> String:
	return TranslationServer.translate("hand." + hand_type)


## An engine message as a sentence: first letter up, a full stop at the end.
func _sentence(text: String) -> String:
	return text.left(1).to_upper() + text.substr(1) + "."


# --- helpers ---

func _hand_card(card_id: int) -> PlayingCard:
	for card in run.hand:
		if card.id == card_id:
			return card
	return null


func _card_from(desc: Dictionary) -> PlayingCard:
	var card := PlayingCard.make(-1, int(desc["rank"]), int(desc["suit"]))
	card.enhancement = str(desc.get("enh", ""))
	card.edition = str(desc.get("ed", ""))
	card.seal = str(desc.get("seal", ""))
	return card


func _wrapped(text: String, font_size: int, width := 148.0) -> Label:
	var l := UiTheme.label(text, font_size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	return l


func _same(a: Dictionary, b: Dictionary) -> bool:
	return not a.is_empty() and a.get("zone") == b.get("zone") and a.get("index") == b.get("index")


func _clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
