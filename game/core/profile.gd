class_name Profile
extends RefCounted
## The player's progress across runs: discoveries, feats, wins per deck and stake, stake
## badges on Jesters. RunState only reports what happened; record_run() turns a finished
## run into progress, and the queries below answer what's unlocked (rules in Unlocks).
## Cloud saves sync to_dict() with the account (M6).

var discovered: Dictionary = {}
var feats: Dictionary = {}
## Highest stake won, per deck.
var best_stake: Dictionary = {}
var total_wins := 0
var runs_lost := 0
var signs_used := 0
var challenges_won: Dictionary = {}
## Highest stake each Jester was part of a win on.
var badges: Dictionary = {}

# Batch 13 (progression).
## Fame per Jester (def id → fame); at Fame.MAESTRO it plays as its Maestro.
var fame: Dictionary = {}
## The wagon: scudi to spend, props owned and the ones carried (one slot, two once bought),
## cosmetics owned and worn ({paint, trims: [], cloth, back, curtain}), and cards unlocked by
## buying them or by a campaign reward.
var scudi := 0
var props_owned: Dictionary = {}
var prop_slots := 1
var carried: Array[String] = []
var cosmetics: Dictionary = {}
var worn: Dictionary = {}
var bought: Dictionary = {}
## The campaign: chapters cleared in order, and the Jester carried into the next one
## ({id, parts}).
var chapters_cleared := 0
var carry: Dictionary = {}
var titles: Array[String] = []
## The Patron that ended the last run ({patron, town}), waiting in the next one.
var nemesis: Dictionary = {}
## Shown once: the Wagon after the first chapter.
var wagon_seen := false
## What the last recorded run brought: {fame: {id: n}, scudi: [{src, v}], reward: {...},
## nemesis: "set" / "beaten" / ""}, for the end screen.
var last_gains: Dictionary = {}


## Call once when a run ends (won and abandoned, or lost). A run that doesn't `count` (a
## seeded one) only adds its discoveries: no feats, wins or losses, fame or scudi.
## `gave_up`: the player left it, so no Patron becomes the nemesis.
func record_run(run: RunState, counts := true, gave_up := false) -> void:
	last_gains = {}
	for id in run.seen:
		discovered[id] = true
	if not counts:
		return
	for f in run.feats:
		feats[f] = true
	signs_used += int(run.counters.get("used_sign", 0))
	if run.won:
		if run.challenge != "":
			challenges_won[run.challenge] = true
		else:
			total_wins += 1
			best_stake[run.deck_id] = maxi(int(best_stake.get(run.deck_id, 0)), run.stake)
			for z in run.zanni:
				badges[z.def_id] = maxi(int(badges.get(z.def_id, 0)), run.stake)
	elif run.phase == RunState.Phase.LOST:
		runs_lost += 1
	_record_progress(run, gave_up)


## Fame, scudi, the nemesis and a campaign chapter's first clear.
func _record_progress(run: RunState, gave_up: bool) -> void:
	for id in run.fame:
		fame[id] = int(fame.get(id, 0)) + int(run.fame[id])
	var earned := WagonCards.scudi_for(run)
	for item in earned:
		scudi += int(item["v"])
	last_gains = {"fame": run.fame.duplicate(), "scudi": earned, "reward": {}, "nemesis": ""}
	if bool(run.extras.get("rivalry", false)):
		if int(run.counters.get("nemesis_beaten", 0)) > 0:
			nemesis = {}
			last_gains["nemesis"] = "beaten"
		if run.phase == RunState.Phase.LOST and not gave_up and run.show_index == Shows.PATRON and run.town_patron != "":
			nemesis = {"patron": run.town_patron, "town": run.town}
			last_gains["nemesis"] = "set"
	var chapter_def := ContentDB.get_def(run.chapter)
	if run.won and chapter_def != null and int(chapter_def.data["n"]) == chapters_cleared + 1:
		chapters_cleared += 1
		carry = {}
		var reward: Dictionary = chapter_def.data["reward"]
		scudi += int(reward.get("scudi", 0))
		if reward.has("deck"):
			bought[str(reward["deck"])] = true
		if reward.has("cosmetic"):
			cosmetics[str(reward["cosmetic"])] = true
		if reward.has("title") and not titles.has(str(reward["title"])):
			titles.append(str(reward["title"]))
		last_gains["reward"] = reward.duplicate()


