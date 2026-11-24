extends Resource
## One fixed prop of a section's scenery that he may come to use: a gray-box thing standing on a platform
## (the 정수기 in front of the kitchen doorway). A data placement type: `kind` says what it is, the
## builder makes a node "Fixture_<id>" in the group "fixtures" for it. It stands in the character lane
## like a 찜기 (it is a prop he uses on purpose, not decor he could walk through by mistake), so it is
## not solid. `params` is for what a later task adds (the water pour of Task 3c-i-b).

@export var id: String = ""
@export_enum("water_dispenser") var kind: String = "water_dispenser"
@export var platform_id: String = ""
## Metres from the platform's left edge to its middle. Negative: from the right edge.
@export var along_m: float = 2.0
@export var lift_m: float = 0.0
## Real centimetres (times the world scale).
@export var width_cm: float = 25.0
@export var height_cm: float = 60.0
@export var color: Color = Color(0.62, 0.66, 0.7)
@export var params: Dictionary = {}
