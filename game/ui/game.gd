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
## The menu opens the campaign when it next appears (after a cleared chapter).
var open_campaign := false


func _ready() -> void:
	ContentPacks.register_all()
	TranslationServer.set_locale("en")
	profile = _load_profile()
	# The tour diary notes today; coming back after a few days brings a gift.
	if profile.visit(today()):
		_save_json(PROFILE_PATH, profile.to_dict())


## Today's date (UTC), as the diary, today's card and the daily run count days.
static func today() -> String:
	return Time.get_date_string_from_system(true)


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


## A new run; the daily run passes its seed and {daily_date, practice}, a seeded run its
## seed and {seeded}, a campaign chapter {chapter}. Maestri, props and the nemesis come
## along only in normal runs and the campaign (fair play: batch 13).
func new_run(deck_id: String, stake: int, challenge_id := "", seed := "", meta := {}) -> void:
	var deck := deck_id
	if challenge_id != "":
		deck = str(ContentDB.get_def(challenge_id).data["deck"])
	var extras := {}
	if Profile.brings_extras(challenge_id, meta):
		# Today's card comes along once the player has finished a first run.
		var card := Profile.card_of_the_day(today()) if profile.runs_played() > 0 else ""
		extras = profile.extras_for(str(meta.get("chapter", "")), card)
	run = RunState.create(seed if seed != "" else random_seed(), deck, stake, challenge_id, profile.locked_cards(), extras)
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
	var in_show := run.phase == RunState.Phase.IN_SHOW
	var result := run.apply(action)
	if result["ok"]:
		# A show just ended: its score may be a new best for that show (the goal bar's ghost).
		if in_show and run.phase != RunState.Phase.IN_SHOW and not run_meta.get("seeded", false):
			profile.note_show(run)
			_save_json(PROFILE_PATH, profile.to_dict())
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
	# A seeded run's cards were known in advance, so only its discoveries count.
	profile.record_run(run, not run_meta.get("seeded", false), run_meta.get("gave_up", false))
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
	run_meta["gave_up"] = true
	_save_json(RUN_META_PATH, run_meta)
	_save_run()
	finish_run()


## Gives up and starts the same kind of run again: a new seed; for a daily run the day's
## seed again as practice (the ranked try is used up); for a seeded run its seed again.
func restart() -> void:
	if run == null:
		return
	var deck := run.deck_id
	var stake := run.stake
	var challenge := run.challenge
	var meta := run_meta.duplicate()
	meta.erase("gave_up")
	var seed := ""
	if meta.has("daily_date"):
		meta["practice"] = true
		seed = run.seed_text
	if meta.get("seeded", false):
		seed = run.seed_text
	give_up()
	new_run(deck, stake, challenge, seed, meta)


## A campaign chapter: its stake, and the deck the player picked.
func start_chapter(chapter_id: String, deck_id: String) -> void:
	var d := ContentDB.get_def(chapter_id)
	new_run(deck_id, int(d.data["stake"]), "", "", {"chapter": chapter_id})


## Ends a cleared chapter: records the run, then keeps `carry_item` (a Jester or a duo of the
## troupe) for the next chapter.
func finish_chapter(carry_item: ItemCard) -> void:
	finish_run()
	if carry_item != null and profile.chapters_cleared < CampaignCards.COUNT:
		profile.carry = {"id": carry_item.def_id, "parts": carry_item.parts.map(func(p: ItemCard) -> String: return p.def_id)}
	save_profile()


func save_profile() -> void:
	_save_json(PROFILE_PATH, profile.to_dict())
	changed.emit()


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


func random_seed() -> String:
	var out := ""
	for i in 8:
		out += SEED_LETTERS[randi() % SEED_LETTERS.length()]
	return out
