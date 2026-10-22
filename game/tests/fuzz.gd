extends SceneTree
## Plays many random runs through RunState.apply, across every deck, stake and challenge,
## and checks after every action that the run still adds up:
##   - during a show, every card of the deck is in exactly one of draw pile, hand, discards
##   - card ids are unique; counters, slots and money stay in range; scores are numbers
##   - a JSON save loads back to the same run; a score preview changes nothing
##   - an honest run (no help from the bot) replays to the same state from its seed and log
## Half the runs are "rich": the bot hands itself ducats and shrinks show targets, so it
## reaches the late towns, the Patrons, endless play and most of the shop. Those runs
## aren't replayed (the bot's help isn't in the log).
##   godot --headless --path game -s res://tests/fuzz.gd -- --runs=200 --seed=1 --steps=500
## Prints one line per problem ("FUZZ FAIL ...") and a summary ("FUZZ DONE ...").

var bot := RandomNumberGenerator.new()
var problems := 0
var action_stats := {}


func _initialize() -> void:
	var runs := 200
	var steps := 500
	bot.seed = 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="):
			runs = int(arg.get_slice("=", 1))
		elif arg.begins_with("--seed="):
			bot.seed = int(arg.get_slice("=", 1))
		elif arg.begins_with("--steps="):
			steps = int(arg.get_slice("=", 1))
	ContentPacks.register_all()
	var decks: Array = ContentDB.pool("deck").map(func(d: ContentDef) -> String: return d.id)
	var challenges: Array = ContentDB.pool("challenge").map(func(d: ContentDef) -> String: return d.id)
	var stakes := ContentDB.pool("stake").size()
	var best_town := 0
	var won := 0
	var started := Time.get_ticks_msec()
	for n in runs:
		var rich := n % 2 == 1
		var challenge := ""
		var deck: String = decks[bot.randi() % decks.size()]
		if bot.randf() < 0.15 and not challenges.is_empty():
			challenge = challenges[bot.randi() % challenges.size()]
			deck = str(ContentDB.get_def(challenge).data["deck"])
		var stake := 1 + bot.randi() % stakes
		var seed_text := "FZ%d-%d" % [bot.seed, n]
		print("RUN %d %s %s stake %d %s%s" % [n, seed_text, deck, stake, challenge, " rich" if rich else ""])
		var run := RunState.create(seed_text, deck, stake, challenge)
		_check(run, "created")
		_play(run, steps, rich)
		var end := "won" if run.won else ("lost at %s" % (run.current_patron() if run.show_index == Shows.PATRON else "show %d" % run.show_index) if run.phase == RunState.Phase.LOST else "stopped")
		print("END %d town %d %s, score %s of %s, hands %d" % [n, run.town, end, run.show_score, run.show_target, run.hands_left])
		best_town = maxi(best_town, run.town)
		if run.won:
			won += 1
		if not rich:
			var again := RunState.replay(seed_text, deck, stake, run.action_log, challenge)
			if JSON.stringify(again.to_dict()) != JSON.stringify(run.to_dict()):
				_fail(run, "replay from the log doesn't rebuild the run")
	var lines := []
	for a in action_stats:
		lines.append("%s %d/%d" % [a, action_stats[a][0], action_stats[a][1]])
	print("FUZZ ACTIONS ok/tried: " + ", ".join(lines))
	print("FUZZ DONE %d runs, %d problems, best town %d, %d won, %.1f s" % [runs, problems, best_town, won, (Time.get_ticks_msec() - started) / 1000.0])
	ContentDB.reset()
	quit(1 if problems > 0 else 0)


func _play(run: RunState, steps: int, rich: bool) -> void:
	var in_shop := 0
	for step in steps:
		if run.phase == RunState.Phase.LOST or (run.town > 12):
			return
		var action := _choose(run, rich, in_shop)
		in_shop = in_shop + 1 if run.phase == RunState.Phase.SHOP else 0
		var before_phase := run.phase
		var result := run.apply(action)
		var name := str(action["a"])
		if not action_stats.has(name):
			action_stats[name] = [0, 0]
		action_stats[name][1] += 1
		if result["ok"]:
			action_stats[name][0] += 1
		if rich:
			if before_phase == RunState.Phase.CHOOSE_SHOW and run.phase == RunState.Phase.IN_SHOW:
				run.show_target = maxf(1.0, floorf(run.show_target * 0.004))
			if before_phase == RunState.Phase.CASH_OUT and run.phase == RunState.Phase.SHOP:
				run.ducats += 40
		_check(run, "after %s" % JSON.stringify(action))
		if step % 40 == 20:
			_check_save(run)
		if run.phase == RunState.Phase.IN_SHOW and step % 15 == 7 and run.hand.size() > 0:
			_check_preview(run)


