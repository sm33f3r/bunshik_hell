extends "res://enemies/enemy_base.gd"
## 만두 (steamed dumpling, soft): waddles along tabletops, turns at edges and at walls, and hops
## short when the 떡 is close. Touching it costs 1 heart (def.contact_damage_half_hearts). All the
## numbers (speed, hop range, hop strength) are in its EnemyDef (data/enemies/mandu.tres); how
## big it is comes from whoever places it (the real 5 cm times the world scale): see configure().

const Layers_ := preload("res://systems/layers.gd")

## An edge is a drop of more than this below the feet, one body-width-fraction ahead.
const EDGE_DROP_M: float = 0.7
## The waddle: how far the body rocks (radians) and how fast.
const ROCK_ANGLE: float = 0.14
const ROCK_SPEED: float = 9.0

## Width (x) in game metres, and its height as a fraction of that. Set before adding to the tree
## (or call configure()).
@export var width_m: float = 0.87
@export var height_fraction: float = 0.7
## Which way it waddles first (+1 right, -1 left).
@export var start_dir: float = 1.0
## Times its walking speed (0 = it stands where it is, hopping when he is close). A map's spawn data
## sets this for a huddled cluster.
@export var speed_scale: float = 1.0

var _dir: float = 1.0
var _hop_rest: float = 0.0
var _rock_phase: float = 0.0
var _player: Node3D


## Sizes the body, the collision box and the reach of the enemy base (body_height).
func configure(p_width_m: float, p_height_fraction: float = 0.7) -> void:
	width_m = p_width_m
	height_fraction = p_height_fraction
	body_height = width_m * height_fraction
	var shape_node: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null:
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(width_m, body_height, width_m * 0.9)
		shape_node.shape = box
		shape_node.position = Vector3(0.0, body_height * 0.5, 0.0)
	var body_mesh: MeshInstance3D = get_node_or_null("Visual/Body") as MeshInstance3D
	if body_mesh != null:
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = width_m * 0.5
		sphere.height = body_height
		body_mesh.mesh = sphere
		body_mesh.position = Vector3(0.0, body_height * 0.5, 0.0)
		body_mesh.scale = Vector3.ONE
	var seam: MeshInstance3D = get_node_or_null("Visual/Seam") as MeshInstance3D
	if seam != null:
		var strip: BoxMesh = BoxMesh.new()
		strip.size = Vector3(width_m * 0.55, body_height * 0.1, width_m * 0.55)
		seam.mesh = strip
		seam.position = Vector3(0.0, body_height * 0.92, 0.0)


func _on_ready() -> void:
	configure(width_m, height_fraction)
	_dir = start_dir
	_hop_rest = 0.0


func _on_reset() -> void:
	_dir = start_dir
	_hop_rest = 0.0


func half_width() -> float:
	return width_m * 0.5


func _ai(delta: float) -> void:
	var speed: float = (def.walk_speed_mps if def != null else 0.0) * speed_factor() * speed_scale
	if is_on_wall() and signf(get_wall_normal().x) == -_dir:
		_dir = -_dir
	elif is_on_floor() and _edge_ahead():
		_dir = -_dir
	velocity.x = _dir * speed
	_hop_rest = maxf(_hop_rest - delta, 0.0)
	if def != null and def.hop_range_m > 0.0 and is_on_floor() and _hop_rest <= 0.0 and _player_close():
		velocity.y = def.hop_velocity_mps
		_hop_rest = def.hop_cooldown_s
	_rock_phase += delta * ROCK_SPEED
	if _visual != null and alive:
		_visual.rotation.z = sin(_rock_phase) * ROCK_ANGLE * (0.0 if absf(velocity.x) < 0.01 else 1.0)


## No floor a body-width ahead of the front foot (within EDGE_DROP_M below it).
func _edge_ahead() -> bool:
	if not is_inside_tree():
		return false
	var from: Vector3 = global_position + Vector3(_dir * (half_width() + 0.15), 0.1, 0.0)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from, from + Vector3(0.0, -(EDGE_DROP_M + 0.1), 0.0), Layers_.WORLD)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _player_close() -> bool:
	if not is_inside_tree():
		return false
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player == null:
		return false
	var offset: Vector3 = _player.global_position - global_position
	return absf(offset.x) <= def.hop_range_m and absf(offset.y) <= def.hop_range_m
