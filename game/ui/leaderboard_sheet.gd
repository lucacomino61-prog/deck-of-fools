class_name LeaderboardSheet
extends Sheet
## The leaderboards: today's daily run, the best single hand ever played, and the highest
## town reached on each stake. The player's own row is highlighted, and shown under the
## list when they're further down.

const TABS := [["daily", "Daily run"], ["best_hand", "Best hand"], ["town", "Highest town"]]
const ROWS := 10

var kind := "daily"
var stake := 1
var _result: Dictionary = {}
var _loading := true


func _init(start := "daily") -> void:
	kind = start
	title_text = "Leaderboards"
	panel_size = Vector2(440, 336)


func _ready() -> void:
	super._ready()
	_load()


func _load() -> void:
	_loading = true
	rebuild()
	var res := await Online.leaderboard(kind, stake)
	if not is_inside_tree():
		return
	_result = res
	_loading = false
	rebuild()


func _build() -> void:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	for tab in TABS:
		var b := UiTheme.button(tab[1], func() -> void: _switch(tab[0]), 10, UiTheme.PANEL_LIGHT.lightened(0.15) if kind == tab[0] else UiTheme.PANEL_DARK)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
	body.add_child(tabs)
	if kind == "town":
		var picker := HBoxContainer.new()
		picker.add_child(UiTheme.button("<", func() -> void: _stake(-1)))
		var l := UiTheme.label("Stake %d: %s" % [stake, UiTheme.name_of(ContentDB.pool("stake")[stake - 1].id)], 10)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picker.add_child(l)
		picker.add_child(UiTheme.button(">", func() -> void: _stake(1)))
		body.add_child(picker)
	elif kind == "daily":
		var setup := Online.daily_setup()
		body.add_child(UiTheme.label("%s: %s deck, Stake 1. Ranked by town reached, then best hand." % [setup["date"], UiTheme.name_of(setup["deck"])], 10, UiTheme.MUTED))
	if _loading:
		body.add_child(UiTheme.label("Loading…", 10, UiTheme.MUTED))
		return
	if not _result.get("ok", false):
		body.add_child(words(str(_result.get("error", "")) if _result.get("error", "") != "" else "Leaderboards need a connection.", 10, UiTheme.MUTED))
		return
	var data: Dictionary = _result["data"]
	var entries: Array = data.get("entries", [])
	if entries.is_empty():
		body.add_child(words("Nobody's on this board yet. Be the first!", 10, UiTheme.MUTED))
		return
	for entry in entries.slice(0, ROWS):
		body.add_child(_row(entry))
	var me = data.get("me")
	if me is Dictionary and int(me["rank"]) > ROWS:
		body.add_child(UiTheme.label("…", 10, UiTheme.MUTED))
		body.add_child(_row(me))


func _row(entry: Dictionary) -> PanelContainer:
	var mine := bool(entry.get("me", false))
	var panel := PanelContainer.new()
	var style := UiTheme.box(UiTheme.GOLD.darkened(0.6) if mine else UiTheme.PANEL_DARK, UiTheme.GOLD if mine else UiTheme.PANEL_LIGHT, 3)
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	panel.add_child(row)
	var rank := int(entry["rank"])
	var rank_label := UiTheme.title("%d" % rank, 11, UiTheme.GOLD if rank <= 3 else UiTheme.TEXT)
	rank_label.custom_minimum_size = Vector2(30, 0)
	row.add_child(rank_label)
	var name_label := UiTheme.label(str(entry["name"]) + ("  (you)" if mine else ""), 10, UiTheme.TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var value := ""
	match kind:
		"daily":
			value = "Town %d   %s" % [int(entry["town"]), UiTheme.number(float(entry["best_hand"]))]
		"best_hand":
			value = UiTheme.number(float(entry["best_hand"]))
		"town":
			value = "Town %d" % int(entry["town"])
	row.add_child(UiTheme.label(value, 10, UiTheme.GOLD))
	return panel


func _switch(new_kind: String) -> void:
	Feel.play("click")
	kind = new_kind
	_load()


func _stake(step: int) -> void:
	Feel.play("click")
	stake = clampi(stake + step, 1, Unlocks.TOP_STAKE)
	_load()
