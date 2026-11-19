class_name SesameOilTuning
extends Resource
## 참기름 numbers (data/sesame_oil.tres). Not a carried item: heals on touch, only if hurt.

## Half-hearts healed per drop, puddle or smudge. Systems spec: ½ heart.
@export var heal_half_hearts: int = 1
@export var gravity: float = 14.0
@export var max_fall_speed: float = 14.0
## Touch radius of a drop, puddle and smudge.
@export var radius: float = 0.3
## A drop that never lands is removed after this long.
@export var max_fall_time_s: float = 12.0
@export var color: Color = Color(0.85, 0.65, 0.1, 0.9)
