extends "res://enemies/enemy_base.gd"
## 만두 stand-in: small, walks back and forth around its spawn point.

@export var walk_speed: float = 1.5
@export var patrol_half_width: float = 2.5

var _home_x: float = 0.0
var _dir: float = 1.0


func _on_ready() -> void:
	_home_x = position.x


func _on_reset() -> void:
	_dir = 1.0


func _ai(_delta: float) -> void:
	var offset: float = position.x - _home_x
	if absf(offset) >= patrol_half_width and signf(offset) == _dir:
		_dir = -_dir
	elif is_on_wall() and signf(get_wall_normal().x) == -_dir:
		_dir = -_dir
	velocity.x = _dir * walk_speed
