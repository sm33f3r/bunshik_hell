extends RefCounted
## Physics queries the environment specials share. The query runs against the physics space
## right now (no one-frame lag, unlike an Area3D's overlap list).

const EnemyBaseScript := preload("res://enemies/enemy_base.gd")
const Layers := preload("res://systems/layers.gd")


## Living enemies whose body touches the axis-aligned box. Needs a world (a scene tree).
static func enemies_in_box(world: World3D, center: Vector3, size: Vector3) -> Array[EnemyBaseScript]:
	var out: Array[EnemyBaseScript] = []
	if world == null:
		return out
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, center)
	query.collision_mask = Layers.ENEMY
	query.collide_with_bodies = true
	query.collide_with_areas = false
	for hit: Dictionary in world.direct_space_state.intersect_shape(query, 32):
		var enemy: EnemyBaseScript = hit["collider"] as EnemyBaseScript
		if enemy != null and enemy.alive and not out.has(enemy):
			out.append(enemy)
	return out


## Height of the first walkable surface straight down from (x, from_y) to (x, to_y), or NAN.
static func surface_below(world: World3D, x: float, z: float, from_y: float, to_y: float) -> float:
	if world == null:
		return NAN
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		Vector3(x, from_y, z), Vector3(x, to_y, z), Layers.WORLD | Layers.ONE_WAY)
	var hit: Dictionary = world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return NAN
	return (hit["position"] as Vector3).y
