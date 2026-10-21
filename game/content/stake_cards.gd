class_name StakeCards
extends RefCounted
## Card batch 11 (approved 2026-10-21): the 8 stakes, named after theatre seats. A run on
## stake N plays under every stake from 1 to N (data "level").


static func register() -> void:
	_add("st_platea", 1, {})
	_add("st_galleria", 2, _stat_set("reward_matinee", 0))
	_add("st_palco", 3, _stat_at_least("target_scaling", 2))
	_add("st_palco_onore", 4, _stat_at_least("eternal_pct", 30))
	_add("st_palco_reale", 5, _stat_add("discards", -1))
	_add("st_proscenio", 6, _stat_at_least("target_scaling", 3))
	_add("st_ribalta", 7, _stat_at_least("perishable_on", 1))
	_add("st_sipario_oro", 8, _stat_at_least("rented_pct", 30))


static func _stat_set(stat_name: String, to: int) -> Dictionary:
	var f := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return to if stat == stat_name else value
	return {"modify_stat": f}


static func _stat_add(stat_name: String, amount: int) -> Dictionary:
	var f := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return value + amount if stat == stat_name else value
	return {"modify_stat": f}


static func _stat_at_least(stat_name: String, floor_value: int) -> Dictionary:
	var f := func(_run: RunState, _item: ItemCard, stat: String, value: int) -> int:
		return maxi(value, floor_value) if stat == stat_name else value
	return {"modify_stat": f}


static func _add(def_id: String, level: int, hooks: Dictionary) -> void:
	ContentDB.register(ContentDef.make(def_id, "stake", 0, 0, hooks, {"level": level}))
