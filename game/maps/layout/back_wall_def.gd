extends Resource
## A room's back wall behind a floor lane, as data: decor only (no collider), entirely behind the
## character lane, with a hole wherever a wall door of that floor stands.

@export var platform_id: String = ""
## Where it starts: LayoutGeometry.item_x of platform_id / from_id / along_m, then `extra_left_m` further left.
@export var along_m: float = 0.0
@export var from_id: String = ""
@export var extra_left_m: float = 0.0
## It runs on this far past the right end of the floor.
@export var extra_right_m: float = 14.0
@export var height_cm: float = 70.0
## Its front face is this far behind the back edge of the lane (real centimetres). The 정수기's own panel
## sits right against it.
@export var gap_cm: float = 8.0
@export var color: Color = Color(0.68, 0.67, 0.64, 1)
