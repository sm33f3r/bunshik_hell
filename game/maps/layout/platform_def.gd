extends Resource
## One table, bench, ledge, napkin box, windowsill, floor or chair stairs of a map section, as data.
## Nothing here is a coordinate: where it stands is worked out from the platform it is placed against
## (see LayoutGeometry), using what the 떡 can actually do (MovementTuning), so the gaps and heights
## follow the tuning when it changes.

## "table": a slab on legs. "ledge": a solid block whose wall reaches down to the platform before it.
## "existing": built by someone else (the prologue's next table); its place comes from the caller.
## "prop": a small solid box standing on its host (a napkin box). "sill": a windowsill slab, higher up.
## "block": a solid block that reaches down to the floor (a chair step). "floor": the floor lane under
## a stretch of tables. "stairs": expands into a staircase of blocks (see below).
@export var id: String = ""
@export_enum("table", "ledge", "existing", "prop", "sill", "block", "floor", "stairs") var kind: String = "table"
## Real centimetres (times the world scale), like everything else on the Map 1 set.
@export var length_cm: float = 60.0
@export var thickness_cm: float = 4.0
## The platform this one is placed against ("" = the one before it on the way through the map).
@export var host: String = ""
## "after": its left edge is `gap` after the host's right edge. "at": its left edge is `along_cm` from
## the host's left edge (it sits on the host). "at_end": its right edge is `along_cm` before the
## host's right edge.
@export_enum("after", "at", "at_end") var anchor: String = "after"
@export var along_cm: float = 0.0
## Empty space before this platform, as a fraction of the longest jump the 떡 can make ("after" only).
@export var gap_fraction: float = 0.0
## Height of the top above the host's top, as a fraction of the reach named by `rise_basis`.
## Negative: lower than the host.
@export var rise_fraction: float = 0.0
## Which reach `rise_fraction` is measured against:
## "jump": his jump height.
## "bounce": the height of a 단무지 bounce (the wheel's own height plus the boost).
## "platform": a knocked-over 단무지 (its flat height) plus his jump height.
## "cm": not a fraction: `rise_cm` real centimetres (a napkin box's height).
@export_enum("jump", "bounce", "platform", "cm") var rise_basis: String = "jump"
@export var rise_cm: float = 0.0
## Becomes the platform the next one is placed against (when its host is "").
@export var chain: bool = true
## On the way through the map (checked by the layout validation). Off-path platforms are extras.
@export var main_path: bool = true
@export var color: Color = Color(0.62, 0.45, 0.28)

@export_group("Decor")
## Where this platform's decor that is NOT a collider (a table's legs, a chair's legs) stands across the
## character lane. "behind": entirely further from the camera than the lane (the lane is the depth of
## the tables he and the enemies walk on), so nothing they can walk through is ever in their way.
## LaneRules tests that no decor is in the lane.
@export_enum("behind") var decor_layer: String = "behind"
## Space between the back edge of the lane and the decor (real centimetres, times the world scale).
@export var decor_gap_cm: float = 1.0
## The legs' size: this wide (x) and this deep (z), real centimetres.
@export var leg_width_cm: float = 3.4
@export var leg_depth_cm: float = 3.4

@export_group("Floor")
## The floor lane runs from under `span_from` to under `span_to` (platform ids), `span_margin_cm`
## further out at each end. Its top is `drop_cm` below the top of `drop_from`. At its left end a wall
## `wall_cm` high keeps him on it.
@export var span_from: String = ""
@export var span_to: String = ""
@export var span_margin_cm: float = 0.0
@export var drop_from: String = ""
@export var drop_cm: float = 0.0
@export var wall_cm: float = 0.0
## The lane runs this much further right than the margin says (a stub beyond the last table).
@export var span_extra_right_cm: float = 0.0
## A floor of a room of its own (no span_from): it has a `host` floor, starts `after_gap_cm` past that
## one's right end at the same height, and is `length_cm` long. Reached only through a wall door.
@export var after_gap_cm: float = 0.0

@export_group("Stairs")
## The way back up from the floor: `steps` blocks next to the `host` table, going down away from it
## (`side` "right" or "left"). The first step's top is `top_drop_cm` below the host's top, the last
## one's is `bottom_rise_cm` above the floor, and the ones between are spread evenly. Each is
## `length_cm` wide; the first starts `along_cm` from the table's edge. The ids are <id>_1 .. <id>_n.
@export var steps: int = 8
@export_enum("right", "left") var side: String = "right"
@export var top_drop_cm: float = 9.0
@export var bottom_rise_cm: float = 8.0
