class_name PlayingCard
extends RefCounted
## A card in the player's deck. Enhancement, edition and seal hold content ids ("" = none);
## their rules live in ContentDB. Enhancement data flags change what the card is:
## "no_rank", "no_suit", "any_suit", "always_scores", "points_override".

enum Suit { SPADES, HEARTS, CLUBS, DIAMONDS }

const JACK := 11
const QUEEN := 12
const KING := 13
const ACE := 14

const RANK_LABELS := {11: "J", 12: "Q", 13: "K", 14: "A", 10: "T"}
const SUIT_LABELS := ["S", "H", "C", "D"]

var id := 0
var rank := 2
var suit := 0
var enhancement := ""
var edition := ""
var seal := ""
var bonus_points := 0
var debuffed := false
## Dealt face down by a Patron: plays normally, the screen just hides it until played.
var face_down := false


static func make(card_id: int, card_rank: int, card_suit: int) -> PlayingCard:
	var card := PlayingCard.new()
	card.id = card_id
	card.rank = card_rank
	card.suit = card_suit
	return card


func _flag(name: String) -> bool:
	var d := ContentDB.get_def(enhancement)
	return d != null and bool(d.data.get(name, false))


func has_rank() -> bool:
	return not _flag("no_rank")


func has_suit(s: int) -> bool:
	if _flag("no_suit"):
		return false
	if _flag("any_suit"):
		return true
	return suit == s


func always_scores() -> bool:
	return _flag("always_scores")


func is_face() -> bool:
	return has_rank() and rank >= JACK and rank <= KING


func base_points() -> int:
	var d := ContentDB.get_def(enhancement)
	if d != null and d.data.has("points_override"):
		return int(d.data["points_override"])
	if not has_rank():
		return 0
	if rank == ACE:
		return 11
	if rank >= JACK:
		return 10
	return rank


## Short name for logs and tests, e.g. "KH", "TS", "2C".
func label() -> String:
	return str(RANK_LABELS.get(rank, rank)) + SUIT_LABELS[suit]


func to_dict() -> Dictionary:
	return {
		"id": id, "rank": rank, "suit": suit,
		"enh": enhancement, "ed": edition, "seal": seal,
		"bonus": bonus_points, "debuffed": debuffed, "face_down": face_down,
	}


static func from_dict(d: Dictionary) -> PlayingCard:
	var card := make(int(d["id"]), int(d["rank"]), int(d["suit"]))
	card.enhancement = str(d.get("enh", ""))
	card.edition = str(d.get("ed", ""))
	card.seal = str(d.get("seal", ""))
	card.bonus_points = int(d.get("bonus", 0))
	card.debuffed = bool(d.get("debuffed", false))
	card.face_down = bool(d.get("face_down", false))
	return card
