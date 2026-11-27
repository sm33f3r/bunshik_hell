extends Resource
## A doorway between two rooms, as data. It is OPEN: never locked, never solid. He walks through it along
## the lane: the frame (jambs, lintel, header wall) is a thin slab just behind the plane he walks in
## (z = 0), and the curtain strips hang from the lintel just in front of it. The strips are thin,
## see-through, not solid, and sway when he passes. Visual only.

## The furthest toward the camera a curtain strip may reach (metres in front of z = 0). 🟡
const CURTAIN_FRONT_MAX_M: float = 0.3
## The furthest back the frame may reach (metres behind z = 0). 🟡
const FRAME_BACK_MAX_M: float = 0.3

@export var id: String = ""
## The floor it stands on, and the metres from its left edge to the middle of the opening (negative: from
## the right edge).
@export var platform_id: String = ""
@export var along_m: float = 0.0
## "" = along_m is on platform_id, the usual way. Else along_m is metres from the RIGHT end of this
## platform, or from the middle of this fixture (negative: back from it). platform_id still says what it
## stands on. See LayoutGeometry.item_x.
@export var from_id: String = ""
## Real centimetres (times the world scale): the opening's width and height (the strips hang from the top).
@export var width_cm: float = 40.0
@export var height_cm: float = 40.0
## Where the strips end: this high above the floor. The default is above his head.
@export var bottom_edge_cm: float = 1.5

@export_group("Strips")
@export var strips: int = 9
## Each strip's width as a fraction of the space it has (the rest is the gap between strips).
@export var strip_fill: float = 0.8
@export var strip_color: Color = Color(0.7, 0.82, 0.85, 0.4)
## The depths the strips hang at, metres in front of z = 0 (they alternate between the two), and how
## thick a strip is. The whole strip stays between 0 and CURTAIN_FRONT_MAX_M.
@export var strip_z_near_m: float = 0.27
@export var strip_z_far_m: float = 0.285
@export var strip_thickness_m: float = 0.02
## The height of the flap at the top of each strip that reaches back to the lintel's face (no gap).
@export var strip_flap_m: float = 0.12

@export_group("Frame and walls")
@export var frame_color: Color = Color(0.55, 0.5, 0.45, 1)
@export var frame_thickness_cm: float = 2.0
## The frame's front face is this far behind z = 0 (metres), and how deep the frame and header are.
@export var frame_clearance_m: float = 0.0
@export var frame_depth_m: float = 0.25
## The rooms' back walls: how far behind the lane strip their front face is, how high they reach from
## the floor, and how far the first room's wall reaches back from the opening. The two walls meet behind the
## MIDDLE of the opening: being further from the camera than the frame they shift against it as he moves,
## and from there the seam only ever shows through the opening, never beside it. The second room's wall
## runs on to the right end of the floor.
@export var wall_gap_cm: float = 9.0
@export var wall_height_cm: float = 70.0
@export var wall_before_cm: float = 160.0
@export var wall_color_before: Color = Color(0.68, 0.67, 0.64, 1)
@export var wall_color_after: Color = Color(0.42, 0.45, 0.49, 1)

@export_group("Sway")
## How far a strip swings at most (radians), and how fast it settles (per second).
@export var sway_max_rad: float = 0.5
@export var sway_stiffness: float = 40.0
@export var sway_damping: float = 4.0
## What a strip needs from him to swing: how far (metres) his body reaches to either side, and the push
## per metre per second of his speed.
@export var sway_reach_m: float = 1.0
@export var sway_gain: float = 14.0
