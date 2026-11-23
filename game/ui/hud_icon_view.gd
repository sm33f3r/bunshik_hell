extends Control
## Draws one HudIcon: its texture if it has one, else its vector shape. `tint` replaces the icon's
## colour (the current sauce's colour, say). Nothing is drawn for a null icon (an empty slot).

const HudIconScript := preload("res://ui/hud_icon.gd")

var icon: HudIconScript:
	set(value):
		icon = value
		queue_redraw()
var tint: Color = Color(0, 0, 0, 0):
	set(value):
		tint = value
		queue_redraw()


func _init(p_size: float = 44.0) -> void:
	custom_minimum_size = Vector2(p_size, p_size)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if icon == null:
		return
	var box: Vector2 = size
	if icon.texture != null:
		draw_texture_rect(icon.texture, Rect2(Vector2.ZERO, box), false)
		return
	var fill: Color = tint if tint.a > 0.0 else icon.color
	var points: PackedVector2Array = shape_points(icon.shape, box)
	if points.size() < 3:
		return
	draw_colored_polygon(points, fill)
	var closed: PackedVector2Array = points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, icon.outline_color, 2.0, true)
	if icon.shape == "crystal":
		draw_line(box * Vector2(0.5, 0.05), box * Vector2(0.5, 0.95), icon.outline_color, 1.5)
	elif icon.shape == "disk":
		draw_rect(Rect2(box * Vector2(0.24, 0.1), box * Vector2(0.44, 0.26)), icon.outline_color)
		draw_rect(Rect2(box * Vector2(0.22, 0.56), box * Vector2(0.56, 0.3)), icon.outline_color, false, 2.0)
	elif icon.shape == "jar":
		draw_rect(Rect2(box * Vector2(0.28, 0.06), box * Vector2(0.44, 0.14)), icon.outline_color)


## The shape's outline in a box of this size.
static func shape_points(shape: String, box: Vector2) -> PackedVector2Array:
	var unit: PackedVector2Array = PackedVector2Array()
	match shape:
		"heart":
			for i: int in 28:
				var t: float = TAU * float(i) / 28.0
				var x: float = 16.0 * pow(sin(t), 3.0)
				var y: float = 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
				unit.append(Vector2(0.5 + x / 34.0, 0.46 - y / 34.0))
		"drop":
			unit.append(Vector2(0.5, 0.04))
			# A circle of radius 0.34 centred low, walked from the right side round the bottom to the left.
			for i: int in 17:
				var angle: float = -PI * 0.3 + (PI * 1.6) * float(i) / 16.0
				unit.append(Vector2(0.5 + 0.34 * cos(angle), 0.64 + 0.34 * sin(angle)))
		"crystal":
			unit = PackedVector2Array([Vector2(0.5, 0.02), Vector2(0.86, 0.3), Vector2(0.72, 0.98),
				Vector2(0.28, 0.98), Vector2(0.14, 0.3)])
		"coat":
			unit = PackedVector2Array([Vector2(0.12, 0.12), Vector2(0.5, 0.02), Vector2(0.88, 0.12),
				Vector2(0.84, 0.58), Vector2(0.5, 0.98), Vector2(0.16, 0.58)])
		"disk": # a floppy disk: a square with one corner cut off
			unit = PackedVector2Array([Vector2(0.08, 0.08), Vector2(0.72, 0.08), Vector2(0.92, 0.28),
				Vector2(0.92, 0.92), Vector2(0.08, 0.92)])
		"jar":
			unit = PackedVector2Array([Vector2(0.22, 0.2), Vector2(0.78, 0.2), Vector2(0.9, 0.34),
				Vector2(0.9, 0.9), Vector2(0.1, 0.9), Vector2(0.1, 0.34)])
		"mound":
			unit = PackedVector2Array([Vector2(0.04, 0.9), Vector2(0.2, 0.55), Vector2(0.5, 0.2),
				Vector2(0.8, 0.55), Vector2(0.96, 0.9)])
		_: # swatch: a rounded-ish square
			unit = PackedVector2Array([Vector2(0.14, 0.06), Vector2(0.86, 0.06), Vector2(0.94, 0.14),
				Vector2(0.94, 0.86), Vector2(0.86, 0.94), Vector2(0.14, 0.94), Vector2(0.06, 0.86),
				Vector2(0.06, 0.14)])
	var out: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in unit:
		out.append(p * box)
	return out