## A random action that makes sense in the current phase (sometimes one that doesn't, to
## check refusals stay harmless).
func _choose(run: RunState, rich: bool, in_shop: int) -> Dictionary:
	if bot.randf() < 0.03:
		return _nonsense(run)
	match run.phase:
		RunState.Phase.CHOOSE_SHOW:
			var r := bot.randf()
			if r < 0.15 and run.show_index < Shows.PATRON:
				return {"a": "skip_show"}
			if r < 0.2:
				return {"a": "swap_patron"}
			return {"a": "select_show", "perform": bot.randf() < 0.5}
		RunState.Phase.MAP:
			var roads := run.roads()
			var col: int = roads[bot.randi() % roads.size()] if bot.randf() < 0.9 and not roads.is_empty() else bot.randi() % 4
			return {"a": "travel", "index": col, "slot": bot.randi() % 2}
		RunState.Phase.ENCORE:
			if run.show_counters.get("encore", "") == "live":
				return {"a": "play", "cards": _good_cards(run) if bot.randf() < 0.7 else _some_cards(run, 1 + bot.randi() % 5)}
			return {"a": "encore"} if bot.randf() < 0.6 else {"a": "bow"}
		RunState.Phase.IN_SHOW:
			var r := bot.randf()
			if r < 0.08 and not run.consumables.is_empty():
				return {"a": "use", "index": bot.randi() % run.consumables.size(), "cards": _some_cards(run, 1 + bot.randi() % 3)}
			if r < 0.11 and run.zanni.size() > 1:
				return {"a": "reorder_zanni", "order": _shuffled(run.zanni.size())}
			if r < 0.13 and not run.zanni.is_empty():
				return {"a": "sell", "zone": "zanni", "index": bot.randi() % run.zanni.size()}
			if r < 0.35 and run.discards_left > 0:
				return {"a": "discard", "cards": _some_cards(run, 1 + bot.randi() % 5)}
			return {"a": "play", "cards": _good_cards(run) if rich or bot.randf() < 0.5 else _some_cards(run, 1 + bot.randi() % 5)}
		RunState.Phase.CASH_OUT:
			return {"a": "cash_out"}
		RunState.Phase.SHOP:
			if in_shop > 12:
				return {"a": "leave_shop"}
			var r := bot.randf()
			if r < 0.35:
				return {"a": "buy", "slot": bot.randi() % maxi(1, run.shop.offers.size())}
			if r < 0.5:
				return {"a": "buy_pack", "slot": bot.randi() % maxi(1, run.shop.packs.size())}
			if r < 0.58:
				return {"a": "buy_warrant", "index": bot.randi() % 2}
			if r < 0.66:
				return {"a": "reroll"}
			if r < 0.72 and not run.consumables.is_empty():
				return {"a": "use", "index": bot.randi() % run.consumables.size(), "cards": []}
			if r < 0.76 and not run.zanni.is_empty() and not rich:
				return {"a": "sell", "zone": "zanni", "index": bot.randi() % run.zanni.size()}
			if r < 0.79 and not run.consumables.is_empty():
				return {"a": "sell", "zone": "consumable", "index": bot.randi() % run.consumables.size()}
			if r < 0.84:
				for i in run.zanni.size():
					var merges := LazziCards.merges_for(run, i)
					if not merges.is_empty():
						return {"a": "merge", "index": merges[0]["index"], "other": merges[0]["other"]}
				if rich and run.zanni.size() < run.stat("zanni_slots") - 1:
					# A rich bot hires a duo's two Jesters now and then, so merges get tried.
					var duos := ContentDB.pool("lazzo")
					var duo: ContentDef = duos[bot.randi() % duos.size()]
					for part in duo.data["parts"]:
						run.zanni.append(ItemCard.make(part, ContentDB.get_def(part).cost))
			return {"a": "leave_shop"}
		RunState.Phase.PACK:
			var items: Array = run.pack.get("items", [])
			if items.is_empty() or bot.randf() < 0.15:
				return {"a": "skip_pack"}
			return {"a": "pick", "index": bot.randi() % items.size(), "cards": _some_cards(run, 1 + bot.randi() % 3)}
	return {"a": "leave_shop"}


