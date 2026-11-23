extends Node3D
## One metal chopstick or spoon in the air over the floor lane: a thin box that falls straight down at
## the def's speed. The zone (falling_zone.gd) moves it, checks what it hits, and turns it into a prop
## when it lands. The origin is at the bottom of the box. Gray box.

const FallingItemDefScript := preload("res://hazards/falling_item_def.gd")
const PrologueSetScript := preload("res://prologue/prologue_set.gd")

var idef: FallingItemDefScript
var width_m: float = 0.0
var length_m: float = 0.0
## The 떡 was hit by this item already (it hurts once), and the enemies it already crushed.
var hit_player: bool = false
var hit_enemy_ids: Array[int] = []


func setup(item_def: FallingItemDefScript, m_per_cm: float) -> void:
	idef = item_def
	width_m = idef.fall_width_cm * m_per_cm
	length_m = idef.fall_length_cm * m_per_cm
	name = "Falling_%s" % idef.id
	PrologueSetScript.add_mesh(self, "Mesh", PrologueSetScript.box_mesh(Vector3(width_m, length_m, width_m)), idef.color,
		Vector3(0.0, length_m * 0.5, 0.0))


func _pos() -> Vector3:
	return global_position if is_inside_tree() else position


func _set_y(y: float) -> void:
	if is_inside_tree():
		global_position.y = y
	else:
		position.y = y


func x() -> float:
	return _pos().x


func bottom_y() -> float:
	return _pos().y


## The middle of the box (x, y).
func center() -> Vector2:
	return Vector2(_pos().x, _pos().y + length_m * 0.5)


## Falls for `delta`. Returns true when it reached `ground_y` (it is put there).
func fall(delta: float, ground_y: float) -> bool:
	var y: float = _pos().y - idef.fall_speed_mps * delta
	if y <= ground_y:
		_set_y(ground_y)
		return true
	_set_y(y)
	return false


## A body (middle at `at`, half sizes) touches the box.
func touches(at: Vector2, half: Vector2) -> bool:
	var c: Vector2 = center()
	return absf(at.x - c.x) <= width_m * 0.5 + half.x and absf(at.y - c.y) <= length_m * 0.5 + half.y
