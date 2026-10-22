extends Node
## Autoload "CardArt": draws each card face once, into a texture, and hands the same texture
## to every card showing that face. A card on screen is then one textured quad (with the tilt
## and foil shader) instead of hundreds of shapes redrawn every frame, which is what made the
## game lag. Faces are drawn at the screen's real resolution, capped by graphics quality, in
## off-screen viewports that render once and are kept while any card uses them.

## The most screen pixels per card unit, by graphics quality (Low, Medium, High).
const MAX_SCALE := [1.5, 2.5, 4.0]
## How much graphics memory the kept faces may use, by graphics quality, before the oldest
## ones no card is using are let go (faces on screen are always kept). Browsing the whole
## collection used to keep ~30 MB of faces at Medium and twice that at High: too much for
## phones, where the screen's own buffers already take ~50 MB.
const BUDGET_MB := [8, 16, 32]
## And at most this many faces whatever their size.
const KEEP := 220

## Faces drawn since the game started (tools/perf.mjs reports it).
var baked := 0
## While true (a hand is scoring) no faces are drawn ahead, so the scoring stays smooth.
var hold := false

var _done := {}
var _waiting := {}
var _users := {}
var _order: Array[String] = []
## Faces to draw ahead of need, one every other frame: cards still in the draw pile, so a
## card dealt mid-show is already drawn (drawing several at once caused a long frame).
var _ahead: Array = []
var _ahead_keys := {}
var _frame := 0


## Queues the faces of these playing cards at this size, for drawing ahead.
func prebake(cards: Array, view_size: Vector2) -> void:
	for card: PlayingCard in cards:
		var key := CardView.playing_key(card, card.edition, view_size)
		if not (_done.has(key) or _waiting.has(key) or _ahead_keys.has(key)):
			_ahead_keys[key] = true
			_ahead.append([key, card, view_size])


func _process(_delta: float) -> void:
	_frame += 1
	if hold or _ahead.is_empty() or _frame % 2 == 0:
		return
	var next: Array = _ahead.pop_front()
	var key: String = next[0]
	_ahead_keys.erase(key)
	if _done.has(key) or _waiting.has(key):
		return
	var view := CardView.new(next[2])
	view.card = next[1]
	view.edition = (next[1] as PlayingCard).edition
	_waiting[key] = []
	_bake(view, key)
	view.free()


## The face's texture if it's drawn; otherwise starts drawing it, and the card gets it by
## set_art() a frame later.
func request(view: CardView) -> Texture2D:
	var key := view.art_key()
	if _done.has(key):
		_order.erase(key)
		_order.append(key)
		var users: Array = _users[key].filter(func(ref: WeakRef) -> bool: return ref.get_ref() != null)
		users.append(weakref(view))
		_users[key] = users
		return _done[key]
	if not _waiting.has(key):
		_waiting[key] = []
		_bake(view, key)
	_waiting[key].append(weakref(view))
	return null


## Forgets every drawn face (after the card back or graphics quality changes).
func clear() -> void:
	for key in _done:
		var texture: ViewportTexture = _done[key]
		var viewport := texture.get_meta("viewport") as SubViewport
		if viewport != null:
			viewport.queue_free()
	_done.clear()
	_users.clear()
	_order.clear()
	_ahead.clear()
	_ahead_keys.clear()


func _scale() -> float:
	var screen := get_tree().root.get_final_transform().get_scale().x
	return clampf(screen, 1.0, MAX_SCALE[Settings.quality])


func _bake(view: CardView, key: String) -> void:
	baked += 1
	var scale := _scale()
	var viewport := SubViewport.new()
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.size = Vector2i(ceili(view.size.x * scale), ceili(view.size.y * scale))
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var face := view.baked_copy()
	face.pivot_offset = Vector2.ZERO
	face.scale = Vector2(scale, scale)
	viewport.add_child(face)
	add_child(viewport)
	await RenderingServer.frame_post_draw
	# The face is drawn (the viewport keeps the picture; UPDATE_ONCE won't draw again). Drop
	# the copy, so a painting it used isn't held in graphics memory.
	face.queue_free()
	var texture := viewport.get_texture()
	texture.set_meta("viewport", viewport)
	_done[key] = texture
	_users[key] = []
	_order.append(key)
	for ref in _waiting[key]:
		var waiting: CardView = ref.get_ref()
		if waiting != null:
			_users[key].append(ref)
			waiting.set_art(texture)
	_waiting.erase(key)
	_trim()


## Graphics memory the kept faces use, in bytes.
func kept_bytes() -> int:
	var total := 0
	for key in _done:
		var size := ((_done[key] as ViewportTexture).get_meta("viewport") as SubViewport).size
		total += size.x * size.y * 4
	return total


## Lets go of the oldest faces no card on screen is using, while the kept ones are over the
## memory budget or the count.
func _trim() -> void:
	var budget: int = BUDGET_MB[Settings.quality] * 1048576
	var bytes := kept_bytes()
	var i := 0
	while (_order.size() > KEEP or bytes > budget) and i < _order.size():
		var key := _order[i]
		var in_use := false
		for ref in _users[key]:
			if ref.get_ref() != null:
				in_use = true
				break
		if in_use:
			i += 1
			continue
		var viewport := (_done[key] as ViewportTexture).get_meta("viewport") as SubViewport
		bytes -= viewport.size.x * viewport.size.y * 4
		viewport.queue_free()
		_done.erase(key)
		_users.erase(key)
		_order.remove_at(i)
