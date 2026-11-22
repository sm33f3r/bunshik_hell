extends "res://enemies/enemy_base.gd"
## 단무지 wheel (pickled radish, crunchy): rolls on its edge along tables, turns at edges and bounces off
## walls. Touching it from the side costs 1 heart. Landing or stomping on it is a springboard
## (bounce_boost); a roll into it knocks it over: it falls flat, stops hurting and becomes a platform
## (see _handle_knock_over); a slam or a heavy object damages it; sauce is absorbed. Roster §5.
## Every number (size, speed, health, bounce, the platform time) is in data/enemies/danmuji.tres and
## data/movement_tuning.tres. Deferred: speeding up downhill (no slopes exist yet).

const Layers_ := preload("res://systems/layers.gd")
const WorldScaleScript := preload("res://systems/world_scale.gd")

## An edge is a drop of more than this below the feet, a little ahead of the wheel's front.
const EDGE_DROP_M: float = 0.7
const EDGE_LOOKAHEAD_M: float = 0.15
## The fall flat takes this long (the picture only; it is a platform at once).
const FALL_FLAT_S: float = 0.3
## How far the settling wobble rocks it while it is still "loose" (radians).
const WOBBLE_ANGLE: float = 0.05
const BRINE_COLOR: Color = Color(0.95, 0.82, 0.12)
const RADISH_COLOR: Color = Color(0.98, 0.88, 0.2)
const MARK_COLOR: Color = Color(0.85, 0.65, 0.1)

## It lay down and became a platform.
signal knocked_over

## Which way it rolls first (+1 right, -1 left).
@export var start_dir: float = 1.0
## Times its rolling speed (a spawn's params may change it).
@export var speed_scale: float = 1.0
## Game metres per real centimetre; -1 = read the world scale data.
@export var m_per_cm: float = -1.0

## True once it is knocked over: a platform now, not an enemy.
var flat: bool = false
## True once the platform time is over: it stays exactly as it is until the section resets.
var is_static: bool = false
var flat_time: float = 0.0
var diameter_m: float = 0.0
var thickness_m: float = 0.0
var flat_height_m: float = 0.0

var _dir: float = 1.0
var _slide_dir: float = 1.0
var _slide_left: float = 0.0
var _spin: Node3D
var _shape_node: CollisionShape3D


## Sizes the body from the EnemyDef (real centimetres times the world scale).
func configure() -> void:
	if def == null:
		return
	var scale_m: float = m_per_cm if m_per_cm > 0.0 else _world_m_per_cm()
	diameter_m = def.size_cm * scale_m
	thickness_m = def.thickness_cm * scale_m
	flat_height_m = def.flat_height_cm * scale_m
	body_height = diameter_m
	_spin = get_node_or_null("Visual/Spin") as Node3D
	_shape_node = get_node_or_null("CollisionShape3D") as CollisionShape3D
	_apply_round_shape()
	if _spin != null:
		_spin.position = Vector3(0.0, diameter_m * 0.5, 0.0)
		var disc: MeshInstance3D = _spin.get_node_or_null("Disc") as MeshInstance3D
		if disc != null:
			var cylinder: CylinderMesh = CylinderMesh.new()
			cylinder.top_radius = diameter_m * 0.5
			cylinder.bottom_radius = diameter_m * 0.5
			cylinder.height = thickness_m
			cylinder.radial_segments = 32
			disc.mesh = cylinder
		var mark: MeshInstance3D = _spin.get_node_or_null("Mark") as MeshInstance3D
		if mark != null:
			var stripe: BoxMesh = BoxMesh.new()
			stripe.size = Vector3(diameter_m * 0.16, diameter_m * 0.34, thickness_m * 1.1)
			mark.mesh = stripe
			mark.position = Vector3(0.0, diameter_m * 0.36, 0.0)


func _world_m_per_cm() -> float:
	var world: Resource = WorldScaleScript.load_default()
	return (world as WorldScaleScript).game_m_per_real_cm() if world != null else 0.1745


func _on_ready() -> void:
	configure()
	_dir = start_dir


func _on_reset() -> void:
	flat = false
	is_static = false
	flat_time = 0.0
	_slide_left = 0.0
	_dir = start_dir
	remove_from_group("flat_wheels")
	if _spin != null:
		_spin.rotation = Vector3.ZERO
		_spin.position = Vector3(0.0, diameter_m * 0.5, 0.0)
	body_height = diameter_m
	collision_layer = Layers_.ENEMY
	_apply_round_shape()


func half_width() -> float:
	return diameter_m * 0.5


func _apply_round_shape() -> void:
	if _shape_node == null:
		return
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(diameter_m, diameter_m, thickness_m)
	_shape_node.shape = box
	_shape_node.position = Vector3(0.0, diameter_m * 0.5, 0.0)


## Lying flat: as wide as the wheel in x and z (he must be able to stand on it), flat_height_m tall.
func _apply_flat_shape() -> void:
	if _shape_node == null:
		return
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(diameter_m, flat_height_m, diameter_m)
	_shape_node.shape = box
	_shape_node.position = Vector3(0.0, flat_height_m * 0.5, 0.0)


# --- Rolling --------------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if flat:
		_step_flat(delta)
		return
	super(delta)


