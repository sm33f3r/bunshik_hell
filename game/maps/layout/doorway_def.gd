extends Resource
## A doorway between two rooms, as data. It is OPEN: never locked, never solid. A frame stands behind the
## character lane (decor), and rubber curtain strips hang from the top of the opening in the lane: not
## solid, they sway when he passes. Visual only.

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
@export var bottom_edge_cm: float = 12.0

@export_group("Strips")
@export var strips: int = 9
## Each strip's width as a fraction of the space it has (the rest is the gap between strips).
@export var strip_fill: float = 0.8
@export var strip_color: Color = Color(0.5, 0.58, 0.6, 1)
@export var frame_color: Color = Color(0.55, 0.5, 0.45, 1)
@export var frame_thickness_cm: float = 3.0
## How far a strip swings at most (radians), and how fast it settles (per second).
@export var sway_max_rad: float = 0.5
@export var sway_stiffness: float = 40.0
@export var sway_damping: float = 4.0
## What a strip needs from him to swing: how far (metres) his body reaches to either side, and the push
## per metre per second of his speed.
@export var sway_reach_m: float = 1.0
@export var sway_gain: float = 14.0
