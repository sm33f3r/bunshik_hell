extends Node3D
## Attached to an object (a shelf, a table...). Drips a drop at a random interval between
## drip_min_s and drip_max_s. The drop is added to the level root, not to this object, and
## falls in the game plane from this node's position.

const DropScene: PackedScene = preload("res://items/sesame_oil_drop.tscn")

signal dripped(drop: Node3D)

@export var drip_min_s: float = 10.0
@export var drip_max_s: float = 30.0
@export var puddle_lifetime_s: float = 8.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _countdown: float = 0.0


func _ready() -> void:
	rng.randomize()
	_countdown = roll_interval()


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
		drop.global_position = global_position
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
