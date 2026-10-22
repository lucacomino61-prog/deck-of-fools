extends Node
## Autoload "Online": the game's link to the Deck of Fools API (server/).
## - A guest account is made silently the first time the game runs online; signing up, or
##   Apple/Google, upgrades that same account so nothing is lost.
## - Cloud save: the device keeps the cloud version it last saw and whether it has changed
##   since. A sync pushes, pulls, or (when both sides changed) asks the player which to keep.
## - Finished runs are handed in for the leaderboards; offline, they wait in a queue.
## - The daily run's setup is worked out here too (for offline practice), the same way the
##   server does it (server/src/daily.js).
## Nothing here blocks play: every call fails softly when the server can't be reached.

signal account_changed
## Both this device and the cloud changed the save: the menu asks which to keep, then
## calls resolve_conflict().
signal conflict(cloud: Dictionary)

const API_SETTING := "deck_of_fools/api_url"
const DEFAULT_API := "http://localhost:8787"

var api_url := DEFAULT_API
## Where the account is kept on the device (the online smoke test uses its own file).
var account_path := "user://account.json"
var token := ""
## The signed-in player: {id, name, email, verified, guest, signins}.
var user: Dictionary = {}
## The cloud save version this device last saw, and whether its progress changed since.
var save_version := 0
var dirty := false
## Whether the last request reached the server.
var online := false
## Runs finished while offline, handed in at the next chance.
var pending_runs: Array = []
var syncing := false
## Headless runs (the tests) stay offline and keep no account file, unless started with
## `-- --online` (tests/online_smoke.tscn).
var inert := false
var _push_timer: Timer


func _ready() -> void:
	api_url = str(ProjectSettings.get_setting(API_SETTING, DEFAULT_API))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--api="):
			api_url = arg.get_slice("=", 1)
		elif arg.begins_with("--account-file="):
			account_path = arg.get_slice("=", 1)
	inert = DisplayServer.get_name() == "headless" and not OS.get_cmdline_user_args().has("--online")
	if inert:
		return
	_load()
	_push_timer = Timer.new()
	_push_timer.one_shot = true
	_push_timer.wait_time = 4.0
	_push_timer.timeout.connect(sync_save)
	add_child(_push_timer)


## Called once by the game at start (not by tests): signs in silently, hands in waiting
## runs and syncs the save.
func start() -> void:
	if token == "":
		await _guest()
	else:
		await refresh_user()
	if token != "":
		await _send_pending_runs()
		await sync_save()


func signed_in() -> bool:
	return token != ""


func is_guest() -> bool:
	return bool(user.get("guest", true))


## Apple and Google sign-in run through the phone apps' native sign-in sheets, added with
## the store builds (M9). Until a plugin is wired in here, the buttons stay hidden; the
## server side (checking the token) is done and tested.
func native_signin_available(_provider: String) -> bool:
	return false


## The identity token from the native sign-in sheet ("" if cancelled or unavailable).
func native_identity_token(_provider: String) -> String:
	return ""


# --- talking to the server ---

## One API call. Always returns {ok, status, data, error}; never throws, never blocks play.
func call_api(method: int, path: String, body: Variant = null) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = 12.0
	add_child(http)
	var headers := PackedStringArray(["Content-Type: application/json"])
	if token != "":
		headers.append("Authorization: Bearer " + token)
	var sent := http.request(api_url + path, headers, method, "" if body == null else JSON.stringify(body))
	if sent != OK:
		http.queue_free()
		online = false
		return {"ok": false, "status": 0, "data": {}, "error": "Can't reach the server right now."}
	var response: Array = await http.request_completed
	http.queue_free()
	if int(response[0]) != HTTPRequest.RESULT_SUCCESS:
		online = false
		return {"ok": false, "status": 0, "data": {}, "error": "You're offline. Your progress is kept on this device."}
	online = true
	var status := int(response[1])
	var text := (response[3] as PackedByteArray).get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text) if text != "" else {}
	var data: Dictionary = parsed if parsed is Dictionary else {}
	if status == 401 and token != "" and not path.begins_with("/v1/auth/"):
		_signed_out()
	return {"ok": status >= 200 and status < 300, "status": status, "data": data, "error": str(data.get("error", "")) if status >= 300 else ""}


