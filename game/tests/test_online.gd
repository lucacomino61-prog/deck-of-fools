extends TestCase
## The online pieces that need no server: the daily run is set up exactly as the server does
## it (server/src/daily.js and its tests use the same examples), and the cloud-save sync
## picks the right move.

## The deck order the server's daily run uses (server/src/daily.js, DECKS).
const SERVER_DECKS := [
	"d_bergamo", "d_venezia", "d_genova", "d_siena", "d_napoli", "d_palermo", "d_padova", "d_benevento",
	"d_verona", "d_ferrara", "d_bologna", "d_firenze", "d_roma", "d_mantova", "d_carnevale",
]


func test_the_daily_run_matches_the_server() -> void:
	ContentPacks.register_all()
	eq(ContentDB.pool("deck").map(func(d: ContentDef) -> String: return d.id), SERVER_DECKS, "the decks are in the server's order")
	eq(Online.daily_setup("2026-10-21"), {"date": "2026-10-21", "seed": "DAY20261021", "deck": "d_genova", "stake": 1})
	eq(Online.daily_setup("2026-12-31")["deck"], "d_mantova")
	eq(Online.daily_setup("2027-01-01")["deck"], "d_carnevale")


func test_a_daily_seed_makes_a_real_run() -> void:
	ContentPacks.register_all()
	var setup := Online.daily_setup("2026-10-21")
	var a := RunState.create(setup["seed"], setup["deck"], setup["stake"])
	var b := RunState.create(setup["seed"], setup["deck"], setup["stake"])
	eq(a.hand.map(func(c: PlayingCard) -> int: return c.id), b.hand.map(func(c: PlayingCard) -> int: return c.id), "everyone gets the same cards")


func test_cloud_sync_decisions() -> void:
	eq(Online.decide(0, 0, false), "none", "nothing anywhere")
	eq(Online.decide(0, 0, true), "push", "first save")
	eq(Online.decide(3, 3, true), "push", "only this device changed")
	eq(Online.decide(3, 3, false), "none", "in step")
	eq(Online.decide(4, 3, false), "pull", "only the cloud changed")
	eq(Online.decide(4, 3, true), "ask", "both changed: the player chooses")
	eq(Online.decide(0, 3, true), "push", "the cloud copy is gone: put this device's back")
