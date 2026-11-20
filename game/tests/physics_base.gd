extends "res://tests/base_test.gd"
## Base for real-room physics suites. Each test loads a FRESH copy of the test room into the
## running SceneTree, simulates input actions and waits on physics frames.
##
## Not an isolated unit: the room's nodes look up the GameState autoload by path, so the
## autoload is reset() to defaults before each test and the room is freed after it.
## Every wait is counted in physics frames, which are always exactly 1/60 s of game time.
## (Headless runs are not paced to real time, so no time-scale tricks are needed.)

const ROOM_SCENE := "res://maps/test/test_room.tscn"
const GameplayInputScript := preload("res://systems/gameplay_input.gd")

var room: Node3D
var player: CharacterBody3D
var gs: Node
var soft_floor: Node3D
var soft_ledge: Node3D
var tall: Node3D


func open_room() -> void:
	gs = tree.root.get_node_or_null("GameState")
	if gs == null:
		failures.append("GameState autoload missing")
		return
	gs.call("reset")
	room = (load(ROOM_SCENE) as PackedScene).instantiate() as Node3D
	tree.root.add_child(room)
	player = room.get_node("Player") as CharacterBody3D
	soft_floor = room.get_node("Dummies/SoftDummyFloor") as Node3D
	soft_ledge = room.get_node("Dummies/SoftDummy") as Node3D
	tall = room.get_node("Dummies/TallRigidDummy") as Node3D
	await frames(40) # spawn and settle on the floor


func after_each() -> void:
	for action: String in ["move_left", "move_right", "jump", "look_up", "look_down", "roll", "sauce_attack", "special", "sauce_next", "sauce_prev", "heal", "inventory", "drop_item", "ui_accept", "ui_cancel"]:
		Input.action_release(action)
	tree.paused = false # a test may end with the inventory screen or a popup open
	GameplayInputScript.clear()
	if room != null:
		room.queue_free()
		await tree.process_frame
		room = null
	player = null


func frames(n: int) -> void:
	for i: int in n:
		await tree.physics_frame


## Waits up to max_frames for cond to become true. Returns whether it did.
func until(cond: Callable, max_frames: int) -> bool:
	for i: int in max_frames:
		if cond.call():
			return true
		await tree.physics_frame
	return cond.call()


## Tap an action for two physics frames.
func tap(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)


func teleport(x: float, y: float) -> void:
	player.global_position = Vector3(x, y, 0.0)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()


## Freeze a dummy where it is so it does not patrol into the test.
func park(enemy: Node3D, x: float) -> void:
	enemy.set_physics_process(false)
	enemy.global_position = Vector3(x, 0.0, 0.0)


func state() -> String:
	return player.call("state_name")


func describe() -> String:
	return "state=%s pos=(%.2f,%.2f) vel=(%.2f,%.2f) hearts=%d" % [
		state(), player.global_position.x, player.global_position.y,
		player.velocity.x, player.velocity.y, gs.hearts]


## Hold a jump for `hold` frames (0 = a tap) and return the peak height above the start.
func jump_peak(hold_frames: int) -> float:
	park(soft_floor, -30.0)
	park(tall, -30.0)
	teleport(-2.0, 0.33)
	await frames(30)
	var base: float = player.global_position.y
	var peak: float = base
	Input.action_press("jump")
	for i: int in 70:
		await tree.physics_frame
		if i == hold_frames:
			Input.action_release("jump")
		peak = maxf(peak, player.global_position.y)
	Input.action_release("jump")
	await frames(40)
	return peak - base


func key_event(physical: Key) -> void:
	var e: InputEventKey = InputEventKey.new()
	e.physical_keycode = physical
	e.keycode = physical
	e.pressed = true
	Input.parse_input_event(e)
	await frames(2)


## A dummy from the room's Dummies node by name (e.g. "FriedSmall").
func dummy(node_name: String) -> Node3D:
	return room.get_node("Dummies/" + node_name) as Node3D


## Sauce flicks currently flying in the room.
func flicks() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for child: Node in room.get_children():
		var script: Script = child.get_script() as Script
		if script != null and script.resource_path == "res://projectiles/sauce_flick.gd":
			out.append(child as Node3D)
	return out
