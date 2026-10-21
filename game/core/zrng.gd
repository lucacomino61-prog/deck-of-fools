class_name ZRng
extends RefCounted
## Seeded random numbers that come out identical on every device and in JavaScript:
## mulberry32 with the 32-bit maths done by hand (GDScript ints are 64-bit), seeded through
## FNV-1a. The server can replay a run from its seed and get the same draws.

const MASK := 0xFFFFFFFF

var state: int


func _init(seed_value: int = 0) -> void:
	state = seed_value & MASK


## FNV-1a over the UTF-8 bytes of `text`.
static func hash_string(text: String) -> int:
	var h := 0x811C9DC5
	for b in text.to_utf8_buffer():
		h = ((h ^ b) * 0x01000193) & MASK
	return h


## Low 32 bits of a * b, like JavaScript's Math.imul (kept unsigned).
static func imul(a: int, b: int) -> int:
	a &= MASK
	b &= MASK
	var a_lo := a & 0xFFFF
	var a_hi := a >> 16
	var b_lo := b & 0xFFFF
	var b_hi := b >> 16
	return (a_lo * b_lo + (((a_hi * b_lo + a_lo * b_hi) << 16) & MASK)) & MASK


func next_u32() -> int:
	state = (state + 0x6D2B79F5) & MASK
	var t := state
	t = imul(t ^ (t >> 15), t | 1)
	t = ((t + imul(t ^ (t >> 7), t | 61)) & MASK) ^ t
	return (t ^ (t >> 14)) & MASK


## Uniform float in [0, 1).
func next_float() -> float:
	return next_u32() / 4294967296.0


## Uniform int in [0, n).
func below(n: int) -> int:
	return int(next_float() * n)


func chance(probability: float) -> bool:
	return next_float() < probability


## Fisher-Yates, in place.
func shuffle(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := below(i + 1)
		var tmp: Variant = items[i]
		items[i] = items[j]
		items[j] = tmp


## Index picked with probability proportional to weights[i]; -1 when every weight is 0.
func pick_weighted(weights: Array) -> int:
	var total := 0.0
	for w in weights:
		total += float(w)
	if total <= 0.0:
		return -1
	var roll := next_float() * total
	for i in weights.size():
		roll -= float(weights[i])
		if roll < 0.0:
			return i
	return weights.size() - 1
