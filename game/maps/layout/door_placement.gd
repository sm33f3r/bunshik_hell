extends "res://maps/layout/fixture_placement.gd"
## A door on a room's back wall, entered with look_up (W): a fixture of kind "wall_door". It replaces
## the piece of the wall where it stands (see BackWallDef), is not solid and has no collider. `width_cm`
## x `height_cm` is the whole door, frame included; `color` is the frame's. Pressing W in its zone on
## the floor lane takes him, behind a fade, to the door `target_door_id`.

## A door is about 1:2, and no taller than what the camera shows well from the floor. 🟡
const MIN_ASPECT: float = 1.7
const MAX_ASPECT: float = 2.2
const MAX_HEIGHT_M: float = 6.6
## The zone in front of it is a small one. 🟡
const MAX_ZONE_M: float = 3.0

## The door he arrives at (a fixture id of kind "wall_door").
@export var target_door_id: String = ""
## A story flag (GameState.has_flag) that must be set for it to open. "" = never locked.
@export var locked_until_flag: String = ""
## How wide (along the lane) the zone in front of it is.
@export var zone_width_m: float = 2.0

@export_group("Look")
## The width of the two posts; the lintel is `lintel_cm` high, the threshold `threshold_cm`.
@export var post_cm: float = 2.0
@export var lintel_cm: float = 2.8
@export var threshold_cm: float = 0.8
## How far back from the wall the dark room behind the opening goes.
@export var recess_cm: float = 7.0
@export var interior_color: Color = Color(0.1, 0.085, 0.075, 1)
## The flat rubber curtain strips hanging in the opening, in the wall's plane.
@export var strips: int = 5
## Each strip's width as a fraction of the space it has (the rest is the gap between strips).
@export var strip_fill: float = 0.95
@export var strip_color: Color = Color(0.55, 0.62, 0.56, 0.62)
## Where the strips end, above the floor: every other one `strip_ragged_cm` higher, so they hang like
## separate flaps and the dark room shows under them.
@export var strip_bottom_cm: float = 3.2
@export var strip_ragged_cm: float = 1.1
