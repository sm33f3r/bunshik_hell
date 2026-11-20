extends "res://items/pickup_base.gd"
## A 나트륨 crystal (gray box: a white diamond). Touch = +amount 나트륨, then it is gone.
## At the cap (7) it stays where it is and is taken later, once there is room.

const NatriumPickupDefScript := preload("res://items/natrium_pickup_def.gd")

const DEF_PATH: String = "res://data/natrium_pickup.tres"

@export var def: NatriumPickupDefScript
## Amount override: -1 = use def.amount. A drop sets this.
@export var amount: int = -1


func pickup_group() -> StringName:
	return &"natrium_pickups"


func effective_amount() -> int:
	if amount >= 0:
		return amount
	if def == null:
		def = load(DEF_PATH) as NatriumPickupDefScript
	return def.amount


func _collect() -> bool:
	if game_state.sodium >= game_state.MAX_SODIUM:
		return false
	game_state.add_sodium(effective_amount())
	return true
