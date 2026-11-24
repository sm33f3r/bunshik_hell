extends "res://enemies/enemy_def.gd"
## One kind of knock-over squirt bottle (the 간장 bottle), as data. It is an EnemyDef (it takes the
## attacks the 떡 makes through the reaction table, like the 단무지), plus what is its own: its size, how
## many times it squirts, what each squirt gives, and how the gray-box blast looks.
## Where it stands is the map layout's business (a SpawnEntry with candidates, see SpawnChoice).
## Every number here is 🟡 until playtested.

## The reaction-table rows it reads: standing, and lying on its side.
@export var upright_material: String = "bottle_upright"
@export var fallen_material: String = "bottle_fallen"

@export_group("Squirts")
## Hits that squirt: this many, then it is empty (until the life starts over).
@export var squirts_max: int = 5
## 나트륨 each squirt gives, added straight to GameState (it is capped there like all 나트륨).
@export var sodium_per_squirt: int = 3

@export_group("Size")
## Real centimetres (times the world scale). Standing: height x width (a square foot). It must be
## no taller than he can climb (the layout check says if it is).
@export var height_cm: float = 8.0
@export var width_cm: float = 3.5

@export_group("Look")
@export var body_color: Color = Color(0.46, 0.56, 0.5, 1)
@export var cap_color: Color = Color(0.78, 0.14, 0.1, 1)
@export var liquid_color: Color = Color(0.1, 0.05, 0.03, 1)
## The blast: this long and thick (real cm), shown for blast_time_s, then it is gone.
@export var blast_length_cm: float = 12.0
@export var blast_thickness_cm: float = 1.3
@export var blast_time_s: float = 0.4
@export var blast_color: Color = Color(0.2, 0.09, 0.03, 1)
## The little puff of an empty bottle that is hit.
@export var empty_puff_color: Color = Color(0.85, 0.85, 0.82, 0.8)
@export var empty_puff_time_s: float = 0.35
