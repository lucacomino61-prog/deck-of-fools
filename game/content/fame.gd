class_name Fame
extends RefCounted
## Card batch 13 (reviewed 2026-10-22): Jester fame and the Maestri. A Jester earns fame
## while it performs (RunState.fame counts this run's; Profile keeps the totals). At 120 it
## becomes its Maestro version for good: in normal runs and the campaign every copy of it
## grows its numbers by SCALE, by the duo rule (RunState.duo_scale). A Jester with nothing
## to grow (counts, slots, copies, rules) pays FLAT_DUCATS at each cash-out instead.

## Fame for each star; the third makes the Maestro.
const STARS := [25, 60, 120]
const MAESTRO := 120
const SCALE := 1.25
## A duo whose two Jesters are both Maestri grows by this instead of the duo's 1.5.
const DUO_SCALE := 1.75

## Fame a Jester earns: each show won in which it fired, a winning Encore hand it fired in,
## being in the troupe when the run is won, and when the troupe beats its nemesis.
const SHOW := 1
const ENCORE := 1
const RUN_WON := 3
const NEMESIS := 2

const FLAT_DUCATS := 2
## Jesters whose effect is a count, a slot, a copy or a rule: as Maestri they pay ducats.
const FLAT := [
	"z_suggeritore", "z_trombettiere", "z_saltimbanco", "z_carro_tespi", "z_notaio", "z_ciarlatano",
	"z_vetraio", "z_prima", "z_teatrino", "z_pappagallo", "z_burattinaio", "z_mattacino",
	"z_compagnia", "z_gioco_parti", "z_pittore", "z_gran_ballo", "z_teatro_olimpico", "z_nebbia",
	"z_fenice", "z_banditore", "z_carnevale", "z_prestigiatore", "z_doge", "z_goldoni", "z_scala",
	"z_macchinista", "z_rigattiere", "z_eco", "z_sagrestano", "z_usuraio", "z_fattucchiere",
	"z_gigante", "z_mecenate", "z_sarta", "z_tipografo", "z_smemorato", "z_commedia",
	"z_ritrattista", "z_copista", "z_buttafuori", "z_ruffiana", "z_avvocato", "z_cometa",
	"z_bigliettaio",
]

## Hooks through which a Jester takes part in scoring or pays at cash-out. One without any of
## them works all the time (a slot, a rule) and counts as firing in every show it's in.
const ACTIVE_HOOKS := ["independent", "card_scored", "card_held", "retrigger_scored", "retrigger_held",
	"payout", "before_score", "after_base", "scored", "before_total", "after_score"]

## The women whose names carry no article.
const FEMALE := [
	"z_isabella", "z_colombina", "z_smeraldina", "z_corallina", "z_lucinda", "z_silvia",
	"z_rosaura", "z_mirandolina", "z_andreini",
]


## Stars for this much fame (0–3).
static func stars(fame: int) -> int:
	var n := 0
	for need in STARS:
		if fame >= need:
			n += 1
	return n


## Fame still needed for the next star; 0 once a Maestro.
static func to_next(fame: int) -> int:
	for need in STARS:
		if fame < need:
			return need - fame
	return 0


static func is_active(def: ContentDef) -> bool:
	for hook in ACTIVE_HOOKS:
		if def.has_hook(hook):
			return true
	return false


## A Maestro's name, by the Italian article: Maestro Arlecchino, Maestra Colombina (La Fioraia
## too), Maestri Gemelli; Il Maestro di Cappella becomes Il Gran Maestro di Cappella.
static func title(def_id: String, plain_name: String) -> String:
	if def_id == "z_maestro_cappella":
		return "Il Gran Maestro di Cappella"
	var word := "Maestra " if FEMALE.has(def_id) else "Maestro "
	var bare := plain_name
	for article in ["Il ", "La ", "Lo ", "L'", "I ", "Gli "]:
		if bare.begins_with(article):
			bare = bare.substr(article.length())
			if article == "La ":
				word = "Maestra "
			elif article == "I " or article == "Gli ":
				word = "Maestri "
			break
	return word + bare
