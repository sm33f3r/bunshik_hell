extends "res://enemies/enemy_base.gd"
## 어묵 stand-in: tall and stationary. Its only behaviour is what the reaction table
## does to it (knock_over plays the tip-over in the base class, then it is removed).


func _ai(_delta: float) -> void:
	velocity.x = 0.0
