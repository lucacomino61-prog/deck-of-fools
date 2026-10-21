extends Node
## Online smoke test: the game's own Online code against a running local API (server/:
## npm run dev). It never adopts a cloud save, so this machine's game files are left alone.
##   godot --headless --path game res://tests/online_smoke.tscn -- --online --api=http://127.0.0.1:8787 --account-file=user://online_smoke.json
## tools/test.ps1 runs it whenever the local API is up. Prints "ONLINE SMOKE OK".

var failures := 0


func _ready() -> void:
	get_tree().create_timer(90.0).timeout.connect(func() -> void:
		push_error("ONLINE SMOKE FAILED: timed out")
		get_tree().quit(1))
	Online.token = ""
	Online.user = {}
	Online.save_version = 0
	Online.dirty = false
	Online.pending_runs = []
	# Answer every conflict by keeping this device, so the test never writes the game's files.
	var asked := [0]
	Online.conflict.connect(func(_cloud: Dictionary) -> void: asked[0] += 1)

	_check(await Online._guest(), "a guest account is made")
	var guest_id := str(Online.user["id"])
	var email := "smoke%d@example.com" % int(Time.get_unix_time_from_system())
	var res := await Online.signup(email, "harlequin1", "Smoke Test")
	_check(res["ok"] and str(Online.user["id"]) == guest_id and not Online.is_guest(), "signing up keeps the guest's account")

	Online.dirty = true
	await Online.sync_save()
	_check(Online.save_version == 1 and not Online.dirty, "the save reaches the cloud")
	await Online.call_api(HTTPClient.METHOD_PUT, "/v1/save", {"base_version": 1, "data": {"profile": {}}, "device": "another phone"})
	Online.dirty = true
	await Online.sync_save()
	_check(asked[0] == 1, "when both sides changed, the player is asked")
	var cloud := await Online.call_api(HTTPClient.METHOD_GET, "/v1/save")
	await Online.resolve_conflict("device", cloud["data"])
	_check(Online.save_version == 3 and not Online.dirty, "keeping this device's progress replaces the cloud copy")

	var run := RunState.create("SMOKE234", "d_bergamo", 1)
	run.town = 2
	run.counters["best_hand"] = 4321.0
	run.action_log.assign([{"a": "play", "cards": [1]}, {"a": "play", "cards": [2]}])
	await Online.submit_run(run, {})
	_check(Online.pending_runs.is_empty(), "a finished run is handed in")
	var hands := await Online.leaderboard("best_hand")
	_check(hands["ok"] and hands["data"]["me"] is Dictionary and float(hands["data"]["me"]["best_hand"]) >= 4321.0, "the run is on the best-hand board")

	var daily := await Online.start_daily()
	_check(daily["ok"], "the ranked daily run starts")
	if daily["ok"]:
		var setup: Dictionary = daily["data"]
		var mine := Online.daily_setup(str(setup["date"]))
		_check(setup["seed"] == mine["seed"] and setup["deck"] == mine["deck"], "the server and the game agree on today's run")
		var day := RunState.create(str(setup["seed"]), str(setup["deck"]), 1)
		day.counters["best_hand"] = 99.0
		day.action_log.assign([{"a": "play", "cards": [1]}])
		await Online.submit_run(day, {"daily_date": setup["date"]})
		var board := await Online.leaderboard("daily")
		_check(board["ok"] and board["data"]["me"] is Dictionary, "the daily attempt is ranked")
	var stats := await Online.stats()
	_check(stats["ok"] and int(stats["data"]["runs"]) == 2, "the profile stats count both runs")

	await Online.logout()
	_check(Online.signed_in() and Online.is_guest(), "signing out carries on as a guest")
	Online.dirty = true
	var login := await Online.login(email, "harlequin1")
	_check(login["ok"] and str(Online.user.get("email", "")) == email, "logging back in")
	var gone := await Online.delete_account()
	_check(gone["ok"] and Online.is_guest(), "deleting the account leaves a fresh guest")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(Online.account_path))
	if failures == 0:
		print("ONLINE SMOKE OK")
	get_tree().quit(0 if failures == 0 else 1)


func _check(condition: bool, what: String) -> void:
	if not condition:
		failures += 1
		push_error("ONLINE SMOKE FAILED: " + what)
