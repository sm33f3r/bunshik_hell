extends RefCounted
## What the 떡 can reach, worked out from MovementTuning (and the 단무지's EnemyDef). The layout
## measures every gap and every ledge against these numbers, so nothing is typed in by hand.

const MovementTuningScript := preload("res://player/movement_tuning.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")

## A step on the main path may use at most this much of what he can do.
const SAFETY: float = 0.85

var tuning: MovementTuningScript
## Game metres per real centimetre (see WorldScale).
var m_per_cm: float = 0.0
## Highest rise of a plain jump (apex of a full jump).
var jump_height: float = 0.0
## Longest flat jump at full run speed (take-off and landing at the same height).
var jump_distance: float = 0.0
## The wheel's diameter, its flat height, and how high a bounce_boost throws him above the wheel top.
var wheel_diameter: float = 0.0
var wheel_flat_height: float = 0.0
var bounce_height: float = 0.0


func _init(p_tuning: MovementTuningScript, wheel: EnemyDefScript, p_m_per_cm: float) -> void:
	tuning = p_tuning
	m_per_cm = p_m_per_cm
	jump_height = tuning.jump_velocity * tuning.jump_velocity / (2.0 * tuning.gravity)
	jump_distance = tuning.max_speed * (tuning.jump_velocity / tuning.gravity + fall_time(jump_height))
	if wheel != null:
		wheel_diameter = wheel.size_cm * m_per_cm
		wheel_flat_height = wheel.flat_height_cm * m_per_cm
		var boost: float = tuning.bounce_velocity * tuning.bounce_boost_multiplier * wheel.bounce_multiplier
		bounce_height = boost * boost / (2.0 * tuning.gravity)


## Seconds to fall `drop` metres (the fall gravity is stronger than the rise).
func fall_time(drop: float) -> float:
	return sqrt(2.0 * maxf(drop, 0.0) / (tuning.gravity * tuning.fall_gravity_scale))


## How far he gets horizontally while jumping up onto something `rise` metres higher.
## (A rise of 0 or less is the flat distance: lower ground only makes it easier.)
func distance_for_rise(rise: float) -> float:
	if rise <= 0.0:
		return jump_distance
	if rise >= jump_height:
		return 0.0
	return tuning.max_speed * (tuning.jump_velocity / tuning.gravity + fall_time(jump_height - rise))


## The reach a `rise_fraction` is measured against (see PlatformDef.rise_basis).
func rise_reference(basis: String) -> float:
	match basis:
		"bounce":
			return wheel_diameter + bounce_height
		"platform":
			return wheel_flat_height + jump_height
	return jump_height


## What he can climb with this kind of step, at the safety margin.
func max_rise(basis: String) -> float:
	return SAFETY * rise_reference(basis)


func max_gap() -> float:
	return SAFETY * jump_distance
