class_name Unlocks
extends RefCounted
## Card batch 11 (approved 2026-10-21): what unlocks what. Commons, uncommons and
## legendaries are never locked; each rare needs a feat (RunState.feats, or a lifetime count
## written "lifetime:<counter>>=<n>"). Decks unlock by discovery or by winning with another
## deck; challenges unlock 5 per win; stakes unlock per deck by winning the one below.

const RARE_FEATS := {
	"z_burattinaio": "jesters_5",
	"z_mattacino": "won_with_burattinaio",
	"z_re_dei_folli": "won_run",
	"z_compagnia": "jesters_6",
	"z_capriccio": "all_hands",
	"z_maschera_oro": "ducats_50",
	"z_orologio": "patrons_8",
	"z_notturno": "patron_first_hand",
	"z_gemelli": "identical_cards",
	"z_gioco_parti": "points_1000",
	"z_pittore": "played_flush",
	"z_gran_ballo": "played_straight_flush",
	"z_teatro_olimpico": "won_on_last_hand",
	"z_nebbia": "lost_to_patron",
	"z_fenice": "lifetime:runs_lost>=5",
	"z_banditore": "signs_20",
	"z_maestro_cappella": "level_5",
	"z_carnevale": "enhanced_10",
	"z_prestigiatore": "editions_3",
	"z_doge": "interest_10",
	"z_cometa": "lifetime:signs_used>=50",
	"z_prima_donna": "won_with_one_jester",
}

## "" = from the start; "discover:N" = N cards seen in the collection; "win:<deck>".
const DECK_RULES := {
	"d_bergamo": "",
	"d_venezia": "discover:20",
	"d_genova": "discover:40",
	"d_siena": "discover:60",
	"d_napoli": "discover:80",
	"d_palermo": "win:d_bergamo",
	"d_padova": "win:d_venezia",
	"d_benevento": "win:d_genova",
	"d_verona": "win:d_siena",
	"d_ferrara": "win:d_napoli",
	"d_bologna": "win:d_palermo",
	"d_firenze": "win:d_padova",
	"d_roma": "win:d_benevento",
	"d_mantova": "win:d_verona",
	"d_carnevale": "win:d_ferrara",
}

const CHALLENGES_PER_WIN := 5
const TOP_STAKE := 8
