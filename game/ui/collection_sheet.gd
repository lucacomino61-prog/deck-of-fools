class_name CollectionSheet
extends Sheet
## Every card in the game, by kind. Jesters, Tarocchi, Signs, Omens and Warrants count once
## found (seen in a shop or a pack, or owned): those show face up, the rest face down, and a
## rare Jester still locked says what unlocks it. Lazzi (duos), Favors, Patrons, decks and
## the cities of the Map of Italy are listed in full, for reference. Tap a card for its details. Cards appear a few per frame, so opening
## a page doesn't stall while their faces are drawn.

const TABS := [["zanni", "Jesters"], ["lazzo", "Lazzi"], ["tarocchi", "Tarocchi"], ["sign", "Signs"], ["omen", "Omens"],
	["warrant", "Warrants"], ["favor", "Favors"], ["patron", "Patrons"], ["deck", "Decks"], ["city", "Cities"]]
const COLLECTED := ["zanni", "tarocchi", "sign", "omen", "warrant"]
const KIND_NAMES := {"zanni": "Jester", "tarocchi": "Tarocchi", "sign": "Sign", "omen": "Omen",
	"warrant": "Warrant", "favor": "Favor", "patron": "Patron", "deck": "Deck", "lazzo": "Lazzo", "city": "City"}
const ROWS := 3
## Cards as big as three rows allow; as many columns as the sheet's width takes.
const CARD := Vector2(54, 76)
const GAP := 8.0

var kind := "zanni"
var page := 0
var _grid: GridContainer
var _columns := 10


func _init(start := "zanni") -> void:
	kind = start
	title_text = "Collection"
	panel_size = Vector2(600, 344)
	wide = true


func _build() -> void:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 3)
	for t in TABS:
		var b := UiTheme.button(t[1], func() -> void:
			Feel.play("click")
			kind = t[0]
			page = 0
			rebuild(), 10, UiTheme.GOLD.darkened(0.35) if kind == t[0] else UiTheme.PANEL_DARK)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
	body.add_child(tabs)
	var defs := ContentDB.pool(kind)
	_columns = maxi(8, int((panel_size.x - 12.0 + GAP) / (CARD.x + GAP)))
	var per_page := _columns * ROWS
	var pages := maxi(1, ceili(defs.size() / float(per_page)))
	page = clampi(page, 0, pages - 1)
	var top := HBoxContainer.new()
	var count := UiTheme.label(_count_text(defs), 11, UiTheme.GOLD)
	count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(count)
	if pages > 1:
		top.add_child(UiTheme.button("<", func() -> void: _turn(-1, pages), 10))
		top.add_child(UiTheme.label("  Page %d of %d  " % [page + 1, pages], 10, UiTheme.MUTED))
		top.add_child(UiTheme.button(">", func() -> void: _turn(1, pages), 10))
	body.add_child(top)
	_grid = GridContainer.new()
	_grid.columns = _columns
	_grid.add_theme_constant_override("h_separation", int(GAP))
	_grid.add_theme_constant_override("v_separation", 6)
	body.add_child(_grid)
	_fill(defs.slice(page * per_page, (page + 1) * per_page), _grid)


func _turn(step: int, pages: int) -> void:
	Feel.play("click")
	page = (page + step + pages) % pages
	rebuild()


func _count_text(defs: Array) -> String:
	if not COLLECTED.has(kind):
		return "%d %s" % [defs.size(), TABS.filter(func(t: Array) -> bool: return t[0] == kind)[0][1]]
	var found := defs.filter(func(d: ContentDef) -> bool: return _found(d)).size()
	if kind == "zanni":
		return "Found %d of %d   -   Maestri: %d of %d" % [found, defs.size(), Game.profile.maestri().size(), defs.size()]
	return "Found %d of %d" % [found, defs.size()]


