extends Resource
## One fixed prop of a section's scenery that he may come to use: a gray-box thing standing on a platform
## (the 정수기 in front of the kitchen doorway). A data placement type: `kind` says what it is, the
## builder makes a node "Fixture_<id>" in the group "fixtures" for it. It is a prop he uses on purpose
## (like a 찜기), so it may reach into the character lane, and it is not solid. `params` is for what a later task adds (the water pour of Task 3c-i-b).

@export var id: String = ""
@export_enum("water_dispenser") var kind: String = "water_dispenser"
@export var platform_id: String = ""
## Metres from the platform's left edge to its middle. Negative: from the right edge.
@export var along_m: float = 2.0
## "" = along_m is on platform_id, the usual way. Else along_m is metres from the RIGHT end of this
## platform, or from the middle of this fixture (negative: back from it). platform_id still says what it
## stands on. See LayoutGeometry.item_x.
@export var from_id: String = ""
@export var lift_m: float = 0.0
## Real centimetres (times the world scale).
@export var width_cm: float = 25.0
@export var height_cm: float = 60.0
## water_dispenser: the underside of the wall unit (where the water comes out) is this high above the floor.
@export var mount_cm: float = 18.0
@export var color: Color = Color(0.62, 0.66, 0.7)
## water_dispenser (read by Task 3c-i-b, nothing uses them yet): "pour_zone_width_m", "sodium_cost".
## Its spout is at the placement's own x (the node carries it as the meta "spout_x").
@export var params: Dictionary = {}
