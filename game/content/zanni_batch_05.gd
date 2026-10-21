class_name ZanniBatch05
extends RefCounted
## Card batch 5 (approved 2026-10-21): 20 rare Jesters and the 5 legendary ones, the
## historical figures of the commedia. Legendaries never appear in the shop.
## Card names and text live in i18n/cards.csv.

const RARE := 2
const LEGENDARY := 3
const LEGENDARY_COST := 20


static func register() -> void:
	_rares()
	_legendaries()


static func _rares() -> void:
	# Copying and the troupe
	_add("z_burattinaio", 10, RARE, {}, {"copies": "right"})
	_add("z_mattacino", 10, RARE, {}, {"copies": "leftmost"})

	var re_dei_folli := func(ctx: ScoreContext, item: ItemCard) -> void:
		var others := ctx.run.zanni.size() - 1
		if others > 0:
			ctx.x_mult(pow(1.2, others), ctx.run.item_source(item))
	_add("z_re_dei_folli", 9, RARE, {"independent": re_dei_folli})

	_add("z_compagnia", 9, RARE, _stat_plus("zanni_slots", 2))

	# Big Mult
	var capriccio_picks := func(run: RunState, item: ItemCard) -> void:
		var hands: Array = HandTable.ORDER.filter(func(h: String) -> bool: return run.hand_levels.is_visible(h))
		item.state["hand"] = hands[run.rng("capriccio").below(hands.size())]
	var capriccio := func(ctx: ScoreContext, item: ItemCard) -> void:
		if str(item.state.get("hand", "")) == ctx.hand_type:
			ctx.x_mult(3, ctx.run.item_source(item))
	_add("z_capriccio", 8, RARE, {"show_start": capriccio_picks, "independent": capriccio})

	var maschera_oro := func(ctx: ScoreContext, item: ItemCard) -> void:
		var steps := floori(ctx.run.ducats / 5.0)
		if steps > 0:
			ctx.x_mult(1.0 + 0.1 * steps, ctx.run.item_source(item))
	_add("z_maschera_oro", 8, RARE, {"independent": maschera_oro})

	var orologio_ticks := func(run: RunState, item: ItemCard) -> void:
		if run.show_index == Shows.PATRON:
			item.state["ticks"] = int(item.state.get("ticks", 0)) + 1
	var orologio := func(ctx: ScoreContext, item: ItemCard) -> void:
		var ticks := int(item.state.get("ticks", 0))
		if ticks > 0:
			ctx.x_mult(1.0 + 0.25 * ticks, ctx.run.item_source(item))
	_add("z_orologio", 8, RARE, {"show_end": orologio_ticks, "independent": orologio})

	var notturno := func(ctx: ScoreContext, item: ItemCard) -> void:
		if ctx.run.show_index == Shows.PATRON:
			ctx.x_mult(2, ctx.run.item_source(item))
	_add("z_notturno", 7, RARE, {"independent": notturno})

	var gemelli := func(ctx: ScoreContext, item: ItemCard) -> void:
		for i in ctx.played.size():
			var a := ctx.played[i]
			if not a.has_rank() or not a.has_suit(a.suit):
				continue
			for j in range(i + 1, ctx.played.size()):
				var b := ctx.played[j]
				if b.has_rank() and b.has_suit(b.suit) and a.rank == b.rank and a.suit == b.suit:
					ctx.x_mult(3, ctx.run.item_source(item))
					return
	_add("z_gemelli", 8, RARE, {"independent": gemelli})

	var gioco_delle_parti := func(ctx: ScoreContext, item: ItemCard) -> void:
		ctx.swap(ctx.run.item_source(item))
	_add("z_gioco_parti", 8, RARE, {"independent": gioco_delle_parti})

	# Rules that bend
	var pittore := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return mini(value, 4) if stat == "flush_min" or stat == "straight_min" else value
	_add("z_pittore", 8, RARE, {"modify_stat": pittore})

	var gran_ballo := func(ctx: ScoreContext, _item: ItemCard, _card: PlayingCard) -> int:
		return 1 if ctx.has(HandTable.STRAIGHT) or ctx.has(HandTable.FLUSH) else 0
	_add("z_gran_ballo", 9, RARE, {"retrigger_scored": gran_ballo})

	var olimpico := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value + 1 if stat == "hands" or stat == "discards" else value
	_add("z_teatro_olimpico", 8, RARE, {"modify_stat": olimpico})

	var nebbia := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		if stat == "patron_muted":
			return value + 1
		if stat == "patron_target_pct":
			return value * 125 / 100
		return value
	_add("z_nebbia", 7, RARE, {"modify_stat": nebbia})

	var fenice := func(run: RunState, _item: ItemCard) -> bool:
		return run.show_score >= run.show_target * 0.25
	_add("z_fenice", 6, RARE, {"rescue": fenice})

	# Growth, Signs and money
	_add("z_banditore", 8, RARE, _stat_plus("sign_levels", 1))

	var maestro := func(ctx: ScoreContext, item: ItemCard) -> void:
		ctx.add_mult(3 * ctx.run.hand_levels.level(ctx.hand_type), ctx.run.item_source(item))
	_add("z_maestro_cappella", 7, RARE, {"independent": maestro})

	var carnevale := func(ctx: ScoreContext, item: ItemCard) -> void:
		for card in ctx.scoring:
			if not card.debuffed and ctx.run.is_face(card) and card.enhancement == "":
				card.enhancement = "enh_masked"
				ctx.note("masked", ctx.run.item_source(item), card.id)
	_add("z_carnevale", 7, RARE, {"after_score": carnevale})

	var prestigiatore := func(run: RunState, _item: ItemCard) -> void:
		var plain := run.full_deck.filter(func(c: PlayingCard) -> bool: return c.edition == "")
		var editions := ContentDB.pool("edition", func(d: ContentDef) -> bool: return d.data.has("appeso_weight"))
		if plain.is_empty() or editions.is_empty():
			return
		var r := run.rng("prestigiatore")
		var card: PlayingCard = plain[r.below(plain.size())]
		var weights := editions.map(func(d: ContentDef) -> int: return int(d.data["appeso_weight"]))
		card.edition = editions[r.pick_weighted(weights)].id
	_add("z_prestigiatore", 9, RARE, {"show_start": prestigiatore})

	var doge := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value * 2 if stat == "interest_mult" else value
	_add("z_doge", 8, RARE, {"modify_stat": doge})


