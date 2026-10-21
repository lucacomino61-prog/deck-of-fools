class_name WarrantCards
extends RefCounted
## Card batch 9 (approved 2026-10-21): 16 Warrants and their 16 upgrades. An upgrade
## (data "requires") is only offered once its base Warrant is owned. One Warrant is on sale
## per town; they last the whole run.

const COST := 10


static func register() -> void:
	_pair("w_bottega", _plus("shop_slots", 1), "w_bottega_grande", _plus("shop_slots", 1))
	_pair("w_sconto", _at_least("shop_discount_pct", 25), "w_svendita", _at_least("shop_discount_pct", 50))
	_pair("w_lustrini", _at_least("edition_rate_pct", 200), "w_paillettes", _at_least("edition_rate_pct", 400))
	_pair("w_rimescolo", _plus("reroll_discount", 2), "w_rimescolo_perpetuo", _plus("reroll_discount", 2))
	_pair("w_baule", _plus("consumable_slots", 1), "w_baule_presagi", _plus("omens_in_tarocchi_packs", 1))

	# L'Osservatorio: each Sign you hold gives ×1.5 Mult when you play its hand.
	var osservatorio := func(ctx: ScoreContext, _item: ItemCard) -> void:
		for c in ctx.run.consumables:
			var d := c.def()
			if d != null and d.kind == "sign" and str(d.data.get("hand", "")) == ctx.hand_type:
				ctx.x_mult(1.5, "w_osservatorio")
	_pair("w_cannocchiale", _plus("sign_pack_favourite", 1), "w_osservatorio", {"scored": osservatorio})

	_pair("w_copione_lungo", _plus("hands", 1), "w_secondo_atto", _plus("hands", 1))
	_pair("w_cestino", _plus("discards", 1), "w_riciclo", _plus("discards", 1))
	_pair("w_mazzo_tarocchi", _at_least("tarocchi_rate_pct", 200), "w_bottega_arcano", _at_least("tarocchi_rate_pct", 400))
	_pair("w_mappa_celeste", _at_least("sign_rate_pct", 200), "w_atlante_celeste", _at_least("sign_rate_pct", 400))
	_pair("w_salvadanaio", _plus("interest_cap", 5), "w_banca_san_giorgio", _plus("interest_cap", 10))
	_pair("w_foglio_bianco", {}, "w_inchiostro_nero", _plus("zanni_slots", 1))
	_pair("w_mazzo_prestigiatore", _plus("card_rate", 4), "w_gran_trucco", _plus("card_quality", 1))

	# La Clessidra and La Meridiana: back one town at once, with a lasting cost.
	var clessidra := _plus("hands", -1)
	clessidra["gain"] = WarrantCards._back_one_town()
	var meridiana := _plus("discards", -1)
	meridiana["gain"] = WarrantCards._back_one_town()
	_pair("w_clessidra", clessidra, "w_meridiana", meridiana)

	_pair("w_ricatto", _plus("patron_swaps", 1), "w_corruzione", _plus("patron_swaps", 99))
	_pair("w_pennello", _plus("hand_size", 1), "w_tavolozza", _plus("hand_size", 1))


static func _back_one_town() -> Callable:
	var f := func(run: RunState, _item: ItemCard) -> void:
		run.town = maxi(1, run.town - 1)
	return f


static func _plus(stat_name: String, amount: int) -> Dictionary:
	var f := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value + amount if stat == stat_name else value
	return {"modify_stat": f}


## Raises a stat to at least `floor_value` (an upgrade replaces its base, it doesn't add).
static func _at_least(stat_name: String, floor_value: int) -> Dictionary:
	var f := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return maxi(value, floor_value) if stat == stat_name else value
	return {"modify_stat": f}


static func _pair(base_id: String, base_hooks: Dictionary, upgrade_id: String, upgrade_hooks: Dictionary) -> void:
	ContentDB.register(ContentDef.make(base_id, "warrant", COST, 0, base_hooks))
	ContentDB.register(ContentDef.make(upgrade_id, "warrant", COST, 0, upgrade_hooks, {"requires": base_id}))
