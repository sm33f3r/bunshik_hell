extends Area3D
## Gray-box projectile: a sphere that flies in a straight line inside the game plane,
## ends at max_range, and reports what it hits. Subclasses decide what a hit means.
## Collision shape and mesh are built in code so there is no scene to maintain.

const Layers := preload("res://systems/layers.gd")

## Direction inside the X/Y plane (normalised by launch()).
var direction: Vector2 = Vector2.RIGHT
var speed: float = 10.0
var max_range: float = 10.0
var radius: float = 0.15
var color: Color = Color(0.85, 0.1, 0.08, 1)
var travelled: float = 0.0

var _lock_z: float = 0.0
var _lock_pending: bool = true
var _done: bool = false


## Call before add_child(); position is set once the node is in the tree.
func launch(dir: Vector2, speed_mps: float, range_m: float) -> void:
	direction = dir.normalized()
	speed = speed_mps
	max_range = range_m


## What this projectile collides with (layers.gd bits).
func hit_mask() -> int:
	return Layers.WORLD


func _ready() -> void:
	collision_layer = 0
	collision_mask = hit_mask()
	monitoring = true
	monitorable = false
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var sphere_mesh: SphereMesh = SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	mesh.mesh = sphere_mesh
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	add_child(mesh)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	step(delta)


## Moves one tick. Public so tests can drive it.
func step(delta: float) -> void:
	if _done:
		return
	if _lock_pending:
		# The spawner positions the node after add_child, so lock on the first step.
		_lock_z = global_position.z
		_lock_pending = false
	var move: Vector2 = direction * speed * delta
	global_position += Vector3(move.x, move.y, 0.0)
	if not is_equal_approx(global_position.z, _lock_z):
		global_position.z = _lock_z
	travelled += move.length()
	if travelled >= max_range:
		finish()


## Ends the projectile (once).
func finish() -> void:
	if _done:
		return
	_done = true
	set_physics_process(false)
	if is_inside_tree():
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if _done:
		return
	_on_hit(body)


## Override. Default: anything in the mask ends it.
func _on_hit(_body: Node3D) -> void:
	finish()