## What this profile brings to a normal run, or to campaign chapter `chapter_id` (the next one
## also gets the carried Jester): Maestri, carried props, the nemesis, the Patron rivalry.
## Daily, seeded and challenge runs get none (Game.new_run).
func extras_for(chapter_id := "") -> Dictionary:
	var out := {"rivalry": true}
	var masters := maestri()
	if not masters.is_empty():
		out["maestri"] = masters
	if not carried.is_empty():
		out["props"] = carried.duplicate()
	if not nemesis.is_empty():
		out["nemesis"] = nemesis.duplicate()
	var chapter_def := ContentDB.get_def(chapter_id)
	if chapter_def != null:
		out["chapter"] = chapter_id
		if int(chapter_def.data["n"]) == chapters_cleared + 1 and not carry.is_empty():
			out["carry"] = carry.duplicate(true)
	return out


## Fair play (Luca, 2026-10-22): only normal runs and the campaign get the profile's extras;
## daily, seeded and challenge runs play the same for everyone (weekly and duel runs, group
## 4, will join this list).
static func brings_extras(challenge_id: String, meta: Dictionary) -> bool:
	return challenge_id == "" and not meta.has("daily_date") and not bool(meta.get("seeded", false))


## Every Jester that has reached Maestro.
func maestri() -> Array:
	return fame.keys().filter(func(id: String) -> bool: return int(fame[id]) >= Fame.MAESTRO)


func fame_of(def_id: String) -> int:
	return int(fame.get(def_id, 0))


# --- the wagon ---

func can_afford(price: int) -> bool:
	return scudi >= price


## Buys a prop; false if owned already or not enough scudi.
func buy_prop(id: String) -> bool:
	var d := ContentDB.get_def(id)
	if d == null or d.kind != "prop" or props_owned.has(id) or scudi < d.cost:
		return false
	scudi -= d.cost
	props_owned[id] = true
	if carried.size() < prop_slots:
		carried.append(id)
	return true


func buy_prop_slot() -> bool:
	if prop_slots >= 2 or scudi < WagonCards.PROP_SLOT_PRICE:
		return false
	scudi -= WagonCards.PROP_SLOT_PRICE
	prop_slots = 2
	return true


## Carries an owned prop (dropping the oldest when the slots are full), or puts it down.
func carry_prop(id: String, on: bool) -> void:
	if not on:
		carried.erase(id)
		return
	if not props_owned.has(id) or carried.has(id):
		return
	carried.append(id)
	while carried.size() > prop_slots:
		carried.remove_at(0)


func buy_cosmetic(id: String) -> bool:
	var c := WagonCards.cosmetic(id)
	if c.is_empty() or cosmetics.has(id) or c["campaign"] or scudi < int(c["price"]):
		return false
	scudi -= int(c["price"])
	cosmetics[id] = true
	return true


## Wears an owned cosmetic in its slot; "" takes the slot's off. Trims are worn together.
func wear(slot: String, id: String) -> void:
	if id != "" and not cosmetics.has(id):
		return
	if slot == "trim":
		var trims: Array = worn.get("trims", [])
		if trims.has(id):
			trims.erase(id)
		elif id != "":
			trims.append(id)
		worn["trims"] = trims
	else:
		worn[slot] = id


func worn_colour(slot: String, fallback: Color) -> Color:
	var c := WagonCards.cosmetic(str(worn.get(slot, "")))
	return c["colour"] if not c.is_empty() else fallback


## Buys something still locked: a deck, a rare Jester or a challenge.
func buy_unlock(id: String) -> bool:
	var d := ContentDB.get_def(id)
	if d == null or bought.has(id):
		return false
	var price := int(WagonCards.UNLOCK_PRICES.get(d.kind, 0))
	if price <= 0 or scudi < price or not unlock_for_sale(id):
		return false
	scudi -= price
	bought[id] = true
	return true


## Whether this card is locked and can be bought early.
func unlock_for_sale(id: String) -> bool:
	var d := ContentDB.get_def(id)
	if d == null or bought.has(id):
		return false
	match d.kind:
		"deck":
			return not deck_unlocked(id)
		"zanni":
			return not is_unlocked(id)
		"challenge":
			return not challenge_unlocked(id)
	return false


