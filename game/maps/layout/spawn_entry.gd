extends Resource
## One thing a section puts on a platform: an enemy, a hazard zone, a pickup.

@export var platform_id: String = ""
## The scene (our own content, so it may be referenced directly).
@export var scene: PackedScene
## Metres from the platform's left edge. Negative: from its right edge.
@export var along_m: float = 2.0
## Real centimetres; 0 = the thing's own size (the 단무지 sizes itself from its EnemyDef). For a
## hazard zone it is the width of the zone.
@export var size_cm: float = 0.0
@export var start_dir: float = 1.0
## Properties set on the node after it is created (e.g. {"speed_scale": 0.0}).
@export var params: Dictionary = {}
## Free text: which beat or lane the entry belongs to, for tests and the debug HUD.
@export var group: String = ""

@export_group("Respawn")
## If it ends up out of reach (see below) for respawn_delay_s it is put back as it started. It is
## also put back at once when he steps onto its platform again. false = never.
@export var respawn_when_out_of_reach: bool = false
@export var respawn_delay_s: float = 4.0
## Out of reach: it fell this far below its platform's top ...
@export var out_below_m: float = 1.5
## ... or it is knocked over (flat) anywhere outside this stretch of its platform (metres along it,
## negative from its right edge). Both 0 = any flat position is fine.
@export var useful_from_m: float = 0.0
@export var useful_to_m: float = 0.0
