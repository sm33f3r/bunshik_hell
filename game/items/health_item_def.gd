class_name HealthItemDef
extends Resource
## One carried health item (data). Hearts are in half-heart units.

@export var id: String = ""
## Shown to the player. Keep Korean names here; UI sentences around them go through tr().
@export var display_name: String = ""
@export var heal_half_hearts: int = 2
## Also gives a coat that blocks the damage of the next hit.
@export var grants_coat: bool = false
## Gray-box pickup colour.
@export var pickup_color: Color = Color(1, 1, 1, 1)
