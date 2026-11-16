extends Camera3D
## Side camera: follows the target on X/Y only and pans a little with look_up / look_down
## while the target stands on the ground.
##
## Physics interpolation is on (project setting physics/common/physics_interpolation), so the
## target is only moved on physics ticks. This camera therefore runs in _process and reads the
## target's interpolated transform; its own interpolation is switched off so it is not
## smoothed twice.

@export var target: Node3D
@export var offset: Vector3 = Vector3(0.0, 2.5, 14.0)
@export var follow_speed: float = 6.0
## How far the view pans at full look_up / look_down.
@export var look_pan: float = 2.5
@export var pan_speed: float = 6.0

var _pan: float = 0.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if target != null:
		global_position = _desired()


func _process(delta: float) -> void:
	if target == null:
		return
	var want: float = 0.0
	var body: CharacterBody3D = target as CharacterBody3D
	if body != null and body.is_on_floor():
		want = Input.get_axis("look_down", "look_up") * look_pan
	_pan = move_toward(_pan, want, pan_speed * delta)
	global_position = global_position.lerp(_desired(), 1.0 - exp(-follow_speed * delta))


func _desired() -> Vector3:
	var at: Vector3 = target.position
	if target.is_inside_tree():
		at = target.get_global_transform_interpolated().origin
	return Vector3(at.x, at.y + _pan, 0.0) + offset
