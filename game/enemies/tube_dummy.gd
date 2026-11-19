extends "res://enemies/enemy_base.gd"
## Tube candy stand-in: stationary, fires a slow pellet at the 떡 every fire_interval seconds
## while he is within fire_range. A jam hit (sauce) switches the shooting off for good.

const PelletScript := preload("res://projectiles/enemy_pellet.gd")

@export var fire_interval: float = 2.0
@export var pellet_speed: float = 4.0
## Only shoots while the 떡 is this close (metres), so a far-off dummy is not a nuisance.
@export var fire_range: float = 12.0
@export var pellet_max_range: float = 20.0
## Muzzle height above the feet.
@export var muzzle_height: float = 0.5

var _fire_timer: float = 0.0


func _on_reset() -> void:
	_fire_timer = 0.0


## Advances the fire timer. True when a shot is due; never while dead or jammed.
func advance_fire_timer(delta: float) -> bool:
	if not alive or jammed:
		return false
	_fire_timer += delta
	if _fire_timer < fire_interval:
		return false
	_fire_timer = 0.0
	return true


func _ai(delta: float) -> void:
	velocity.x = 0.0
	if not advance_fire_timer(delta) or not is_inside_tree():
		return
	var target: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	var parent: Node = get_parent()
	if target == null or parent == null:
		return
	var muzzle: Vector3 = global_position + Vector3(0.0, muzzle_height, 0.0)
	var aim: Vector2 = Vector2(target.global_position.x - muzzle.x, target.global_position.y - muzzle.y)
	if aim.length() > fire_range or aim.is_zero_approx():
		return
	var pellet: PelletScript = PelletScript.new()
	pellet.launch(aim, pellet_speed, pellet_max_range)
	parent.add_child(pellet)
	pellet.global_position = muzzle
