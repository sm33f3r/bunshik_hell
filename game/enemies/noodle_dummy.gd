extends "res://enemies/enemy_base.gd"
## The 라면 dummy: creeps slowly toward the 떡 while he is within def.creep_range_m (measured
## in the game plane). Touching it hurts through the normal contact path. Swelling slows it
## to a stop (speed_factor); a pinned noodle does not move at all (the base skips _ai).

## Stops this close to the 떡 horizontally, so it does not shake back and forth under him.
const ARRIVE_DISTANCE: float = 0.1


func _ai(_delta: float) -> void:
	velocity.x = 0.0
	if def == null or def.creep_speed_mps <= 0.0 or not is_inside_tree():
		return
	var target: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if target == null:
		return
	velocity.x = creep_velocity_x(target.global_position)


## The x velocity toward a target position: 0 when out of range, arrived, or swelled to a stop.
func creep_velocity_x(target: Vector3) -> float:
	var to_target: Vector2 = Vector2(target.x, target.y) - center_xy()
	if to_target.length() > def.creep_range_m or absf(to_target.x) < ARRIVE_DISTANCE:
		return 0.0
	return signf(to_target.x) * def.creep_speed_mps * speed_factor()
