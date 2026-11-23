extends "res://hazards/strike_def.gd"
## A giant foot (a customer's shoe, as seen from the floor). Data: data/hazards/giant_foot.tres.

## How long he is flat under it, and then pops back (damage is the base's damage_half_hearts).
@export var stun_s: float = 0.6
## The foot's size, real centimetres times the world scale (the strike width is the base's).
@export var foot_height_cm: float = 14.0
## Height the foot comes down from (metres above the floor).
@export var drop_from_m: float = 8.0