# --- accounts ---

func _guest() -> bool:
	var res := await call_api(HTTPClient.METHOD_POST, "/v1/auth/guest")
	if res["ok"]:
		_signed_in(res["data"])
	return res["ok"]


func refresh_user() -> bool:
	var res := await call_api(HTTPClient.METHOD_GET, "/v1/me")
	if res["ok"]:
		user = res["data"]["user"]
		_save()
		account_changed.emit()
	return res["ok"]


## Email sign-up; as a guest this links the guest's progress to the new account.
func signup(email: String, password: String, name: String) -> Dictionary:
	var res := await call_api(HTTPClient.METHOD_POST, "/v1/auth/signup", {"email": email, "password": password, "name": name})
	if res["ok"]:
		_signed_in(res["data"])
		await sync_save()
	return res


func login(email: String, password: String) -> Dictionary:
	var res := await call_api(HTTPClient.METHOD_POST, "/v1/auth/login", {"email": email, "password": password})
	if res["ok"]:
		# A different account: this device's save is compared with that account's cloud save.
		save_version = 0
		_signed_in(res["data"])
		await sync_save()
	return res


## Apple or Google, once a native plugin has handed the game an identity token.
func signin_with(provider: String, id_token: String, name := "") -> Dictionary:
	var res := await call_api(HTTPClient.METHOD_POST, "/v1/auth/" + provider, {"id_token": id_token, "name": name})
	if res["ok"]:
		if not bool(res["data"].get("linked", false)):
			save_version = 0
		_signed_in(res["data"])
		await sync_save()
	return res


func forgot(email: String) -> Dictionary:
	return await call_api(HTTPClient.METHOD_POST, "/v1/auth/forgot", {"email": email})


func resend_verification() -> Dictionary:
	return await call_api(HTTPClient.METHOD_POST, "/v1/auth/resend-verification")


func rename(name: String) -> Dictionary:
	var res := await call_api(HTTPClient.METHOD_PATCH, "/v1/me", {"name": name})
	if res["ok"]:
		user = res["data"]["user"]
		_save()
		account_changed.emit()
	return res


## Signs out; the game then carries on as a new guest, keeping this device's progress.
func logout() -> void:
	await call_api(HTTPClient.METHOD_POST, "/v1/auth/logout")
	_signed_out()
	await _guest()
	dirty = true
	await sync_save()


## Deletes the account and everything stored about it on the server.
func delete_account() -> Dictionary:
	var res := await call_api(HTTPClient.METHOD_DELETE, "/v1/me")
	if res["ok"]:
		_signed_out()
		await _guest()
	return res


func stats() -> Dictionary:
	return await call_api(HTTPClient.METHOD_GET, "/v1/me/stats")


func _signed_in(data: Dictionary) -> void:
	token = str(data["token"])
	user = data["user"]
	_save()
	account_changed.emit()


func _signed_out() -> void:
	token = ""
	user = {}
	save_version = 0
	_save()
	account_changed.emit()


# --- cloud save ---

## What a sync should do: "push" this device's save, "pull" the cloud's, "ask" the player
## (both changed), or nothing.
static func decide(cloud_version: int, seen_version: int, changed: bool) -> String:
	if cloud_version == seen_version:
		return "push" if changed else "none"
	if cloud_version == 0:
		return "push"
	return "ask" if changed else "pull"


## The device's progress changed: push it to the cloud in a few seconds.
func mark_dirty() -> void:
	if inert:
		return
	dirty = true
	_save()
	if token != "" and _push_timer != null and is_inside_tree():
		_push_timer.start()


func sync_save() -> void:
	if token == "" or syncing:
		return
	syncing = true
	var res := await call_api(HTTPClient.METHOD_GET, "/v1/save")
	if res["ok"]:
		var cloud: Dictionary = res["data"]
		match decide(int(cloud["version"]), save_version, dirty):
			"push":
				await _push(false)
			"pull":
				_adopt(cloud)
			"ask":
				conflict.emit(cloud)
	syncing = false


