extends "res://hazards/strike_def.gd"
## A stretch of the floor lane where customers above drop metal chopsticks and spoons: a shadow warns
## (the base's telegraph), then an item from the list falls from the top of the view. Data:
## data/hazards/falling_items.tres. The base's cooldown is the interval between drops; its
## damage and strike width are not used (each item brings its own). Values are 🟡 (playtests).

const FallingItemDefScript := preload("res://hazards/falling_item_def.gd")

## What may fall, with weights (see FallingItemDef).
@export var items: Array[FallingItemDefScript] = []
## How many landed props one zone keeps: the oldest goes when another lands.
@export var cap: int = 4
## Where an item starts above the ground under it (metres): above the top of the view of someone on the floor.
@export var start_height_m: float = 11.0
## The zone only drops while he is within this many metres of it (it waits otherwise).
@export var active_range_m: float = 30.0
## Room kept free beside a table, a ledge or a chair step above (real cm): nothing falls closer than this.
@export var clearance_cm: float = 3.0
## Whether it also hurts enemies under it (the foot's crush rule).
@export var hits_enemies: bool = true
