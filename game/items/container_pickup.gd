extends "res://items/pickup_base.gd"
## A container on the ground. Picked up like an item: it equips if none is held, otherwise
## it stays where it is.

const ItemCatalogScript := preload("res://systems/item_catalog.gd")

@export var container_id: String = "starter_container"


func _ready() -> void:
	super._ready()
	var def: Variant = ItemCatalogScript.container(container_id)
	if def == null:
		return
	var mesh: MeshInstance3D = get_node_or_null("Mesh") as MeshInstance3D
	if mesh != null:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = def.pickup_color
		mat.roughness = 0.7
		mesh.material_override = mat
	var label: Label3D = get_node_or_null("Name") as Label3D
	if label != null:
		label.text = def.display_name


func _collect() -> bool:
	return game_state.try_equip_container(container_id)
