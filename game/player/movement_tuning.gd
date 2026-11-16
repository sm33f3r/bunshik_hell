class_name MovementTuning
extends Resource
## Every number that shapes how the 떡 moves and fights. Starting values live in
## res://data/movement_tuning.tres, never in player code. All fields default to 0 on
## purpose: a field missing from the .tres shows up as unset (see unset_fields()).
## Units: metres, seconds, m/s, m/s². Prototype values only; final values come from playtests.

@export_group("Run")
@export var max_speed: float = 0.0
@export var acceleration: float = 0.0
@export var friction: float = 0.0
@export var air_acceleration: float = 0.0
@export var air_friction: float = 0.0

@export_group("Jump")
@export var gravity: float = 0.0
## Gravity multiplier while moving down (snappier falls).
@export var fall_gravity_scale: float = 0.0
@export var max_fall_speed: float = 0.0
@export var jump_velocity: float = 0.0
## Multiplier applied to upward speed when jump is released early.
@export var short_hop_cut: float = 0.0
@export var coyote_time: float = 0.0
@export var buffer_time: float = 0.0

@export_group("Attacks")
@export var stomp_speed: float = 0.0
@export var roll_speed: float = 0.0
@export var roll_duration: float = 0.0
@export var roll_cooldown: float = 0.0
@export var slam_speed: float = 0.0
@export var slam_radius: float = 0.0
## Upward speed after a landing or stomp hits an enemy.
@export var bounce_velocity: float = 0.0
## How far below an enemy's top the previous-frame feet may be and still count as "from above".
@export var above_tolerance: float = 0.0

@export_group("Damage")
@export var i_frame_time: float = 0.0
@export var flash_interval: float = 0.0
@export var knockback_horizontal: float = 0.0
@export var knockback_vertical: float = 0.0
@export var hurt_stun_time: float = 0.0
@export var respawn_delay: float = 0.0

@export_group("One-way platforms")
@export var drop_through_time: float = 0.0
## Feet may be this far below a platform's top and still land on it.
@export var one_way_tolerance: float = 0.0


## Names of every numeric field that is still 0 or below.
func unset_fields() -> Array[String]:
	var out: Array[String] = []
	for prop: Dictionary in get_property_list():
		var usage: int = prop["usage"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and prop["type"] == TYPE_FLOAT:
			var value: float = get(prop["name"])
			if value <= 0.0:
				out.append(prop["name"])
	return out
