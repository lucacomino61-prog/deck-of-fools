class_name WagonSheet
extends Sheet
## The troupe's wagon (batch 13): the scudi every run earns, spent on props (small starting
## perks, carried one at a time, two once the second slot is bought; off in daily, seeded and
## challenge runs), the wardrobe (paint and trims for the wagon, table cloths for the shows,
## card backs, curtains for the theatre boxes), and the notice board (locked decks, rare
## Jesters and challenges, bought early). The wagon at the top wears what's chosen.

const TABS := [["props", "Props"], ["wardrobe", "Wardrobe"], ["board", "Notice board"]]
const SLOTS := [["paint", "Paint"], ["trim", "Trims"], ["cloth", "Table cloth"], ["back", "Card back"], ["curtain", "Curtains"]]

var tab := "props"
## The cosmetic picked in the wardrobe (shown on the wagon before it's bought).
var picked := ""
var intro := ""


func _init(first_words := "") -> void:
	intro = first_words
	title_text = "The Wagon"
	panel_size = Vector2(600, 344)
	wide = true


func _build() -> void:
	var p := Game.profile
	title_text = "The Wagon  -  %d scudi" % p.scudi
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	body.add_child(top)
	top.add_child(_WagonPreview.new(_preview_paint(), _preview_trims()))
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 3)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(right)
	var words := intro if intro != "" else "Every run pays scudi: 1 a show won, 1 a Scenario performed in full, 2 an Encore hit, 5 for a won run (plus 1 per stake above 1)."
	right.add_child(_line(words, 9, UiTheme.MUTED, panel_size.x - 140.0))
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 3)
	for t in TABS:
		var b := UiTheme.button(t[1], func() -> void:
			Feel.play("click")
			tab = t[0]
			picked = ""
			rebuild(), 10, UiTheme.PANEL_LIGHT.lightened(0.15) if tab == t[0] else UiTheme.PANEL_DARK)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
	right.add_child(tabs)
	match tab:
		"props":
			_props()
		"wardrobe":
			_wardrobe()
		"board":
			_board()


# --- props ---

func _props() -> void:
	var p := Game.profile
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 6)
	var carried := "Carrying %d of %d: %s" % [p.carried.size(), p.prop_slots, ", ".join(p.carried.map(func(id: String) -> String: return UiTheme.name_of(id))) if not p.carried.is_empty() else "nothing yet"]
	var l := _line(carried + ". Props work in normal runs and the campaign.", 10, UiTheme.GOLD, panel_size.x - 200.0)
	slots.add_child(l)
	if p.prop_slots < 2:
		var b := UiTheme.button("Second slot (%d)" % WagonCards.PROP_SLOT_PRICE, func() -> void: _buy(p.buy_prop_slot()), 9, UiTheme.GOLD.darkened(0.35))
		b.disabled = not p.can_afford(WagonCards.PROP_SLOT_PRICE)
		slots.add_child(b)
	body.add_child(slots)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 4)
	body.add_child(grid)
	for d in ContentDB.pool("prop"):
		grid.add_child(_prop_cell(d))


