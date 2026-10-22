class_name CampaignCards
extends RefCounted
## Card batch 13 (reviewed 2026-10-22): the campaign, Il Lungo Giro. Sixteen chapters, one
## per city, each a full 8-town run whose map starts where the last chapter ended and ends
## in the chapter's city, where its story Patron waits as the town 8 Patron. A chapter is a
## source of its runs (RunState._sources): its own hooks, plus the twist of its rule city all
## tour long. Difficulty climbs by stake (Luca, 2026-10-22). Data: city, start, patron,
## stake, deck (suggested), rule_city, scenario_tier, reward {scudi, deck, cosmetic, title}.
## Messer Grifone, the last chapter's Patron, appears only there.

const GRIFONE := "pt_grifone"
const COUNT := 16


static func register() -> void:
	# After each hand Grifone "buys out" the rightmost Jester still working, for the show.
	var buy_out := func(run: RunState, _item: ItemCard, _cards: Array) -> void:
		for i in range(run.zanni.size() - 1, -1, -1):
			if not run.zanni[i].debuffed:
				run.zanni[i].debuffed = true
				return
	ContentDB.register(ContentDef.make(GRIFONE, "patron", 0, 0, {"hand_played": buy_out},
		{"min_town": 8, "finale": true, "campaign": true, "target_mult": 5.0, "reward_bonus": 3}))

	_add(1, "c_bergamo", "c_bergamo", "pt_censore", "d_bergamo", "", {"scudi": 20}, {}, {"scenario_tier": 1})
	_add(2, "c_milano", "c_bergamo", "pt_banchiere", "d_bergamo", "c_milano", {"scudi": 20})
	_add(3, "c_torino", "c_milano", "pt_ciambellano", "d_padova", "c_torino", {"scudi": 20, "cosmetic": "back_corte"})
	var no_purse := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return 0 if stat == "start_ducats" else value
	_add(4, "c_genova", "c_torino", "pt_gabelliere", "d_genova", "c_genova", {"scudi": 20, "deck": "d_genova"}, {"modify_stat": no_purse})
	_add(5, "c_lucca", "c_genova", "pt_fortezza", "d_siena", "c_lucca", {"scudi": 25})
	var enhanced_packs := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value + 1 if stat == "pack_enhanced_card" else value
	_add(6, "c_firenze", "c_lucca", "pt_critico", "d_firenze", "", {"scudi": 25, "deck": "d_firenze"}, {"modify_stat": enhanced_packs})
	_add(7, "c_siena", "c_firenze", "pt_purista", "d_siena", "c_siena", {"scudi": 25, "deck": "d_siena"})
	_add(8, "c_roma", "c_siena", "pt_vescovo", "d_roma", "c_roma", {"scudi": 25, "deck": "d_roma"})
	_add(9, "c_napoli", "c_roma", "pt_borsaiolo", "d_napoli", "c_napoli", {"scudi": 30, "deck": "d_napoli"})
	var at_sea := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value - 1 if stat == "hands" else value
	_add(10, "c_bari", "c_napoli", "pt_maggiordomo", "d_benevento", "c_bari", {"scudi": 30, "cosmetic": "trim_sail"}, {"modify_stat": at_sea})
	_add(11, "c_palermo", "c_bari", "pt_marchese", "d_palermo", "c_palermo", {"scudi": 30, "deck": "d_palermo"})
	_add(12, "c_urbino", "c_palermo", "pt_impaziente", "d_ferrara", "c_urbino", {"scudi": 30})
	_add(13, "c_bologna", "c_urbino", "pt_avaro", "d_bologna", "c_bologna", {"scudi": 35, "deck": "d_bologna"})
	_add(14, "c_mantova", "c_bologna", "pt_contessa", "d_mantova", "c_mantova", {"scudi": 35, "deck": "d_mantova"})
	_add(15, "c_verona", "c_mantova", "pt_badessa", "d_verona", "c_verona", {"scudi": 35, "deck": "d_verona"})
	_add(16, CityCards.VENEZIA, "c_verona", GRIFONE, "d_venezia", "",
		{"scudi": 100, "deck": "d_carnevale", "cosmetic": "paint_oro", "title": "Compagnia Reale"})


static func _add(n: int, city: String, start: String, patron: String, deck: String, rule_city: String,
		reward: Dictionary, hooks := {}, extra := {}) -> void:
	var data := {"n": n, "city": city, "start": start, "patron": patron, "deck": deck,
		"rule_city": rule_city, "stake": stake_of(n), "reward": reward}
	data.merge(extra)
	ContentDB.register(ContentDef.make(id_of(n), "chapter", 0, 0, hooks, data))


static func id_of(n: int) -> String:
	return "ch_%02d" % n


## Chapters 1–4 at Stake 1, 5–8 at Stake 2, 9–12 at Stake 3, 13–16 at Stake 4.
static func stake_of(n: int) -> int:
	return (n - 1) / 4 + 1


static func chapters() -> Array[ContentDef]:
	return ContentDB.pool("chapter")
