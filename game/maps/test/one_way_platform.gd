extends StaticBody3D
## A thin platform you can jump up through and drop down through. Godot 3D has no
## built-in one-way collision, so the player toggles the ONE_WAY layer in his mask
## (see ddeok.gd _update_one_way_mask) using top_y() from here.

const Layers := preload("res://systems/layers.gd")

## Distance from this node's origin up to the walkable surface.
@export var top_offset: float = 0.1


func _ready() -> void:
	collision_layer = Layers.ONE_WAY
	collision_mask = 0
	add_to_group("one_way")


func top_y() -> float:
	return global_position.y + top_offset
