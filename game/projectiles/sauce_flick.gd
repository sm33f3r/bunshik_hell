extends "res://projectiles/projectile.gd"
## The sauce flick: flies straight ahead. An enemy hit goes through the reaction table
## (attack "sauce"); world geometry just stops it.

const EnemyBaseScript := preload("res://enemies/enemy_base.gd")
const ReactionTableScript := preload("res://systems/reaction_table.gd")


func hit_mask() -> int:
	return Layers.WORLD | Layers.ENEMY


func _on_hit(body: Node3D) -> void:
	var enemy: EnemyBaseScript = body as EnemyBaseScript
	if enemy != null:
		if not enemy.alive:
			return # already on its way out: fly through
		enemy.receive_attack(ReactionTableScript.ATTACK_SAUCE, signf(direction.x))
	finish()
