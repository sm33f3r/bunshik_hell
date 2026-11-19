class_name SauceTuning
extends Resource
## Every number for sauce attacks and refills. Starting values live in
## res://data/sauce_tuning.tres, never in player code. Units: metres, seconds, m/s.
## Prototype values only; final values come from playtests (Systems Spec §5 #3).

## Sauce spent per flick.
@export var flick_cost: int = 0
@export var flick_range_m: float = 0.0
@export var flick_cooldown_s: float = 0.0
@export var flick_speed_mps: float = 0.0
## Standing in a sauce pool: +1 sauce this often (seconds).
@export var pool_refill_interval_s: float = 0.0
## Sauce a drip pickup gives.
@export var drip_amount: int = 0
