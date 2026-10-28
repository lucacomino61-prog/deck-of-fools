class_name Learning
extends RefCounted
## One new thing per run (Luca, 2026-10-28): a new player's first normal run has only the
## heart of the game (poker hands, the four shows and their Patrons, Jesters, playing cards
## in the Market, Jester and card packs). Each finished run switches on the next part, with a
## line saying what it is. From the seventh run on, everything is on. Daily, seeded and
## challenge runs, the campaign and the Grand Tour always play the whole game; Settings can
## switch it all on from the start.

## Each part and the run it arrives in (0 = the first run).
const PARTS := {
	"signs": 1,
	"tarocchi": 2,
	"favors": 3,
	"warrants": 3,
	"map": 4,
	"scenarios": 5,
	"crowd": 5,
	"omens": 6,
	"lazzi": 6,
}
## The level at which everything is on.
const FULL := 6

## What each level brings, as the run screen and the end screen say it.
const NEWS := [
	"",
	"Signs: zodiac cards in the Market that level up a poker hand for the rest of the run.",
	"Tarocchi: magic cards that change your playing cards (more points, a new suit, a copy).",
	"Skipping a show for its Favor, and Warrants: permanent upgrades for the run, one per town.",
	"The Map of Italy: after each Patron you choose the next city, and every city has its own twist.",
	"Scenarios and the crowd: perform a scripted show for big rewards, keep the audience happy for an Encore.",
	"Omens (rare, powerful, risky cards) and Lazzi: two Jesters that belong together merge into one.",
]


static func has(level: int, part: String) -> bool:
	return level >= int(PARTS.get(part, 0))


## What the next run brings for a player at `level`, or "" when everything is on already.
static func next_news(level: int) -> String:
	return NEWS[level + 1] if level + 1 <= FULL else ""
