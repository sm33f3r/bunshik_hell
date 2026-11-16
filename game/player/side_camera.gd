extends Camera3D
## Side camera: follows the target on X/Y only and pans a little with look_up / look_down
## while the target stands on the ground.

@export var target: Node3D
@export var offset: Vector3 = Vector3(0.0, 2.5, 14.0)
@export var follow_speed: float = 6.0
## How far the view pans at full look_up / look_down.
@export var look_pan: float = 2.5
@export var pan_speed: float = 6.0

var _pan: float = 0.0


func _ready() -> void:
	if target != null:
		global_position = _desired()


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var want: float = 0.0
	var body: CharacterBody3D = target as CharacterBody3D
	if body != null and body.is_on_floor():
		want = Input.get_axis("look_down", "look_up") * look_pan
	_pan = move_toward(_pan, want, pan_speed * delta)
	global_position = global_position.lerp(_desired(), 1.0 - exp(-follow_speed * delta))


func _desired() -> Vector3:
	return Vector3(target.global_position.x, target.global_position.y + _pan, 0.0) + offset
