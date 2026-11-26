extends Node3D
## The rubber curtain strips of a doorway (DoorwayDef): thin see-through boxes hung from the top of the
## opening by their top edge, a little in front of him. No collider at all. When he is under them (or jumps through) the strips near him
## swing away from the way he moves and settle again like a damped spring. Visual only.

const PrologueSetScript := preload("res://prologue/prologue_set.gd")
const DoorwayDefScript := preload("res://maps/layout/doorway_def.gd")

var doorway: DoorwayDefScript
## Game metres per real centimetre.
var m_per_cm: float = 0.1745
## The player; found in the group "player" when not set (tests inject one).
var player: Node3D

var _pivots: Array[Node3D] = []
var _angle: Array[float] = []
var _speed: Array[float] = []


## Hangs the strips from y = top (in the curtain's own space) down to y = bottom.
func build(p_def: DoorwayDefScript, p_m_per_cm: float) -> void:
	doorway = p_def
	m_per_cm = p_m_per_cm
	var width: float = doorway.width_cm * m_per_cm
	var top: float = doorway.height_cm * m_per_cm
	var length: float = maxf(top - doorway.bottom_edge_cm * m_per_cm, 0.05)
	var slot: float = width / float(maxi(doorway.strips, 1))
	for i: int in maxi(doorway.strips, 1):
		var pivot: Node3D = Node3D.new()
		pivot.name = "Strip%d" % i
		var z: float = doorway.strip_z_near_m if i % 2 == 0 else doorway.strip_z_far_m
		pivot.position = Vector3(-width * 0.5 + slot * (float(i) + 0.5), top, z)
		add_child(pivot)
		var mesh: MeshInstance3D = PrologueSetScript.add_mesh(pivot, "Mesh",
			PrologueSetScript.box_mesh(Vector3(slot * doorway.strip_fill, length, doorway.strip_thickness_m)),
			doorway.strip_color, Vector3(0.0, -length * 0.5, 0.0))
		(mesh.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_pivots.append(pivot)
		_angle.append(0.0)
		_speed.append(0.0)


func strip_count() -> int:
	return _pivots.size()


## The y (in the world) the strips end at.
func bottom_edge_y() -> float:
	return global_position.y + doorway.bottom_edge_cm * m_per_cm if doorway != null else 0.0


## The furthest any strip is swung out right now (radians).
func sway_amount() -> float:
	var most: float = 0.0
	for a: float in _angle:
		most = maxf(most, absf(a))
	return most


func _physics_process(delta: float) -> void:
	if doorway == null:
		return
	var who: Node3D = player
	if who == null and is_inside_tree():
		who = get_tree().get_first_node_in_group("player") as Node3D
	var push_x: float = 0.0
	var at_x: float = 0.0
	var near: bool = false
	if who != null and is_instance_valid(who):
		var local: Vector3 = who.global_position - global_position
		var top: float = doorway.height_cm * m_per_cm
		near = absf(local.x) <= doorway.width_cm * m_per_cm * 0.5 + doorway.sway_reach_m and local.y > -1.0 and local.y < top + 1.0
		if near:
			push_x = float(who.get("velocity").x) if who.get("velocity") != null else 0.0
			at_x = local.x
	for i: int in _pivots.size():
		var push: float = 0.0
		if near:
			var reach: float = maxf(doorway.sway_reach_m, 0.01)
			var influence: float = clampf(1.0 - absf(_pivots[i].position.x - at_x) / (reach * 2.0), 0.0, 1.0)
			push = push_x * influence * doorway.sway_gain
		# A strip hanging from its top swings out the way he goes: a positive angle leans the bottom toward +x.
		var accel: float = -doorway.sway_stiffness * _angle[i] - doorway.sway_damping * _speed[i] + push
		_speed[i] += accel * delta
		_angle[i] = clampf(_angle[i] + _speed[i] * delta, -doorway.sway_max_rad, doorway.sway_max_rad)
		_pivots[i].rotation.z = _angle[i]