## The player's answer to a conflict: keep "device" (overwrite the cloud) or "cloud".
func resolve_conflict(keep: String, cloud: Dictionary) -> void:
	if keep == "cloud":
		_adopt(cloud)
	else:
		save_version = int(cloud["version"])
		await _push(true)


func _push(force: bool) -> void:
	var res := await call_api(HTTPClient.METHOD_PUT, "/v1/save", {"base_version": save_version, "data": Game.cloud_data(), "device": OS.get_name(), "force": force})
	if res["ok"]:
		save_version = int(res["data"]["version"])
		dirty = false
		_save()
	elif res["status"] == 409:
		conflict.emit(res["data"])


func _adopt(cloud: Dictionary) -> void:
	if cloud.get("data") is Dictionary:
		Game.adopt_cloud(cloud["data"])
	save_version = int(cloud["version"])
	dirty = false
	_save()


# --- runs, the daily run and leaderboards ---

## Hands in a finished run (queued while offline). Practice runs of the daily and seeded
## runs aren't ranked.
func submit_run(run: RunState, meta: Dictionary) -> void:
	if inert or bool(meta.get("practice", false)) or bool(meta.get("seeded", false)):
		return
	var entry := {
		"seed": run.seed_text, "deck": run.deck_id, "stake": run.stake, "challenge": run.challenge,
		"won": run.won, "town": run.town, "best_hand": float(run.counters.get("best_hand", 0.0)),
		"jesters": run.zanni.map(func(z: ItemCard) -> String: return z.def_id),
		"actions": run.action_log,
		# Maestri, props or the campaign helped (batch 13): kept off the leaderboards.
		"assisted": run.assisted(),
	}
	if meta.has("daily_date"):
		entry["daily_date"] = meta["daily_date"]
	pending_runs.append(entry)
	_save()
	await _send_pending_runs()


func _send_pending_runs() -> void:
	while token != "" and not pending_runs.is_empty():
		var res := await call_api(HTTPClient.METHOD_POST, "/v1/runs", pending_runs[0])
		if res["status"] == 0 or res["status"] >= 500 or res["status"] == 429:
			return
		# Sent, or refused for good (implausible, a daily already handed in): either way, done.
		pending_runs.pop_front()
		_save()


## Today's (UTC) daily run, worked out on the device: {date, seed, deck, stake}.
static func daily_setup(date := "") -> Dictionary:
	if date == "":
		date = Time.get_date_string_from_system(true)
	var parts := date.split("-")
	var day := int(Time.get_unix_time_from_datetime_dict({"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2])}) / 86400)
	var decks: Array = ContentDB.pool("deck").map(func(d: ContentDef) -> String: return d.id)
	return {"date": date, "seed": "DAY" + date.replace("-", ""), "deck": decks[day % decks.size()], "stake": 1}


## Today's daily run from the server, with this player's attempt if any.
func daily() -> Dictionary:
	return await call_api(HTTPClient.METHOD_GET, "/v1/daily")


func start_daily() -> Dictionary:
	return await call_api(HTTPClient.METHOD_POST, "/v1/daily/start")


## kind: "daily", "best_hand" or "town" (with a stake).
func leaderboard(kind: String, stake := 1) -> Dictionary:
	var path := "/v1/leaderboards/" + kind + ("?stake=%d" % stake if kind == "town" else "")
	return await call_api(HTTPClient.METHOD_GET, path)


# --- the account file ---

func _load() -> void:
	if not FileAccess.file_exists(account_path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(account_path))
	if data is Dictionary:
		token = str(data.get("token", ""))
		user = data.get("user", {})
		save_version = int(data.get("save_version", 0))
		dirty = bool(data.get("dirty", false))
		pending_runs = data.get("pending_runs", [])


func _save() -> void:
	if inert:
		return
	var f := FileAccess.open(account_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"token": token, "user": user, "save_version": save_version, "dirty": dirty, "pending_runs": pending_runs}))
