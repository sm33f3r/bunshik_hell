class_name EnemyDef
extends Resource
## Data for one kind of enemy. Behaviour differences beyond this live in a small script.

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