static func _legendaries() -> void:
	var martinelli := func(ctx: ScoreContext, item: ItemCard) -> void:
		var left := ctx.run.zanni.find(item)
		if left > 0:
			ctx.x_mult(pow(1.5, left), ctx.run.item_source(item))
	_add("z_martinelli", LEGENDARY_COST, LEGENDARY, {"independent": martinelli})

	_add("z_andreini", LEGENDARY_COST, LEGENDARY,
		EffectKit.per_card(EffectKit.rank_in([PlayingCard.QUEEN]), 0, 0, 2.5))

	var goldoni := func(_ctx: ScoreContext, _item: ItemCard, _card: PlayingCard) -> int:
		return 1
	_add("z_goldoni", LEGENDARY_COST, LEGENDARY, {"retrigger_scored": goldoni})

	var gozzi_grows := func(_run: RunState, item: ItemCard, used: ItemCard) -> void:
		var used_def := used.def()
		if used_def != null and used_def.kind == "sign":
			item.state["signs"] = int(item.state.get("signs", 0)) + 1
	var gozzi := func(ctx: ScoreContext, item: ItemCard) -> void:
		var signs := int(item.state.get("signs", 0))
		if signs > 0:
			ctx.x_mult(1.0 + 0.5 * signs, ctx.run.item_source(item))
	_add("z_gozzi", LEGENDARY_COST, LEGENDARY, {"use": gozzi_grows, "independent": gozzi})

	var scala := func(run: RunState, _item: ItemCard) -> void:
		var hand := TarocchiCards.most_played(run)
		if hand != "":
			run.hand_levels.level_up(hand)
	_add("z_scala", LEGENDARY_COST, LEGENDARY, {"show_end": scala})


static func _stat_plus(stat_name: String, amount: int) -> Dictionary:
	var f := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value + amount if stat == stat_name else value
	return {"modify_stat": f}


static func _add(def_id: String, cost: int, rarity: int, hooks: Dictionary, data := {}) -> void:
	ContentDB.register(ContentDef.make(def_id, "zanni", cost, rarity, hooks, data))
