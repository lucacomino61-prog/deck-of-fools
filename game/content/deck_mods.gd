class_name DeckMods
extends RefCounted
## Card batch 2 (approved 2026-10-21): the 8 enhancements, 4 editions and 4 seals that
## Tarocchi and packs put on cards. Card text lives in i18n/cards.csv.


static func register() -> void:
	_enhancements()
	_editions()
	_seals()


static func _enhancements() -> void:
	var lacquered := func(ctx: ScoreContext, _item: ItemCard, card: PlayingCard) -> void:
		ctx.add_points(30, "enh_lacquered", card.id)
	_add("enh_lacquered", "enhancement", {"card_scored": lacquered})

	var masked := func(ctx: ScoreContext, _item: ItemCard, card: PlayingCard) -> void:
		ctx.add_mult(4, "enh_masked", card.id)
	_add("enh_masked", "enhancement", {"card_scored": masked})

	_add("enh_motley", "enhancement", {}, {"any_suit": true})

	var mirror_hits := func(ctx: ScoreContext, _item: ItemCard, card: PlayingCard) -> void:
		ctx.x_mult(2, "enh_mirror", card.id)
	var mirror_shatters := func(ctx: ScoreContext, _item: ItemCard, card: PlayingCard) -> void:
		if ctx.run.stat("mirror_safe") > 0 or ctx.destroyed.has(card):
			return
		if ctx.run.roll("mirror", 1, ctx.run.stat("mirror_odds")):
			ctx.destroyed.append(card)
			ctx.note("shattered", "enh_mirror", card.id)
	_add("enh_mirror", "enhancement", {"card_scored": mirror_hits, "after_scored": mirror_shatters})

	var iron := func(ctx: ScoreContext, _item: ItemCard, card: PlayingCard) -> void:
		ctx.x_mult(1.5, "enh_iron", card.id)
	_add("enh_iron", "enhancement", {"card_held": iron})

	_add("enh_marble", "enhancement", {},
		{"no_rank": true, "no_suit": true, "always_scores": true, "points_override": 50})

	var gilt := func(run: RunState, _item: ItemCard, _card: PlayingCard) -> int:
		return 3 * run.stat("gilt_mult")
	_add("enh_gilt", "enhancement", {"payout_held": gilt})

	var charmed := func(ctx: ScoreContext, _item: ItemCard, card: PlayingCard) -> void:
		if ctx.run.roll("charm", 1, 5):
			ctx.add_mult(20, "enh_charmed", card.id)
		if ctx.run.roll("charm", 1, 15):
			ctx.add_ducats(20, "enh_charmed", card.id)
	_add("enh_charmed", "enhancement", {"card_scored": charmed})


## Editions shine a playing card when it scores, or a zanni around its own effect.
## shop_chance / extra_cost: odds and surcharge on a shop zanni. appeso_weight: L'Appeso's pick.
static func _editions() -> void:
	var silvered_card := func(ctx: ScoreContext, _item: ItemCard, card: PlayingCard) -> void:
		ctx.add_points(50, "ed_silvered", card.id)
	var silvered_zanni := func(ctx: ScoreContext, item: ItemCard) -> void:
		ctx.add_points(50, ctx.run.item_source(item))
	_add("ed_silvered", "edition", {"card_scored": silvered_card, "zanni_pre": silvered_zanni},
		{"shop_chance": 0.02, "extra_cost": 2, "on_cards": true, "appeso_weight": 50})

	var opaline_card := func(ctx: ScoreContext, _item: ItemCard, card: PlayingCard) -> void:
		ctx.add_mult(10, "ed_opaline", card.id)
	var opaline_zanni := func(ctx: ScoreContext, item: ItemCard) -> void:
		ctx.add_mult(10, ctx.run.item_source(item))
	_add("ed_opaline", "edition", {"card_scored": opaline_card, "zanni_pre": opaline_zanni},
		{"shop_chance": 0.014, "extra_cost": 3, "on_cards": true, "appeso_weight": 35})

	var prismatic_card := func(ctx: ScoreContext, _item: ItemCard, card: PlayingCard) -> void:
		ctx.x_mult(1.5, "ed_prismatic", card.id)
	var prismatic_zanni := func(ctx: ScoreContext, item: ItemCard) -> void:
		ctx.x_mult(1.5, ctx.run.item_source(item))
	_add("ed_prismatic", "edition", {"card_scored": prismatic_card, "zanni_post": prismatic_zanni},
		{"shop_chance": 0.003, "extra_cost": 5, "on_cards": true, "appeso_weight": 15})

	var shadow_slot := func(run: RunState, item: ItemCard, stat: String, value: int) -> int:
		if item == null:
			return value
		if stat == "zanni_slots" and run.zanni.has(item):
			return value + 1
		if stat == "consumable_slots" and run.consumables.has(item):
			return value + 1
		return value
	_add("ed_shadow", "edition", {"modify_stat": shadow_slot},
		{"shop_chance": 0.003, "extra_cost": 5, "on_cards": false, "adds_slot": true})


static func _seals() -> void:
	var ducal := func(ctx: ScoreContext, _item: ItemCard, card: PlayingCard) -> void:
		ctx.add_ducats(3, "seal_ducal", card.id)
	_add("seal_ducal", "seal", {"card_scored": ducal})

	var encore := func(_ctx: ScoreContext, _item: ItemCard, _card: PlayingCard) -> int:
		return 1
	_add("seal_encore", "seal", {"retrigger_scored": encore})

	var astral := func(run: RunState, _item: ItemCard, _card: PlayingCard) -> void:
		var hand := str(run.counters.get("last_hand", ""))
		if hand != "":
			run.create_consumable(SignCards.for_hand(hand))
	_add("seal_astral", "seal", {"won_held": astral})

	var oracle := func(run: RunState, _item: ItemCard, _card: PlayingCard) -> void:
		var pool := ContentDB.pool("tarocchi")
		if not pool.is_empty() and run.free_consumable_slots() > 0:
			run.create_consumable(pool[run.rng("oracle").below(pool.size())].id)
	_add("seal_oracle", "seal", {"discarded": oracle})


static func _add(def_id: String, kind: String, hooks: Dictionary, data := {}) -> void:
	ContentDB.register(ContentDef.make(def_id, kind, 0, 0, hooks, data))
