extends "res://projectiles/projectile.gd"
## A tube dummy's slow pellet. Half a heart (1 half-heart) to the 떡, then it is gone.

@export var damage_half_hearts: int = 1


func _init() -> void:
	radius = 0.12
	color = Color(0.9, 0.85, 0.2, 1)


func hit_mask() -> int:
	return Layers.WORLD | Layers.PLAYER


func _on_hit(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("hurt"):
		body.call("hurt", damage_half_hearts, global_position.x)
	finish()
