extends TestCase
## The RNG must match the JavaScript reference exactly (values from Node: FNV-1a + mulberry32).


func test_hash_matches_javascript() -> void:
	eq(ZRng.hash_string("zanni"), 1236207899, "zanni")
	eq(ZRng.hash_string("ZANNI-7Q4K/deck"), 2894283261, "ZANNI-7Q4K/deck")
	eq(ZRng.hash_string("àèì"), 620293146, "non-ASCII")


func test_sequence_matches_javascript() -> void:
	var expected := {
		"zanni": [168127591, 2020858816, 786517733, 3207412669, 957797698],
		"ZANNI-7Q4K/deck": [2233179479, 595284537, 207152579, 2300995682, 1705610872],
		"àèì": [1871480587, 1539438039, 2549670224, 1893397377, 296559715],
	}
	for text: String in expected:
		var r := ZRng.new(ZRng.hash_string(text))
		var outs := []
		for i in 5:
			outs.append(r.next_u32())
		eq(outs, expected[text], text)


func test_same_seed_same_shuffle() -> void:
	var a := range(52)
	var b := range(52)
	ZRng.new(42).shuffle(a)
	ZRng.new(42).shuffle(b)
	eq(a, b, "same seed")
	ok(a != range(52), "shuffle changed the order")


func test_streams_are_independent() -> void:
	var one := RunState.create("STREAMS")
	var two := RunState.create("STREAMS")
	two.rng("shop").next_u32()
	two.rng("shop").next_u32()
	eq(one.rng("deck").next_u32(), two.rng("deck").next_u32(), "deck stream unaffected by shop draws")


func test_weighted_pick_skips_zero_weights() -> void:
	var r := ZRng.new(7)
	var hits := [0, 0, 0]
	for i in 500:
		hits[r.pick_weighted([1, 0, 3])] += 1
	eq(hits[1], 0, "zero weight never picked")
	ok(hits[2] > hits[0], "heavier weight picked more")
	eq(r.pick_weighted([0, 0]), -1, "all zero")
