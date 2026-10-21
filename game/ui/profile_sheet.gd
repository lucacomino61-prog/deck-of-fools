class_name ProfileSheet
extends Sheet
## The player: their name, how their progress is kept (a guest, or an account), the cloud
## save, stats (win rate per deck and stake, favourite Jester, best hand, highest town,
## collection), and signing out or deleting the account.

var _stats: Dictionary = {}
var _loaded := false
var _confirm_delete := false
var _status: Label


func _init() -> void:
	title_text = "Profile"
	panel_size = Vector2(560, 340)


func _ready() -> void:
	super._ready()
	Online.account_changed.connect(_on_account)
	_load_stats()


func _load_stats() -> void:
	if not Online.signed_in():
		_loaded = true
		rebuild()
		return
	var res := await Online.stats()
	if not is_inside_tree():
		return
	_stats = res["data"] if res["ok"] else {}
	_loaded = true
	rebuild()


func _on_account() -> void:
	if is_inside_tree():
		_loaded = false
		_load_stats()


func _build() -> void:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(240, 0)
	left.add_theme_constant_override("separation", 5)
	columns.add_child(left)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 3)
	columns.add_child(right)
	_build_account(left)
	_build_stats(right)


func _build_account(col: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	var name_field := field("Your name")
	name_field.text = str(Online.user.get("name", ""))
	name_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_field)
	row.add_child(UiTheme.button("Save", func() -> void: _rename(name_field.text)))
	col.add_child(row)
	if not Online.signed_in():
		col.add_child(_wrapped("You're offline. Your progress is kept on this device and reaches the cloud when you're back online.", UiTheme.MUTED))
	elif Online.is_guest():
		col.add_child(_wrapped("You're playing as a guest. Create an account to keep your progress safe and play on other devices.", UiTheme.MUTED))
		col.add_child(UiTheme.button("Save your progress", func() -> void: _open_account("signup"), 12, UiTheme.MULT))
		col.add_child(UiTheme.button("I have an account: log in", func() -> void: _open_account("login")))
	else:
		var email := str(Online.user.get("email", ""))
		if email != "":
			col.add_child(UiTheme.label(email, 10, UiTheme.TEXT))
			if bool(Online.user.get("verified", false)):
				col.add_child(UiTheme.label("Email confirmed", 10, UiTheme.GOOD))
			else:
				col.add_child(_wrapped("Not confirmed yet: check your inbox for our email.", UiTheme.GOLD))
				col.add_child(UiTheme.button("Send the email again", _resend))
		var signins: Dictionary = Online.user.get("signins", {})
		var ways := []
		for way in ["password", "apple", "google"]:
			if bool(signins.get(way, false)):
				ways.append({"password": "email", "apple": "Apple", "google": "Google"}[way])
		col.add_child(UiTheme.label("Signs in with: " + ", ".join(ways), 10, UiTheme.MUTED))
	var cloud := "Cloud save: up to date" if not Online.dirty else ("Cloud save: will update in a moment" if Online.online else "Cloud save: waiting for a connection")
	col.add_child(UiTheme.label(cloud if Online.signed_in() else "Cloud save: offline", 10, UiTheme.MUTED))
	_status = _wrapped("", UiTheme.MULT.lightened(0.3))
	col.add_child(_status)
	if Online.signed_in():
		var buttons := HBoxContainer.new()
		buttons.add_theme_constant_override("separation", 6)
		if not Online.is_guest():
			buttons.add_child(UiTheme.button("Sign out", _sign_out))
		var delete := UiTheme.button("Tap again to delete everything" if _confirm_delete else "Delete account", _delete, 10, UiTheme.MULT.darkened(0.3) if _confirm_delete else Color.TRANSPARENT)
		buttons.add_child(delete)
		col.add_child(buttons)


func _build_stats(col: VBoxContainer) -> void:
	col.add_child(UiTheme.title("Stats", 13, UiTheme.GOLD))
	var p := Game.profile
	var total_cards := 0
	for kind in ["zanni", "tarocchi", "sign", "omen", "warrant"]:
		total_cards += ContentDB.pool(kind).size()
	var collection := "%d of %d (%d%%)" % [p.discovered.size(), total_cards, roundi(100.0 * p.discovered.size() / maxf(1, total_cards))]
	if not _loaded:
		col.add_child(UiTheme.label("Loading…", 10, UiTheme.MUTED))
		return
	if _stats.is_empty():
		col.add_child(pair("Runs won", str(p.total_wins)))
		col.add_child(pair("Runs lost", str(p.runs_lost)))
		col.add_child(pair("Collection", collection))
		col.add_child(_wrapped("More stats appear when you're online.", UiTheme.MUTED))
		return
	var runs := int(_stats.get("runs", 0))
	var wins := int(_stats.get("wins", 0))
	col.add_child(pair("Runs played", str(runs)))
	col.add_child(pair("Wins", "%d (%d%%)" % [wins, roundi(100.0 * wins / maxf(1, runs))]))
	col.add_child(pair("Best hand", UiTheme.number(float(_stats.get("best_hand", 0)))))
	col.add_child(pair("Highest town", str(int(_stats.get("best_town", 0)))))
	col.add_child(pair("Collection", collection))
	var favourite = _stats.get("favourite_jester")
	if favourite is String and ContentDB.get_def(favourite) != null:
		col.add_child(pair("Favourite Jester", UiTheme.name_of(favourite), UiTheme.GOLD))
	var per_deck: Array = _stats.get("per_deck", [])
	if not per_deck.is_empty():
		col.add_child(UiTheme.label("Win rate by deck and stake", 10, UiTheme.GOLD))
		per_deck.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["runs"]) > int(b["runs"]))
		for entry in per_deck.slice(0, 5):
			var deck_runs := int(entry["runs"])
			col.add_child(pair("%s, Stake %d" % [UiTheme.name_of(str(entry["deck"])), int(entry["stake"])], "%d of %d (%d%%)" % [int(entry["wins"]), deck_runs, roundi(100.0 * int(entry["wins"]) / maxf(1, deck_runs))]))


func _wrapped(text: String, colour: Color) -> Label:
	var l := UiTheme.label(text, 10, colour)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(240, 0)
	return l


func _open_account(mode: String) -> void:
	Feel.play("click")
	get_parent().add_child(AccountSheet.new(mode))


func _rename(text: String) -> void:
	var res := await Online.rename(text.strip_edges())
	if is_inside_tree():
		_show(res, "Saved.")


func _resend() -> void:
	var res := await Online.resend_verification()
	if is_inside_tree():
		_show(res, "Sent. Check your inbox.")


func _sign_out() -> void:
	await Online.logout()
	if is_inside_tree():
		rebuild()


func _delete() -> void:
	if not _confirm_delete:
		Feel.play("error")
		_confirm_delete = true
		rebuild()
		return
	var res := await Online.delete_account()
	if not is_inside_tree():
		return
	_confirm_delete = false
	_show(res, "Your account and everything stored about it are deleted.")
	if res["ok"]:
		rebuild()


func _show(res: Dictionary, success: String) -> void:
	if _status == null:
		return
	_status.add_theme_color_override("font_color", UiTheme.GOOD if res["ok"] else UiTheme.MULT.lightened(0.3))
	_status.text = success if res["ok"] else str(res["error"])