func _nonsense(run: RunState) -> Dictionary:
	var options := [
		{"a": "play", "cards": [99999]}, {"a": "play", "cards": []}, {"a": "discard", "cards": [-1]},
		{"a": "buy", "slot": 99}, {"a": "sell", "zone": "zanni", "index": 99}, {"a": "use", "index": 99},
		{"a": "pick", "index": -1}, {"a": "reorder_zanni", "order": [0, 0]}, {"a": "cash_out"},
		{"a": "select_show"}, {"a": "skip_pack"}, {"a": "buy_warrant", "index": 5}, {"a": "nonsense"},
		{"a": "travel", "index": 9}, {"a": "encore"}, {"a": "bow"}, {"a": "merge", "index": 0, "other": 0},
	]
	if not run.hand.is_empty():
		var id := run.hand[0].id
		options.append({"a": "play", "cards": [id, id]})
	return options[bot.randi() % options.size()]


func _some_cards(run: RunState, count: int) -> Array:
	var order := _shuffled(run.hand.size())
	return order.slice(0, mini(count, order.size())).map(func(i: int) -> int: return run.hand[i].id)


## The strongest-looking handful: the biggest group of one rank, or the longest suit, plus
## high cards, up to 5 (the forced card, if any, goes in first).
func _good_cards(run: RunState) -> Array:
	var by_rank := {}
	var by_suit := {}
	for c in run.hand:
		if c.has_rank():
			by_rank[c.rank] = (by_rank.get(c.rank, []) as Array) + [c]
		by_suit[c.suit] = (by_suit.get(c.suit, []) as Array) + [c]
	var best: Array = []
	for group in by_rank.values() + by_suit.values():
		if (group as Array).size() > best.size():
			best = group
	best = best.slice(0, 5)
	var rest := run.hand.filter(func(c: PlayingCard) -> bool: return not best.has(c))
	rest.sort_custom(func(a: PlayingCard, b: PlayingCard) -> bool: return a.rank > b.rank)
	while best.size() < mini(5, run.hand.size()) and not rest.is_empty() and best.size() < 2:
		best.append(rest.pop_front())
	var out: Array = best.map(func(c: PlayingCard) -> int: return c.id)
	var forced := int(run.show_counters.get("forced", -1))
	if forced >= 0 and not out.has(forced) and run.hand.any(func(c: PlayingCard) -> bool: return c.id == forced):
		out.push_front(forced)
		out = out.slice(0, 5)
	return out


func _shuffled(count: int) -> Array:
	var order := range(count)
	for i in range(count - 1, 0, -1):
		var j := bot.randi() % (i + 1)
		var t: int = order[i]
		order[i] = order[j]
		order[j] = t
	return order


# --- checks ---

