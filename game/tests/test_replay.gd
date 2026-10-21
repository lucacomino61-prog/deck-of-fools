extends TestCase
## A seed plus the action log must rebuild the exact same run; so must a JSON save.


## Plays a fixed strategy for `steps` actions: always the first 5 cards, buy the first
## affordable offer, skip every other evening show.
func _play(run: RunState, steps: int) -> void:
	for i in steps:
		match run.phase:
			RunState.Phase.CHOOSE_SHOW:
				if run.show_index == Shows.EVENING and run.town % 2 == 0:
					run.apply({"a": "skip_show"})
				else:
					run.apply({"a": "select_show"})
			RunState.Phase.IN_SHOW:
				if run.discards_left == 3:
					run.apply({"a": "discard", "cards": ids(run.hand.slice(0, 2))})
				else:
					run.apply({"a": "play", "cards": ids(run.hand.slice(0, 5))})
			RunState.Phase.CASH_OUT:
				run.apply({"a": "cash_out"})
			RunState.Phase.SHOP:
				var bought := false
				for slot in run.shop.offers.size():
					if not bought and run.apply({"a": "buy", "slot": slot})["ok"]:
						bought = true
				if run.shop.rerolls == 0 and run.ducats > 20:
					run.apply({"a": "reroll"})
				else:
					run.apply({"a": "leave_shop"})
			_:
				return


func _json(run: RunState) -> String:
	return JSON.stringify(run.to_dict())


func test_replay_rebuilds_the_run() -> void:
	var run := RunState.create("REPLAY-1", "deck_test_rich")
	_play(run, 60)
	ok(run.town > 2, "the strategy got past town 2")
	var again := RunState.replay("REPLAY-1", "deck_test_rich", 1, run.action_log)
	eq(_json(again), _json(run), "replayed state")


func test_json_save_round_trip() -> void:
	var run := RunState.create("SAVE-1", "deck_test_rich")
	_play(run, 25)
	var saved: Dictionary = JSON.parse_string(_json(run))
	var loaded := RunState.from_dict(saved)
	eq(_json(loaded), _json(run), "loaded state")
	_play(run, 25)
	_play(loaded, 25)
	eq(_json(loaded), _json(run), "both continue identically")


func test_different_seeds_differ() -> void:
	var a := RunState.create("SEED-A")
	var b := RunState.create("SEED-B")
	a.apply({"a": "select_show"})
	b.apply({"a": "select_show"})
	ok(ids(a.hand) != ids(b.hand), "different seeds deal different hands")
