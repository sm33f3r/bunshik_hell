extends Resource
## One slow camera shot of the opening cutscene. The camera moves in a straight line from
## `from_pos` to `to_pos` while looking at a point that moves from `look_from` to `look_to`.
## Positions are in REAL centimetres (x along the counter from its left end, y up from the floor,
## z toward the camera); PrologueData converts them to game metres. With `end_on_pick_camera` the
## shot ends exactly where the pick camera sits (the to_ and look_to fields are then ignored).

@export var label: String = ""
@export var from_pos: Vector3 = Vector3.ZERO
@export var to_pos: Vector3 = Vector3.ZERO
@export var look_from: Vector3 = Vector3.ZERO
@export var look_to: Vector3 = Vector3.ZERO
@export var duration_s: float = 2.0
@export var end_on_pick_camera: bool = false
