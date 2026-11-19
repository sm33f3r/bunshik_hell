class_name ContainerDef
extends Resource
## One kind of container (data). The container is itself an item the 떡 picks up.

@export var id: String = ""
@export var display_name: String = ""
## One item per slot. No stacking.
@export var capacity: int = 3
## Gray-box pickup colour.
@export var pickup_color: Color = Color(0.55, 0.38, 0.2, 1)
