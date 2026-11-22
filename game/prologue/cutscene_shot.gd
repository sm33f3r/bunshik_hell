extends Resource
## One slow camera shot of the opening cutscene. The camera moves in a straight line from
## `from_pos` to `to_pos` while looking at a point that moves from `look_from` to `look_to`.

@export var label: String = ""
@export var from_pos: Vector3 = Vector3.ZERO
@export var to_pos: Vector3 = Vector3.ZERO
@export var look_from: Vector3 = Vector3.ZERO
@export var look_to: Vector3 = Vector3.ZERO
@export var duration_s: float = 2.0
