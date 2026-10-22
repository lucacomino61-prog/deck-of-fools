class_name WagonArt
extends RefCounted
## The troupe's wagon, il carrozzone (batch 13), drawn in code on any canvas: a painted box
## under an arched canvas roof, two spoked wheels and the shafts, in the paint worn in the
## Wagon, with the trims worn (lanterns, flags, an awning, bells, the sail). `at` is where the
## wheels touch the ground, in the middle; one unit of `s` is about a pixel on the map token.


static func draw(c: CanvasItem, at: Vector2, s: float, paint: Color, trims: Array, roll := 0.0) -> void:
	var body := Rect2(at + Vector2(-14, -17) * s, Vector2(28, 11) * s)
	var wheel_r := 4.2 * s
	var wheel_y := at.y - wheel_r
	# Shafts reaching forward, the roof, then the box.
	c.draw_line(at + Vector2(12, -8) * s, at + Vector2(22, -6) * s, Color("5a3a1e"), 1.4 * s, true)
	c.draw_line(at + Vector2(12, -10) * s, at + Vector2(22, -8) * s, Color("5a3a1e"), 1.0 * s, true)
	if trims.has("trim_sail"):
		c.draw_line(at + Vector2(-2, -24) * s, at + Vector2(-2, -38) * s, Color("5a3a1e"), 1.2 * s, true)
		c.draw_colored_polygon(PackedVector2Array([at + Vector2(-1, -37) * s, at + Vector2(10, -27) * s, at + Vector2(-1, -26) * s]), Color("f0ebdc"))
	var roof := PackedVector2Array()
	for i in 13:
		var a := PI + i * PI / 12.0
		roof.append(Vector2(body.get_center().x + cos(a) * body.size.x * 0.52, body.position.y + sin(a) * 9.0 * s))
	c.draw_colored_polygon(roof, Color("efe4c8"))
	for i in range(2, 12, 3):
		c.draw_line(roof[i], Vector2(roof[i].x, body.position.y), Color("cdbf9e"), 0.8 * s, true)
	c.draw_polyline(roof, Color("8a6a3a"), 0.9 * s, true)
	if trims.has("trim_flags"):
		for i in [3, 9]:
			var top: Vector2 = roof[i] + Vector2(0, -5) * s
			c.draw_line(roof[i], top, Color("5a3a1e"), 0.8 * s, true)
			c.draw_colored_polygon(PackedVector2Array([top, top + Vector2(5, 1.5) * s, top + Vector2(0, 3) * s]), Color("d4404e") if i == 3 else Color("f0c040"))
	c.draw_rect(body, paint)
	c.draw_rect(Rect2(body.position, Vector2(body.size.x, 1.6 * s)), paint.lightened(0.25))
	c.draw_rect(Rect2(body.position + Vector2(0, body.size.y - 1.6 * s), Vector2(body.size.x, 1.6 * s)), paint.darkened(0.3))
	c.draw_rect(body, UiTheme.GOLD.darkened(0.2), false, 0.9 * s)
	# A gold star painted on the side, and a little window.
	_star(c, body.get_center() + Vector2(-5, 0.5) * s, 2.8 * s, UiTheme.GOLD)
	c.draw_rect(Rect2(body.get_center() + Vector2(3, -3) * s, Vector2(6, 5) * s), Color("2a1a10"))
	c.draw_rect(Rect2(body.get_center() + Vector2(3, -3) * s, Vector2(6, 5) * s), UiTheme.GOLD.darkened(0.2), false, 0.6 * s)
	if trims.has("trim_awning"):
		for i in 6:
			var x := body.position.x + 2 * s + i * 4 * s
			c.draw_colored_polygon(PackedVector2Array([Vector2(x, body.position.y), Vector2(x + 4 * s, body.position.y),
				Vector2(x + 4 * s, body.position.y + 3.5 * s), Vector2(x, body.position.y + 3.5 * s)]),
				Color("d4404e") if i % 2 == 0 else Color("f3ead8"))
	if trims.has("trim_bells"):
		for i in 5:
			c.draw_circle(Vector2(body.position.x + (3 + i * 5.5) * s, body.end.y + 1.2 * s), 1.1 * s, UiTheme.GOLD)
	if trims.has("trim_lanterns"):
		for x in [body.position.x - 1.5 * s, body.end.x + 1.5 * s]:
			c.draw_line(Vector2(x, body.position.y - 2 * s), Vector2(x, body.position.y + 1 * s), Color("3a2a1a"), 0.6 * s, true)
			c.draw_circle(Vector2(x, body.position.y + 2.6 * s), 2.6 * s, Color(1.0, 0.8, 0.35, 0.25))
			c.draw_circle(Vector2(x, body.position.y + 2.6 * s), 1.4 * s, Color("ffd36a"))
	for x in [body.position.x + 6 * s, body.end.x - 6 * s]:
		_wheel(c, Vector2(x, wheel_y), wheel_r, roll)


static func _wheel(c: CanvasItem, centre: Vector2, r: float, roll: float) -> void:
	c.draw_circle(centre, r, Color("3a2412"))
	c.draw_circle(centre, r * 0.8, Color("8a5a2a"))
	for i in 6:
		var a := roll + i * PI / 3.0
		c.draw_line(centre, centre + Vector2(cos(a), sin(a)) * r * 0.8, Color("3a2412"), maxf(0.6, r * 0.14), true)
	c.draw_circle(centre, r * 0.22, UiTheme.GOLD.darkened(0.2))


static func _star(c: CanvasItem, centre: Vector2, r: float, colour: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(centre + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	c.draw_colored_polygon(pts, colour)


## The paint the player's wagon wears, and its trims.
static func worn_paint() -> Color:
	return Game.profile.worn_colour("paint", WagonCards.WOOD)


static func worn_trims() -> Array:
	return Game.profile.worn.get("trims", [])
