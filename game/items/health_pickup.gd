extends "res://items/pickup_base.gd"
## A carried health item on the ground. Touching it NEVER heals: it goes into the inventory.
## No container: it stays. Container full: the "full" popup opens (see GameState).

const ItemCatalogScript := preload("res://systems/item_catalog.gd")

@export var item_id: String = "kongomul"


func _ready() -> void:
	super._ready()
	var def: Variant = ItemCatalogScript.health_item(item_id)
	if def == null:
		return
	var mesh: MeshInstance3D = get_node_or_null("Mesh") as MeshInstance3D
	if mesh != null:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = def.pickup_color
		mat.roughness = 0.4
		mesh.material_override = mat
	var label: Label3D = get_node_or_null("Name") as Label3D
	if label != null:
		label.text = def.display_name


func _collect() -> bool:
	match game_state.try_pickup_item(item_id):
		GameStateScript.Pickup.PICKED:
			return true
		GameStateScript.Pickup.FULL:
			if not _popup_suppressed and not game_state.popup_open():
				_popup_suppressed = true
				game_state.open_popup(item_id, _on_popup_used)
	return false


func _on_popup_used() -> void:
	_consume()
