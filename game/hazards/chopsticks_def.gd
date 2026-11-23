extends "res://hazards/strike_def.gd"
## Other customers' metal chopsticks (Roster §5 hazard). Data: data/hazards/chopsticks.tres.

## Alternations of the wiggle that free him (the prologue's pick needs more: this is the easy one).
@export var wiggle_required: int = 4
## If he does not get free by himself they let go after this long (so nobody is stuck for good).
@export var hold_max_s: float = 6.0
## While holding him they lift him this high (metres) at this speed.
@export var lift_m: float = 2.5
@export var lift_speed_mps: float = 5.0
## They also pick up enemies of these EnemyDef ids that stand in the strike: removed, lifted off-screen.
@export var takes_enemy_ids: PackedStringArray = PackedStringArray(["mandu"])
@export var enemy_lift_m: float = 8.0
@export var enemy_lift_s: float = 0.7