func _prop_cell(d: ContentDef) -> Control:
	var p := Game.profile
	var owned := p.props_owned.has(d.id)
	var on := p.carried.has(d.id)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL_DARK, UiTheme.GOLD if on else (UiTheme.PANEL_LIGHT if owned else UiTheme.PANEL), 4))
	panel.custom_minimum_size = Vector2(floorf((panel_size.x - 30.0) / 2.0), 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	panel.add_child(row)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	col.add_child(UiTheme.title(UiTheme.name_of(d.id), 11, UiTheme.GOLD if on else UiTheme.TEXT))
	col.add_child(_line(UiTheme.text_of(d.id), 9, UiTheme.MUTED, floorf((panel_size.x - 30.0) / 2.0) - 96.0))
	var b: Button
	if not owned:
		b = UiTheme.button("Buy %d" % d.cost, func() -> void: _buy(p.buy_prop(d.id)), 9, UiTheme.GOLD.darkened(0.35))
		b.disabled = not p.can_afford(d.cost)
	elif on:
		b = UiTheme.button("Put down", func() -> void:
			p.carry_prop(d.id, false)
			_saved(), 9, UiTheme.PANEL_LIGHT)
	else:
		b = UiTheme.button("Carry", func() -> void:
			p.carry_prop(d.id, true)
			_saved(), 9, UiTheme.POINTS.darkened(0.2))
	b.custom_minimum_size = Vector2(70, 0)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(b)
	return panel


# --- the wardrobe ---

func _wardrobe() -> void:
	var p := Game.profile
	for slot in SLOTS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		var name_label := UiTheme.label(slot[1], 10, UiTheme.MUTED)
		name_label.custom_minimum_size = Vector2(64, 0)
		row.add_child(name_label)
		for c in WagonCards.COSMETICS[slot[0]]:
			var id: String = c["id"]
			var owned := p.cosmetics.has(id)
			if c.get("campaign", false) and not owned:
				continue
			var worn := _is_worn(slot[0], id)
			var colour: Color = c["colour"]
			var text := _short(id) + (" - on" if worn else "")
			var face := colour if owned else colour.darkened(0.45)
			var b := UiTheme.button(("> " if picked == id else "") + text, func() -> void:
				Feel.play("select")
				picked = id
				rebuild(), 9, face)
			# Dark letters on a light swatch (white paint, gold lanterns), light ones otherwise.
			var ink := UiTheme.OUTLINE if face.get_luminance() > 0.55 else UiTheme.TEXT
			for state in ["font_color", "font_hover_color", "font_pressed_color"]:
				b.add_theme_color_override(state, ink)
			row.add_child(b)
		body.add_child(row)
	body.add_child(_picked_row())
	body.add_child(_line("Campaign rewards (Oro Doge, the sail, La Corte) join the wardrobe when you clear their chapters.", 9, UiTheme.MUTED, panel_size.x - 30.0))


func _picked_row() -> Control:
	var p := Game.profile
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	if picked == "":
		row.add_child(UiTheme.label("Tap a colour or a trim to see it on the wagon.", 9, UiTheme.TEXT))
		return row
	var c := WagonCards.cosmetic(picked)
	var slot: String = c["slot"]
	var owned := p.cosmetics.has(picked)
	var l := UiTheme.title(UiTheme.name_of(picked), 11, UiTheme.GOLD)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	if not owned:
		var b := UiTheme.button("Buy %d" % int(c["price"]), func() -> void:
			if p.buy_cosmetic(picked):
				p.wear(slot, picked)
				_buy(true)
			else:
				_buy(false), 10, UiTheme.GOLD.darkened(0.35))
		b.disabled = not p.can_afford(int(c["price"]))
		row.add_child(b)
	elif _is_worn(slot, picked):
		row.add_child(UiTheme.button("Take off", func() -> void:
			p.wear(slot, picked if slot == "trim" else "")
			_saved(), 10, UiTheme.PANEL_LIGHT))
	else:
		row.add_child(UiTheme.button("Wear", func() -> void:
			p.wear(slot, picked)
			_saved(), 10, UiTheme.POINTS.darkened(0.2)))
	return row


func _is_worn(slot: String, id: String) -> bool:
	var p := Game.profile
	if slot == "trim":
		return (p.worn.get("trims", []) as Array).has(id)
	return str(p.worn.get(slot, "")) == id


## A cosmetic's short name for its button: the first word of a paint, cloth or curtain.
func _short(id: String) -> String:
	var full := UiTheme.name_of(id)
	return full.get_slice(" ", 0) if id.begins_with("paint_") or id.begins_with("cloth_") or id.begins_with("curtain_") else full


func _preview_paint() -> Color:
	if picked.begins_with("paint_"):
		return WagonCards.cosmetic(picked)["colour"]
	return WagonArt.worn_paint()


func _preview_trims() -> Array:
	var trims: Array = WagonArt.worn_trims().duplicate()
	if picked.begins_with("trim_") and not trims.has(picked):
		trims.append(picked)
	return trims


# --- the notice board ---

func _board() -> void:
	var p := Game.profile
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 236)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 3)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var any := false
	for section in [["deck", "Decks"], ["zanni", "Rare Jesters"], ["challenge", "Challenges"]]:
		var ids: Array = ContentDB.pool(section[0]).map(func(d: ContentDef) -> String: return d.id) \
			.filter(func(id: String) -> bool: return p.unlock_for_sale(id))
		if ids.is_empty():
			continue
		any = true
		list.add_child(UiTheme.title("%s  -  %d scudi each" % [section[1], int(WagonCards.UNLOCK_PRICES[section[0]])], 10, UiTheme.GOLD))
		for id in ids:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			var name_label := UiTheme.label(UiTheme.name_of(id), 10, UiTheme.TEXT)
			name_label.custom_minimum_size = Vector2(150, 0)
			row.add_child(name_label)
			var how := _line(_rule_of(section[0], id), 9, UiTheme.MUTED, panel_size.x - 320.0)
			how.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(how)
			var price := int(WagonCards.UNLOCK_PRICES[section[0]])
			var b := UiTheme.button("Buy %d" % price, func() -> void: _buy(p.buy_unlock(id)), 9, UiTheme.GOLD.darkened(0.35))
			b.disabled = not p.can_afford(price)
			row.add_child(b)
			list.add_child(row)
	if not any:
		list.add_child(UiTheme.label("Everything is unlocked already.", 10, UiTheme.TEXT))


## How a card unlocks without buying it.
func _rule_of(kind: String, id: String) -> String:
	match kind:
		"deck":
			var parts := str(Unlocks.DECK_RULES.get(id, "")).split(":")
			if parts[0] == "discover":
				return "Or find %s cards for your collection." % parts[1]
			return "Or win a run with the %s deck." % UiTheme.name_of(parts[1])
		"zanni":
			return "Or: " + TranslationServer.translate("feat." + str(Unlocks.RARE_FEATS.get(id, ""))) + "."
		"challenge":
			return "Or win more runs (each win opens %d challenges)." % Unlocks.CHALLENGES_PER_WIN
	return ""


# --- helpers ---

func _buy(done: bool) -> void:
	Feel.play("jackpot" if done else "error")
	if done:
		_saved()


func _saved() -> void:
	Game.save_profile()
	rebuild()


func _line(text: String, font_size: int, colour: Color, width: float) -> Label:
	var l := UiTheme.label(text, font_size, colour)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	return l


## The wagon, large, in the paint and trims given.
class _WagonPreview extends Control:
	var paint: Color
	var trims: Array

	func _init(wagon_paint: Color, wagon_trims: Array) -> void:
		paint = wagon_paint
		trims = wagon_trims
		custom_minimum_size = Vector2(110, 62)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("201430"))
		draw_rect(Rect2(0, size.y - 8, size.x, 8), Color("3a2a1a"))
		WagonArt.draw(self, Vector2(size.x / 2.0 - 6, size.y - 6), 1.35, paint, trims)
		draw_rect(Rect2(Vector2.ZERO, size), UiTheme.GOLD.darkened(0.3), false, 1.0)