func is_unlocked(def_id: String) -> bool:
	return bought.has(def_id) or not Unlocks.RARE_FEATS.has(def_id) or _met(Unlocks.RARE_FEATS[def_id])


## Ids to pass to RunState.create so locked cards never turn up.
func locked_cards() -> Array:
	return Unlocks.RARE_FEATS.keys().filter(func(id: String) -> bool: return not is_unlocked(id))


func deck_unlocked(deck_id: String) -> bool:
	var rule := str(Unlocks.DECK_RULES.get(deck_id, ""))
	if rule == "" or bought.has(deck_id):
		return true
	var parts := rule.split(":")
	if parts[0] == "discover":
		return discovered.size() >= int(parts[1])
	return best_stake.has(parts[1])


## The highest stake this deck can be played on: one above its best win.
func max_stake(deck_id: String) -> int:
	return mini(Unlocks.TOP_STAKE, int(best_stake.get(deck_id, 0)) + 1)


func challenge_unlocked(challenge_id: String) -> bool:
	if bought.has(challenge_id):
		return true
	var order := ContentDB.pool("challenge").map(func(d: ContentDef) -> String: return d.id)
	var index := order.find(challenge_id)
	return index >= 0 and index < total_wins * Unlocks.CHALLENGES_PER_WIN


func _met(rule: String) -> bool:
	if not rule.begins_with("lifetime:"):
		return feats.has(rule)
	var spec := rule.substr(9).split(">=")
	var have := 0
	match spec[0]:
		"runs_lost":
			have = runs_lost
		"signs_used":
			have = signs_used
	return have >= int(spec[1])


func to_dict() -> Dictionary:
	return {
		"discovered": discovered.keys(), "feats": feats.keys(), "best_stake": best_stake.duplicate(),
		"total_wins": total_wins, "runs_lost": runs_lost, "signs_used": signs_used,
		"challenges_won": challenges_won.keys(), "badges": badges.duplicate(),
		"fame": fame.duplicate(), "scudi": scudi, "props": props_owned.keys(), "prop_slots": prop_slots,
		"carried": carried.duplicate(), "cosmetics": cosmetics.keys(), "worn": worn.duplicate(true),
		"bought": bought.keys(), "chapters": chapters_cleared, "carry": carry.duplicate(true),
		"titles": titles.duplicate(), "nemesis": nemesis.duplicate(), "wagon_seen": wagon_seen,
	}


static func from_dict(d: Dictionary) -> Profile:
	var p := Profile.new()
	for id in d.get("discovered", []):
		p.discovered[str(id)] = true
	for f in d.get("feats", []):
		p.feats[str(f)] = true
	for deck in d.get("best_stake", {}):
		p.best_stake[str(deck)] = int(d["best_stake"][deck])
	p.total_wins = int(d.get("total_wins", 0))
	p.runs_lost = int(d.get("runs_lost", 0))
	p.signs_used = int(d.get("signs_used", 0))
	for c in d.get("challenges_won", []):
		p.challenges_won[str(c)] = true
	for z in d.get("badges", {}):
		p.badges[str(z)] = int(d["badges"][z])
	for z in d.get("fame", {}):
		p.fame[str(z)] = int(d["fame"][z])
	p.scudi = int(d.get("scudi", 0))
	for id in d.get("props", []):
		p.props_owned[str(id)] = true
	p.prop_slots = clampi(int(d.get("prop_slots", 1)), 1, 2)
	for id in d.get("carried", []):
		p.carried.append(str(id))
	for id in d.get("cosmetics", []):
		p.cosmetics[str(id)] = true
	p.worn = (d.get("worn", {}) as Dictionary).duplicate(true)
	for id in d.get("bought", []):
		p.bought[str(id)] = true
	p.chapters_cleared = int(d.get("chapters", 0))
	p.carry = (d.get("carry", {}) as Dictionary).duplicate(true)
	for t in d.get("titles", []):
		p.titles.append(str(t))
	var n: Dictionary = d.get("nemesis", {})
	if not n.is_empty():
		p.nemesis = {"patron": str(n["patron"]), "town": int(n["town"])}
	p.wagon_seen = bool(d.get("wagon_seen", false))
	return p