func _ai(delta: float) -> void:
	var speed: float = (def.walk_speed_mps if def != null else 0.0) * speed_factor() * speed_scale
	if is_on_wall() and signf(get_wall_normal().x) == -_dir:
		_dir = -_dir
	elif is_on_floor() and _edge_ahead(_dir):
		_dir = -_dir
	velocity.x = _dir * speed
	if _spin != null and alive and diameter_m > 0.0:
		# Rolling to the right is clockwise seen from the camera.
		_spin.rotation.z -= _dir * speed * delta / (diameter_m * 0.5)


## No floor just ahead of the front (within EDGE_DROP_M below the feet).
func _edge_ahead(direction: float) -> bool:
	if not is_inside_tree():
		return false
	var from: Vector3 = global_position + Vector3(direction * (half_width() + EDGE_LOOKAHEAD_M), 0.1, 0.0)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from, from + Vector3(0.0, -(EDGE_DROP_M + 0.1), 0.0), Layers_.WORLD)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


# --- Knocked over: a platform ---------------------------------------------------------------------

## A roll lays it down. It slides on the way it was hit (stopping at an edge or at a wall), wobbles
## for def.platform_duration_s, then stays still as a static platform. It no longer hurts and no
## longer counts as an enemy (alive = false), and it is solid for him now (the world layer).
func _handle_knock_over(hit_dir: float) -> bool:
	if flat:
		return true
	flat = true
	alive = false
	is_static = false
	flat_time = 0.0
	pin_left = 0.0
	swelling = false
	swell_left = 0.0
	_slide_dir = signf(hit_dir) if hit_dir != 0.0 else _dir
	_slide_left = def.knock_slide_m
	velocity = Vector3.ZERO
	collision_layer = Layers_.WORLD
	body_height = flat_height_m
	_apply_flat_shape()
	add_to_group("flat_wheels")
	_fall_flat_picture()
	knocked_over.emit()
	return true


func _fall_flat_picture() -> void:
	if _spin == null or not is_inside_tree():
		if _spin != null:
			_spin.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
			_spin.position = Vector3(0.0, flat_height_m * 0.5, 0.0)
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_spin, "rotation", Vector3(-PI * 0.5, 0.0, 0.0), FALL_FLAT_S) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(_spin, "position", Vector3(0.0, flat_height_m * 0.5, 0.0), FALL_FLAT_S)


func _step_flat(delta: float) -> void:
	flat_time += delta
	if is_static:
		return
	var before_x: float = global_position.x if is_inside_tree() else position.x
	velocity.x = _slide_dir * def.knock_slide_speed_mps if _slide_left > 0.0 else 0.0
	velocity.y = maxf(velocity.y - gravity * delta, -max_fall_speed)
	velocity.z = 0.0
	move_and_slide()
	if not is_equal_approx(position.z, _lock_z):
		position.z = _lock_z
	if _slide_left > 0.0:
		var after_x: float = global_position.x if is_inside_tree() else position.x
		_slide_left -= absf(after_x - before_x)
		var at_wall: bool = is_on_wall() and signf(get_wall_normal().x) == -_slide_dir
		if at_wall or _edge_ahead(_slide_dir) or _slide_left <= 0.0:
			_slide_left = 0.0
	if _visual != null and def.platform_duration_s > 0.0:
		var loose: float = clampf(1.0 - flat_time / def.platform_duration_s, 0.0, 1.0)
		_visual.rotation.z = sin(flat_time * 36.0) * WOBBLE_ANGLE * loose
	if flat_time >= def.platform_duration_s and _slide_left <= 0.0 and is_on_floor():
		_become_static()


## The platform time is over: it stays as it is until the section resets.
func _become_static() -> void:
	is_static = true
	velocity = Vector3.ZERO
	if _visual != null:
		_visual.rotation = Vector3.ZERO
	set_physics_process(false)


# --- Death: it snaps in half and leaves a brine puddle ----------------------------------------------

func _play_death(_tip_over: bool, hit_dir: float) -> bool:
	if not is_inside_tree() or get_parent() == null:
		return false
	var parent: Node = get_parent()
	var at: Vector3 = global_position
	for side: float in [-1.0, 1.0]:
		var half: MeshInstance3D = MeshInstance3D.new()
		var slab: BoxMesh = BoxMesh.new()
		slab.size = Vector3(diameter_m * 0.5, diameter_m * 0.92, thickness_m)
		half.mesh = slab
		half.material_override = _plain(RADISH_COLOR)
		half.add_to_group("section_decor")
		parent.add_child(half)
		half.global_position = at + Vector3(side * diameter_m * 0.25, diameter_m * 0.5, 0.0)
		var fall: Tween = half.create_tween().set_parallel(true)
		fall.tween_property(half, "rotation:z", side * 0.9 + signf(hit_dir) * 0.1, 0.35)
		fall.tween_property(half, "position:x", half.position.x + side * diameter_m * 0.3, 0.35)
		fall.tween_property(half, "position:y", at.y + thickness_m * 0.5, 0.35) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var puddle: MeshInstance3D = MeshInstance3D.new()
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = diameter_m * 0.55
	disc.bottom_radius = diameter_m * 0.55
	disc.height = 0.03
	puddle.mesh = disc
	puddle.material_override = _plain(BRINE_COLOR)
	puddle.add_to_group("section_decor")
	parent.add_child(puddle)
	puddle.global_position = at + Vector3(0.0, 0.03, 0.0)
	_finish_death()
	return true


static func _plain(color: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	return mat
