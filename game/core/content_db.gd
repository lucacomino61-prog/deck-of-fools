class_name ContentDB
extends RefCounted
## Registry of every content definition, by id. Content packs register here at start-up;
## tests reset it and register their own. Pools keep registration order, which is part of
## what a seed reproduces, so packs must always register in the same order.

static var _defs: Dictionary = {}


static func reset() -> void:
	_defs.clear()


static func register(def: ContentDef) -> void:
	_defs[def.id] = def


static func get_def(def_id: String) -> ContentDef:
	if def_id == "":
		return null
	return _defs.get(def_id)


## Every definition of one kind, in registration order, optionally filtered.
static func pool(kind: String, filter := Callable()) -> Array[ContentDef]:
	var out: Array[ContentDef] = []
	for d: ContentDef in _defs.values():
		if d.kind == kind and (not filter.is_valid() or filter.call(d)):
			out.append(d)
	return out
