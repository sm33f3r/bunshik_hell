extends Resource
## One table, bench or ledge of a map section, as data. Nothing here is a coordinate: where it
## stands is worked out from the platform before it (see LayoutGeometry), using what the 떡 can
## actually do (MovementTuning), so the gaps and heights follow the tuning when it changes.

## "table": a slab on legs. "ledge": a solid block whose wall reaches down to the platform before it.
## "existing": built by someone else (the prologue's next table); its place comes from the caller.
@export var id: String = ""
@export_enum("table", "ledge", "existing") var kind: String = "table"
## Real centimetres (times the world scale), like everything else on the Map 1 set.
@export var length_cm: float = 60.0
@export var thickness_cm: float = 4.0
## Empty space before this platform, as a fraction of the longest jump the 떡 can make.
@export var gap_fraction: float = 0.0
## Height of the top above the previous top, as a fraction of the reach named by `rise_basis`.
## Negative: lower than the one before.
@export var rise_fraction: float = 0.0
## Which reach `rise_fraction` is measured against:
## "jump": his jump height.
## "bounce": the height of a 단무지 bounce (the wheel's own height plus the boost).
## "platform": a knocked-over 단무지 (its flat height) plus his jump height.
@export_enum("jump", "bounce", "platform") var rise_basis: String = "jump"
## On the way through the map (checked by the layout validation). Off-path platforms are extras.
@export var main_path: bool = true
@export var color: Color = Color(0.62, 0.45, 0.28)
