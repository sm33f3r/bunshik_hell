class_name EnvSpecialDef
extends Resource
## Data for one usable environment object (a water bottle, a pot...). The `special` action
## spends natrium_cost 나트륨 and then does what `kind` says. Content is data: one .tres each.

const KIND_POUR_WATER: String = "pour_water"
const KIND_HEAVY_OBJECT: String = "heavy_object"
const SIZE_SMALL: String = "small"
const SIZE_MEDIUM: String = "medium"
const SIZE_LARGE: String = "large"

@export var id: String = ""
@export var display_name: String = ""
## KIND_POUR_WATER or KIND_HEAVY_OBJECT.
@export var kind: String = KIND_POUR_WATER
@export var natrium_cost: int = 1
## Heavy objects only: SIZE_SMALL / SIZE_MEDIUM / SIZE_LARGE. Sets the pin time and the body.
@export var size: String = SIZE_SMALL
## Pin time in seconds per size (a bigger object pins longer).
@export var pin_small_s: float = 3.0
@export var pin_medium_s: float = 6.0
@export var pin_large_s: float = 10.0
## Pour water: how far the water sheet runs along the floor (metres).
@export var reach_m: float = 3.0
## Pour water: how long the sheet stays wet (seconds).
@export var sheet_lifetime_s: float = 4.0
## Heavy object: horizontal speed it is knocked off with (m/s), and its fall gravity (m/s^2).
@export var knock_speed_mps: float = 2.0
@export var fall_gravity: float = 20.0
## How close the 떡 must be (distance in the game plane, metres) to use it.
@export var use_range_m: float = 1.5
@export var tint: Color = Color(0.4, 0.6, 0.9, 1.0)


func is_pour_water() -> bool:
	return kind == KIND_POUR_WATER


func is_heavy_object() -> bool:
	return kind == KIND_HEAVY_OBJECT


## Pin duration for this def's size. 0 for anything that is not a heavy object.
func pin_s() -> float:
	if not is_heavy_object():
		return 0.0
	match size:
		SIZE_MEDIUM:
			return pin_medium_s
		SIZE_LARGE:
			return pin_large_s
	return pin_small_s


## Collision/mesh size of the object's box (width, height, depth) by kind and size.
func body_size() -> Vector3:
	if is_pour_water():
		return Vector3(0.22, 0.5, 0.22)
	match size:
		SIZE_MEDIUM:
			return Vector3(0.7, 0.45, 0.5)
		SIZE_LARGE:
			return Vector3(1.0, 0.7, 0.6)
	return Vector3(0.5, 0.32, 0.4)
