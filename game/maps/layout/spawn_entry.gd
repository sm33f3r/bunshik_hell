extends Resource
## One enemy a section puts on a platform.

@export var platform_id: String = ""
## The enemy's scene (our own content, so it may be referenced directly).
@export var scene: PackedScene
## Metres from the platform's left edge. Negative: from its right edge.
@export var along_m: float = 2.0
## Real centimetres; 0 = the enemy's own size (the 단무지 sizes itself from its EnemyDef).
@export var size_cm: float = 0.0
@export var start_dir: float = 1.0
## Properties set on the enemy node after it is created (e.g. {"speed_scale": 0.0}).
@export var params: Dictionary = {}
## Free text: which beat of the section this belongs to ("a".."e"), for tests and the debug HUD.
@export var group: String = ""
