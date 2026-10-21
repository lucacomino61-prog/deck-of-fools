class_name AccountSheet
extends Sheet
## Creating an account, logging in, or asking for a password reset. Signing up as a guest
## keeps everything played so far. Apple and Google buttons appear where the phone apps'
## native sign-in exists (M9); elsewhere a line says so.

var mode := "signup"
## A line above the form, e.g. why we're asking ("Save your progress…").
var intro := ""
var _name: LineEdit
var _email: LineEdit
var _password: LineEdit
var _status: Label
var _go: Button


func _init(start_mode := "signup", why := "") -> void:
	mode = start_mode
	intro = why
	panel_size = Vector2(380, 330)


func _build() -> void:
	title_text = {"signup": "Save your progress", "login": "Log in", "forgot": "Forgotten password"}[mode]
	if intro != "" and mode == "signup":
		body.add_child(words(intro, 10, UiTheme.MUTED))
	match mode:
		"signup":
			_name = field("Your name on the leaderboards")
			var current := str(Online.user.get("name", ""))
			if not current.begins_with("Guest"):
				_name.text = current
			body.add_child(_name)
			_email = field("Email")
			body.add_child(_email)
			_password = field("Password (at least 8 characters)", true)
			body.add_child(_password)
			_go = UiTheme.button("Create account", _submit, 13, UiTheme.MULT)
		"login":
			_email = field("Email")
			body.add_child(_email)
			_password = field("Password", true)
			body.add_child(_password)
			_go = UiTheme.button("Log in", _submit, 13, UiTheme.POINTS)
		"forgot":
			body.add_child(words("We'll email you a link to choose a new password.", 10, UiTheme.MUTED))
			_email = field("Email")
			body.add_child(_email)
			_go = UiTheme.button("Send the link", _submit, 13, UiTheme.POINTS)
	body.add_child(_go)
	_status = words("", 10, UiTheme.MULT.lightened(0.3))
	body.add_child(_status)
	var links := HBoxContainer.new()
	links.add_theme_constant_override("separation", 6)
	match mode:
		"signup":
			links.add_child(UiTheme.button("I have an account: log in", func() -> void: _switch("login")))
		"login":
			links.add_child(UiTheme.button("New here? Create one", func() -> void: _switch("signup")))
			links.add_child(UiTheme.button("Forgot password?", func() -> void: _switch("forgot")))
		"forgot":
			links.add_child(UiTheme.button("Back to log in", func() -> void: _switch("login")))
	body.add_child(links)
	if mode != "forgot":
		var natives := HBoxContainer.new()
		natives.add_theme_constant_override("separation", 6)
		for provider in ["apple", "google"]:
			if Online.native_signin_available(provider):
				natives.add_child(UiTheme.button("Continue with " + provider.capitalize(), _native.bind(provider), 11, UiTheme.BLACK_SUIT if provider == "apple" else UiTheme.POINTS))
		if natives.get_child_count() > 0:
			body.add_child(natives)
		else:
			body.add_child(words("Sign in with Apple and Google come with the phone apps.", 8, UiTheme.MUTED))


func _switch(new_mode: String) -> void:
	Feel.play("click")
	mode = new_mode
	rebuild()


func _submit() -> void:
	_go.disabled = true
	_status.add_theme_color_override("font_color", UiTheme.MUTED)
	_status.text = "One moment…"
	var res: Dictionary
	match mode:
		"signup":
			res = await Online.signup(_email.text.strip_edges(), _password.text, _name.text.strip_edges())
		"login":
			res = await Online.login(_email.text.strip_edges(), _password.text)
		"forgot":
			res = await Online.forgot(_email.text.strip_edges())
	if not is_inside_tree():
		return
	_go.disabled = false
	if not res["ok"]:
		Feel.play("error")
		_status.add_theme_color_override("font_color", UiTheme.MULT.lightened(0.3))
		_status.text = str(res["error"])
		return
	Feel.play("buy")
	if mode == "forgot":
		_status.add_theme_color_override("font_color", UiTheme.GOOD)
		_status.text = "If that email has an account, the link is on its way."
		return
	close()


## Apple or Google: the phone's sign-in sheet hands back an identity token for the server.
func _native(provider: String) -> void:
	var id_token := await Online.native_identity_token(provider)
	if id_token == "":
		return
	var res := await Online.signin_with(provider, id_token)
	if res["ok"]:
		close()
	else:
		_status.text = str(res["error"])
