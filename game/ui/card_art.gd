extends Node
## Autoload "CardArt": draws each card face once, into a texture, and hands the same texture
## to every card showing that face. A card on screen is then one textured quad (with the tilt
## and foil shader) instead of hundreds of shapes redrawn every frame, which is what made the
## game lag. Faces are drawn at the screen's real resolution, capped by graphics quality, in
## off-screen viewports that render once and are kept while any card uses them.

## The most screen pixels per card unit, by graphics quality (Low, Medium, High).
const MAX_SCALE := [1.5, 2.5, 4.0]
## How many faces to keep before letting go of ones no card is using.
const KEEP := 220

var _done := {}
var _waiting := {}
var _users := {}
var _order: Array[String] = []


## The face's texture if it's drawn; otherwise starts drawing it, and the card gets it by
## set_art() a frame later.
func request(view: CardView) -> Texture2D:
	var key := view.art_key()
	if _done.has(key):
		_order.erase(key)
		_order.append(key)
		_users[key].append(weakref(view))
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


func _scale() -> float:
	var screen := get_tree().root.get_final_transform().get_scale().x
	return clampf(screen, 1.0, MAX_SCALE[Settings.quality])


func _bake(view: CardView, key: String) -> void:
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


## Lets go of the oldest faces no card on screen is using.
func _trim() -> void:
	var i := 0
	while _order.size() > KEEP and i < _order.size():
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
		viewport.queue_free()
		_done.erase(key)
		_users.erase(key)
		_order.remove_at(i)
