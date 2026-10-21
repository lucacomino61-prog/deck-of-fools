extends TestCase
## Every Jester has its own hand-made portrait (ui/jester_designs.gd), built only from parts
## JesterArt knows how to draw, and no two Jesters look alike.


func _jester_ids() -> Array:
	ContentPacks.register_all()
	return ContentDB.pool("zanni").map(func(d: ContentDef) -> String: return d.id)


func test_every_jester_has_a_design() -> void:
	var ids := _jester_ids()
	ok(ids.size() >= 150, "the full set of Jesters is registered (%d)" % ids.size())
	for id in ids:
		ok(JesterDesigns.DESIGNS.has(id), "%s has a design" % id)
	for id in JesterDesigns.DESIGNS:
		ok(ids.has(id), "design %s belongs to a real Jester" % id)


func test_designs_use_known_parts() -> void:
	var lists := [
		JesterDesigns.BACKDROPS.keys(), JesterDesigns.PATTERNS, JesterDesigns.HATS, JesterDesigns.MASKS,
		JesterDesigns.FACES, JesterDesigns.COSTUMES, JesterDesigns.COLOURS.keys(), JesterDesigns.COLOURS.keys(),
		JesterDesigns.PROPS, JesterDesigns.EFFECTS,
	]
	for id in JesterDesigns.DESIGNS:
		var d: Array = JesterDesigns.DESIGNS[id]
		eq(d.size(), 11, "%s has all eleven fields" % id)
		for i in lists.size():
			ok(lists[i].has(d[i]), "%s field %d (%s) is a known part" % [id, i, d[i]])
		for extra in str(d[10]).split(" ", false):
			ok(JesterDesigns.EXTRAS.has(extra), "%s extra %s is known" % [id, extra])


func test_no_two_jesters_look_alike() -> void:
	var seen := {}
	for id in JesterDesigns.DESIGNS:
		var key := str(JesterDesigns.DESIGNS[id])
		ok(not seen.has(key), "%s looks different from %s" % [id, seen.get(key, "")])
		seen[key] = id
