extends "res://enemies/enemy_base.gd"
## A dummy that stays put. Everything it does comes from its EnemyDef and the reaction table.


func _ai(_delta: float) -> void:
	velocity.x = 0.0
