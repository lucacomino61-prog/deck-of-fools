extends Node
## Autoload "Game": the player's profile and the run in progress. Screens apply every action
## through act(), which saves the run (and the profile when a run ends) to the device and
## tells Online the progress changed, so it reaches the cloud save.

signal changed

const RUN_PATH := "user://run.json"
const RUN_META_PATH := "user://run_meta.json"
const PROFILE_PATH := "user://profile.json"
const SEED_LETTERS := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

var profile := Profile.new()
var run: RunState = null
## About the run in progress: {daily_date} for a daily run, plus practice = true when it
## isn't the ranked attempt.
var run_meta: Dictionary = {}
## True once the current run has been written into the profile.
var recorded := false
## True once the player has seen the "you won" screen for this run.
var win_seen := false


func _ready() -> void:
	ContentPacks.register_all()
	TranslationServer.set_locale("en")
	profile = _load_profile()


## Drop the card callbacks before the engine unloads their scripts, or quitting crashes.
func _exit_tree() -> void:
	run = null
	ContentDB.reset()


func has_saved_run() -> bool:
	return FileAccess.file_exists(RUN_PATH)


## The saved run, read without making it the current one (the menu shows it); null if none.
func peek_saved_run() -> RunState:
	if not has_saved_run():
		return null
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUN_PATH))
	return RunState.from_dict(data) if data is Dictionary else null


## A new run; the daily run passes its seed and {daily_date, practice}.
func new_run(deck_id: String, stake: int, challenge_id := "", seed := "", meta := {}) -> void:
	var deck := deck_id
	if challenge_id != "":
		deck = str(ContentDB.get_def(challenge_id).data["deck"])
	run = RunState.create(seed if seed != "" else _random_seed(), deck, stake, challenge_id, profile.locked_cards())
	run_meta = meta.duplicate()
	recorded = false
	win_seen = false
	_save_json(RUN_META_PATH, run_meta)
	_save_run()
	changed.emit()


func continue_run() -> bool:
	var text := FileAccess.get_file_as_string(RUN_PATH)
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		return false
	run = RunState.from_dict(data)
	run_meta = _load_json(RUN_META_PATH)
	recorded = false
	win_seen = run.won
	changed.emit()
	return true


## Everything the cloud save holds: the profile and the run in progress.
func cloud_data() -> Dictionary:
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUN_PATH)) if has_saved_run() else null
	return {"profile": profile.to_dict(), "run": saved, "run_meta": run_meta if saved != null else {}}


## Takes a save from the cloud in place of this device's.
func adopt_cloud(data: Dictionary) -> void:
	if data.get("profile") is Dictionary:
		profile = Profile.from_dict(data["profile"])
		_save_json(PROFILE_PATH, profile.to_dict(), false)
	run = null
	if data.get("run") is Dictionary:
		_save_json(RUN_PATH, data["run"], false)
		_save_json(RUN_META_PATH, data.get("run_meta", {}), false)
	elif FileAccess.file_exists(RUN_PATH):
		DirAccess.remove_absolute(RUN_PATH)
	changed.emit()


## Applies an action and saves. `quiet` skips the change signal, for screens that animate
## the result first and refresh afterwards.
func act(action: Dictionary, quiet := false) -> Dictionary:
	var result := run.apply(action)
	if result["ok"]:
		if run.phase == RunState.Phase.LOST:
			finish_run()
		else:
			_save_run()
	if not quiet:
		changed.emit()
	return result


## Writes the run into the profile once (a loss, or leaving after a win) and clears the save.
func finish_run() -> void:
	if run == null or recorded:
		return
	profile.record_run(run)
	recorded = true
	_save_json(PROFILE_PATH, profile.to_dict())
	if FileAccess.file_exists(RUN_PATH):
		DirAccess.remove_absolute(RUN_PATH)
	Online.submit_run(run, run_meta)


## Gives up the run in progress: it counts as lost (and is handed in like any lost run).
func give_up() -> void:
	if run == null or recorded:
		return
	run.phase = RunState.Phase.LOST
	_save_run()
	finish_run()


## Gives up and starts the same kind of run again: a new seed, or for a daily run the
## day's seed again as practice (the ranked try is used up).
func restart() -> void:
	if run == null:
		return
	var deck := run.deck_id
	var stake := run.stake
	var challenge := run.challenge
	var meta := run_meta.duplicate()
	var seed := ""
	if meta.has("daily_date"):
		meta["practice"] = true
		seed = run.seed_text
	give_up()
	new_run(deck, stake, challenge, seed, meta)


## Whether this device has finished exactly one run so far: the moment to offer an account.
func first_run_finished() -> bool:
	return profile.total_wins + profile.runs_lost + profile.challenges_won.size() == 1


func _save_run() -> void:
	_save_json(RUN_PATH, run.to_dict())


func _load_profile() -> Profile:
	var data := _load_json(PROFILE_PATH)
	return Profile.from_dict(data) if not data.is_empty() else Profile.new()


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}


## Writes a save file; progress the player made (not a copy from the cloud) is marked for
## the next cloud sync.
func _save_json(path: String, data: Dictionary, changed_here := true) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))
	if changed_here:
		Online.mark_dirty()


func _random_seed() -> String:
	var out := ""
	for i in 8:
		out += SEED_LETTERS[randi() % SEED_LETTERS.length()]
	return out