## Adds the page's cards a few per frame (each new face is drawn the frame it appears).
func _fill(defs: Array, grid: GridContainer) -> void:
	for i in defs.size():
		if i > 0 and i % 5 == 0:
			await get_tree().process_frame
			if not is_instance_valid(grid) or grid.is_queued_for_deletion():
				return
		grid.add_child(_cell(defs[i]))


func _found(d: ContentDef) -> bool:
	return not COLLECTED.has(d.kind) or Game.profile.discovered.has(d.id)


func _cell(d: ContentDef) -> Control:
	var v := CardView.new(CARD)
	v.kind = d.kind
	v.def_id = d.id
	v.face_down = not _found(d)
	if d.kind == "zanni":
		var fame := Game.profile.fame_of(d.id)
		v.maestro = fame >= Fame.MAESTRO
		v.stars = Fame.stars(fame)
	v.tapped.connect(func(_view: CardView) -> void: _details(d))
	v.long_pressed.connect(func(_view: CardView) -> void: _details(d))
	return v


func _details(d: ContentDef) -> void:
	Feel.play("select")
	var big := CardView.new(Vector2(110, 154))
	big.kind = d.kind
	big.def_id = d.id
	if d.kind == "zanni":
		big.maestro = Game.profile.fame_of(d.id) >= Fame.MAESTRO
		big.stars = Fame.stars(Game.profile.fame_of(d.id))
	if not _found(d):
		big.face_down = true
		var how := "Find it in a shop or a pack (or own it) to add it to your collection."
		if not Game.profile.is_unlocked(d.id):
			how = "Locked. To unlock it: " + TranslationServer.translate("feat." + str(Unlocks.RARE_FEATS[d.id])) + "."
		UiTheme.show_sheet(DetailSheet.new(big, "Not found yet", [KIND_NAMES.get(d.kind, ""), how]))
		return
	var what: String = KIND_NAMES.get(d.kind, "")
	if d.kind == "zanni":
		what = CardView.RARITY_NAMES[clampi(d.rarity, 0, 3)] + " Jester"
	var lines := [what, UiTheme.text_of(d.id)]
	var gloss := TranslationServer.translate(d.id + ".gloss")
	if gloss != d.id + ".gloss":
		lines.append("(" + gloss + ")")
	if d.kind == "deck" and not Game.profile.deck_unlocked(d.id):
		lines.append("Locked: " + _deck_rule(d.id))
	if d.kind == "zanni" and Game.profile.badges.has(d.id):
		lines.append("Won with it up to Stake %d" % int(Game.profile.badges[d.id]))
	if d.kind == "zanni":
		lines.append(RunScreen._fame_line(d.id))
		if Game.profile.fame_of(d.id) >= Fame.MAESTRO:
			lines.append("As %s: %s" % [Fame.title(d.id, UiTheme.name_of(d.id)), "+%d ducats at each cash-out" % Fame.FLAT_DUCATS if Fame.FLAT.has(d.id) else "its numbers are x1.25"])
	if d.kind == "patron":
		for k in [["enter", "Arriving"], ["beaten", "Beaten"], ["gloat", "Winning"], ["revenge", "Back for revenge"]]:
			lines.append("%s: “%s”" % [k[1], TranslationServer.translate("%s.%s" % [d.id, k[0]])])
	if d.kind == "lazzo":
		var parts: Array = d.data["parts"]
		lines.append("Merge %s and %s in the Market. It takes one slot and does both their effects, about 1.5x stronger." % [UiTheme.name_of(parts[0]), UiTheme.name_of(parts[1])])
	if d.kind == "city":
		lines.append("Shop: " + TranslationServer.translate(d.id + ".lean"))
	UiTheme.show_sheet(DetailSheet.new(big, UiTheme.name_of(d.id), lines))


func _deck_rule(deck_id: String) -> String:
	var parts := str(Unlocks.DECK_RULES.get(deck_id, "")).split(":")
	if parts[0] == "discover":
		return "find %s cards for your collection." % parts[1]
	return "win a run with the %s deck." % UiTheme.name_of(parts[1])
