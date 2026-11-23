extends "res://tests/physics_base.gd"
## Base for the real Map 1 physics suites of Task 3b-ii-fix: opens the real map scene (the tutorial
## with its prompt answered, or the dining room with the tutorial skipped) and holds the helpers they
## share. Everything is played with real input; waits are counted in physics frames.

const MAP_SCENE := "res://maps/ep01/map01_bunsikjip/map01.tscn"
const LayoutGeometryScript := preload("res://maps/layout/layout_geometry.gd")
const MapFlowScript := preload("res://maps/layout/map_flow.gd")

var map: Node3D
var flow: Node


## Opens Map 1 on a fresh game (cutscene seen) and finishes the prologue with debug key 8: that
## leaves the tutorial prompt open. The old plate 만두 are removed.
func open_prompt() -> void:
	gs = tree.root.get_node_or_null("GameState")
	if gs == null:
		failures.append("GameState autoload missing")
		return
	gs.call("reset")
	gs.set("prologue_intro_seen", true)
	room = (load(MAP_SCENE) as PackedScene).instantiate() as Node3D
	tree.root.add_child(room)
	map = room
	player = room.get_node("Player") as CharacterBody3D
	await frames(3)
	flow = map.get("flow")
	for mandu: Node3D in (map.call("live_mandu") as Array):
		mandu.call("debug_defeat")
	map.get("_mandu_respawn").set("count", 0)
	await key_event(KEY_8)
	await frames(20)


## ... and answers it with the cross (do the tutorial).
func open_tutorial() -> void:
	await open_prompt()
	await tap("ui_accept")
	await frames(6)


## Map 1 with the tutorial skipped (the circle): he stands on the dining room's first table.
func open_dining() -> void:
	await open_prompt()
	Input.action_press("ui_cancel")
	await frames(2)
	Input.action_release("ui_cancel")
	await until(func() -> bool: return flow.phase == MapFlowScript.Phase.IDLE and on_top_of("dining_1"), 240)
	await frames(10)


func plat(id: String) -> LayoutGeometryScript.Placed:
	return LayoutGeometryScript.find(flow.placed, id)


func put_on(id: String, along: float, lift: float = 0.4) -> void:
	var p: LayoutGeometryScript.Placed = plat(id)
	teleport(LayoutGeometryScript.x_on(p, along), p.top + lift)
	await until(func() -> bool: return player.get("grounded"), 90)


func feet_y() -> float:
	return player.global_position.y - player.get("body_half_height")


func on_top_of(id: String) -> bool:
	var p: LayoutGeometryScript.Placed = plat(id)
	return player.get("grounded") and player.global_position.x >= p.left and player.global_position.x <= p.right \
		and absf(feet_y() - p.top) < 0.15


func clear_enemies() -> void:
	for node: Node in tree.get_nodes_in_group("enemies"):
		if is_instance_valid(node) and node.get("alive"):
			node.call("debug_defeat")


func hazards_off(kinds: Array[String]) -> void:
	for node: Node in tree.get_nodes_in_group("hazards"):
		var file: String = (node.get_script() as Script).resource_path.get_file()
		if kinds.has(file) or file == "falling_zone.gd": # the falling items only ever have their own tests
			node.call("set_enabled", false)


func hazards_of(file: String) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for node: Node in tree.get_nodes_in_group("hazards"):
		if (node.get_script() as Script).resource_path.get_file() == file:
			out.append(node as Node3D)
	return out


func slices() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for node: Node in tree.get_nodes_in_group("enemies"):
		if (node.get_script() as Script).resource_path.get_file() == "gimbap_slice.gd":
			out.append(node as Node3D)
	return out


## Everything but one train is taken away and the hazards are off. The train keeps marching.
func isolate_train() -> Node3D:
	var all: Array[Node3D] = slices()
	var train: Node3D = all[0].get("train")
	for node: Node in tree.get_nodes_in_group("enemies"):
		var keep: bool = node in all and node.get("train") == train
		if not keep and node.get("alive"):
			node.call("debug_defeat")
	hazards_off(["chopsticks.gd", "giant_foot.gd", "gum_patch.gd"])
	return train
