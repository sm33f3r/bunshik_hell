extends StaticBody3D
## A 참기름 source: a real object (a bottle, a brush...) that drips a drop at a random interval
## between drip_min_s and drip_max_s. The drop is added to the level root, not to this object,
## and falls in the game plane.
##
## The object has its own collision, controlled by `standable`:
##   standable = true:  a solid box of object_size on the world layer. The 떡 can land and stand
##                      on it (a bottle, a shelf, a table edge).
##   standable = false: no collision at all (an oil brush hanging from a hook): he falls through.
## Origin: the middle of the object base. The drop appears at drip_offset from the origin;
## keep it clear of the object own box, or the drop lands on the object.

const DropScene: PackedScene = preload("res://items/sesame_oil_drop.tscn")
const Layers := preload("res://systems/layers.gd")

signal dripped(drop: Node3D)

@export var standable: bool = false
## The standable collision box (width, height, depth). Ignored when not standable.
@export var object_size: Vector3 = Vector3(0.3, 0.7, 0.3)
## Where the drop appears, relative to the origin.
@export var drip_offset: Vector3 = Vector3(0.0, -0.2, 0.0)
@export var drip_min_s: float = 10.0
@export var drip_max_s: float = 30.0
@export var puddle_lifetime_s: float = 8.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _countdown: float = 0.0


func _ready() -> void:
	rng.randomize()
	_countdown = roll_interval()
	_build_collision()


## The collision is built from the data flag: a box on the world layer, or nothing.
func _build_collision() -> void:
	for child: Node in get_children():
		if child is CollisionShape3D:
			child.queue_free()
	collision_mask = 0
	if not standable:
		collision_layer = 0
		return
	collision_layer = Layers.WORLD
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = object_size
	shape.shape = box
	shape.position = Vector3(0.0, object_size.y * 0.5, 0.0)
	add_child(shape)


func _physics_process(delta: float) -> void:
	step(delta)


## Next wait in seconds, uniformly between drip_min_s and drip_max_s (swapped if reversed,
## never below 0.1 s).
func roll_interval() -> float:
	var lo: float = minf(drip_min_s, drip_max_s)
	var hi: float = maxf(drip_min_s, drip_max_s)
	return maxf(rng.randf_range(lo, hi), 0.1)


func seconds_until_drip() -> float:
	return _countdown


## One tick. Returns true if it dripped.
func step(delta: float) -> bool:
	_countdown -= delta
	if _countdown > 0.0:
		return false
	_countdown = roll_interval()
	drip()
	return true


## Spawns one drop now (null when this node is not in a tree).
func drip() -> Node3D:
	var drop: Node3D = null
	if is_inside_tree():
		drop = DropScene.instantiate() as Node3D
		drop.set("puddle_lifetime_s", puddle_lifetime_s)
		_world_root().add_child(drop)
		drop.global_position = global_transform * drip_offset
	dripped.emit(drop)
	return drop


## The top node of the level (the child of the viewport root), so the drop does not move
## with the object it dripped from.
func _world_root() -> Node:
	var node: Node = self
	var root: Node = get_tree().root
	while node.get_parent() != null and node.get_parent() != root:
		node = node.get_parent()
	return node