func _check(run: RunState, where: String) -> void:
	var ids := {}
	for c in run.full_deck:
		if ids.has(c.id):
			_fail(run, "%s: card id %d twice in the deck" % [where, c.id])
		ids[c.id] = true
		if c.id >= run._next_card_id:
			_fail(run, "%s: card id %d not below next_id %d" % [where, c.id, run._next_card_id])
	if run.phase == RunState.Phase.IN_SHOW:
		var seen := {}
		for pile in [run.draw_pile, run.hand, run.discard_pile]:
			for c: PlayingCard in pile:
				if seen.has(c.id):
					_fail(run, "%s: card %s in two piles" % [where, c.label()])
				seen[c.id] = true
				if not ids.has(c.id):
					_fail(run, "%s: card %s in a pile but not in the deck" % [where, c.label()])
		if seen.size() != ids.size():
			_fail(run, "%s: %d deck cards but %d in the piles" % [where, ids.size(), seen.size()])
		if run.hands_left < 0 or run.discards_left < 0:
			_fail(run, "%s: hands %d, discards %d" % [where, run.hands_left, run.discards_left])
		# L'Impaziente (draw exactly 3 after each play or discard) grows the hand on purpose.
		if run.hand.size() > run.stat("hand_size") + 3 and run.stat("draw_exact") <= 0:
			_fail(run, "%s: %d cards in hand, hand size %d" % [where, run.hand.size(), run.stat("hand_size")])
	if is_nan(run.show_score) or is_nan(run.show_target):
		_fail(run, "%s: score or target is NaN" % where)
	if run.ducats < -run.stat("debt_limit") - 25:
		_fail(run, "%s: ducats %d below the debt limit %d" % [where, run.ducats, run.stat("debt_limit")])
	var slot_free := run.zanni.filter(func(z: ItemCard) -> bool: return run._takes_no_slot(z)).size()
	if run.zanni.size() - slot_free > maxi(run.stat("zanni_slots"), 0) + 1:
		_fail(run, "%s: %d Jesters for %d slots" % [where, run.zanni.size() - slot_free, run.stat("zanni_slots")])
	var cons_free := run.consumables.filter(func(z: ItemCard) -> bool: return run._takes_no_slot(z)).size()
	if run.consumables.size() - cons_free > maxi(run.stat("consumable_slots"), 0):
		_fail(run, "%s: %d one-use cards for %d slots" % [where, run.consumables.size() - cons_free, run.stat("consumable_slots")])
	for z in run.zanni + run.consumables:
		if z.def() == null:
			_fail(run, "%s: unknown card %s" % [where, z.def_id])
	if run.phase == RunState.Phase.SHOP and run.shop == null:
		_fail(run, "%s: in the shop with no shop" % where)
	if run.phase == RunState.Phase.PACK and (run.pack.is_empty() or not run.pack.has("items")):
		_fail(run, "%s: pack phase with no pack" % where)
	if run.tour:
		if run.mood < 0 or run.mood > RunState.MOOD_MAX:
			_fail(run, "%s: mood %d" % [where, run.mood])
		if run.route_row >= run.route.size() or run.city == "" or (run.route[run.route_row] as Array)[run.route_col]["city"] != run.city:
			_fail(run, "%s: off the map (row %d of %d, city '%s')" % [where, run.route_row, run.route.size(), run.city])
		if run.phase == RunState.Phase.MAP and run.roads().is_empty():
			_fail(run, "%s: on the map with no road out" % where)
		if run.phase == RunState.Phase.CHOOSE_SHOW and run.scenario == "":
			_fail(run, "%s: a show with no Scenario" % where)
	for z in run.zanni:
		for part in z.parts:
			if part.def() == null or part.def().kind != "zanni":
				_fail(run, "%s: a duo holds %s" % [where, part.def_id])


func _check_save(run: RunState) -> void:
	var text := JSON.stringify(run.to_dict())
	var loaded := RunState.from_dict(JSON.parse_string(text))
	var again := JSON.stringify(loaded.to_dict())
	if again != text:
		_fail(run, "a JSON save doesn't load back to the same run: " + _diff(JSON.parse_string(text), JSON.parse_string(again), ""))


## Where two saves first differ, as "path: a != b".
func _diff(a: Variant, b: Variant, path: String) -> String:
	if typeof(a) != typeof(b):
		return "%s: %s != %s" % [path, JSON.stringify(a).left(120), JSON.stringify(b).left(120)]
	if a is Dictionary:
		for k in a:
			if not b.has(k):
				return "%s.%s missing after loading" % [path, k]
			var d := _diff(a[k], b[k], "%s.%s" % [path, k])
			if d != "":
				return d
		for k in b:
			if not a.has(k):
				return "%s.%s appeared after loading" % [path, k]
		return ""
	if a is Array:
		if a.size() != b.size():
			return "%s: %d items != %d" % [path, a.size(), b.size()]
		for i in a.size():
			var d := _diff(a[i], b[i], "%s[%d]" % [path, i])
			if d != "":
				return d
		return ""
	return "" if a == b else "%s: %s != %s" % [path, JSON.stringify(a).left(120), JSON.stringify(b).left(120)]


func _check_preview(run: RunState) -> void:
	var before := JSON.stringify(run.to_dict())
	run.preview(_good_cards(run))
	for i in run.zanni.size():
		run.jester_now(i)
	if JSON.stringify(run.to_dict()) != before:
		_fail(run, "a score preview or a Jester's value changed the run")


func _fail(run: RunState, what: String) -> void:
	problems += 1
	var tail := run.action_log.slice(maxi(0, run.action_log.size() - 3))
	print("FUZZ FAIL [%s town %d show %d phase %d] %s | last actions %s" % [run.seed_text, run.town, run.show_index, run.phase, what, JSON.stringify(tail)])
