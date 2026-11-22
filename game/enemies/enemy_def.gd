class_name EnemyDef
extends Resource
## Data for one kind of enemy. Behaviour differences beyond this live in a small script.

const DropEntryScript := preload("res://systems/drop_entry.gd")

@export var id: String = ""
## Key into the reaction table (e.g. "soft", "tall_rigid").
@export var material: String = ""
@export var max_hp: int = 1
## Damage dealt to the player on side contact, in half-hearts.
@export var contact_damage_half_hearts: int = 0
## "deteriorate" hits needed per stage. Size sets durability (small 1, medium 2, large 3).
@export var hits_per_stage: int = 1
## Skill id unlocked the first time an enemy with this def id is defeated. Empty = none.
@export var unlocks_skill_on_first_defeat: StringName = &""
## Seconds a "swell" (water on a noodle) takes: the enemy grows and slows to a stop, then dies.
@export var swell_time_s: float = 2.0
## Creeping enemies (0 = stands still): speed in m/s, and how close the 떡 must be (metres,
## in the game plane) before it starts to creep toward him.
@export var creep_speed_mps: float = 0.0
@export var creep_range_m: float = 6.0
## Walkers (0 = stands still): walking speed in m/s.
@export var walk_speed_mps: float = 0.0
## Hoppers: how close the 떡 must be (metres) before it hops, the hop's launch speed (m/s) and
## the rest between hops (seconds). hop_range_m 0 = never hops.
@export var hop_range_m: float = 0.0
@export var hop_velocity_mps: float = 0.0
@export var hop_cooldown_s: float = 1.5
## What it may leave behind when it dies (see DropEntry). Empty = nothing.
@export var drops: Array[DropEntryScript] = []
## Bad-luck protection: after this many kills in a row (of this enemy type) with no drop,
## the next kill always drops.
@export var drop_guarantee_after: int = 4
## Guaranteed periodic drop: every Nth kill BY THE 떡 of this enemy type also drops
## `every_nth_drop` (a DropEntry kind) where it died. 0 = off. Independent of `drops`.
@export var every_nth_kill: int = 0
@export var every_nth_drop: String = ""
