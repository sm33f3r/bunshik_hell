extends Node3D
## 찜기 placeholder. Press look_up (W) while overlapping its zone: full heal and this
## becomes the checkpoint. Also used as the initial spawn point.

const GameStateScript := preload("res://systems/game_state.gd")
const Layers := preload("res://systems/layers.gd")

@export var steamer_id: String = ""
## Where the 떡 appears on respawn, relative to this node.
@export var spawn_offset: Vector3 = Vector3(1.6, 0.5, 0.0)
@export var feedback_time: float = 0.7
@export var idle_glow: float = 0.3
@export var active_glow: float = 1.6

var game_state: GameStateScript

var _zone: Area3D
var _top_material: StandardMaterial3D
var _puff: MeshInstance3D
var _puff_material: StandardMaterial3D
var _prompt: Label3D
var _tween: Tween


func _ready() -> void:
	_zone = get_node_or_null("UseZone") as Area3D
	if _zone != null:
		_zone.collision_layer = 0
		_zone.collision_mask = Layers.PLAYER
	_prompt = get_node_or_null("Prompt") as Label3D
	_puff = get_node_or_null("Puff") as MeshInstance3D
	if _puff != null and _puff.material_override is StandardMaterial3D:
		_puff_material = (_puff.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		_puff.material_override = _puff_material
		_puff.visible = false
	var top: MeshInstance3D = get_node_or_null("SteamTop") as MeshInstance3D
	if top != null and top.material_override is StandardMaterial3D:
		_top_material = (top.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		top.material_override = _top_material
	if game_state == null:
		game_state = get_node_or_null("/root/GameState") as GameStateScript
	if game_state != null:
		game_state.checkpoint_changed.connect(_refresh_glow)
	_refresh_glow(game_state.checkpoint_id if game_state != null else "")


func _physics_process(_delta: float) -> void:
	if _zone == null or game_state == null:
		return
	var near: bool = false
	for body: Node3D in _zone.get_overlapping_bodies():
		if body.is_in_group("player"):
			near = true
			break
	if _prompt != null:
		_prompt.visible = near
	if near and Input.is_action_just_pressed("look_up"):
		activate(game_state)


func spawn_point() -> Vector3:
	return (global_position if is_inside_tree() else position) + spawn_offset


## Full heal + checkpoint. False if refused (the 떡 is dead).
func activate(state: GameStateScript) -> bool:
	if not state.use_steamer(steamer_id, spawn_point()):
		return false
	_play_feedback()
	return true


func _refresh_glow(active_id: String) -> void:
	if _top_material == null:
		return
	_top_material.emission_enabled = true
	_top_material.emission_energy_multiplier = active_glow if active_id == steamer_id else idle_glow


func _play_feedback() -> void:
	if not is_inside_tree() or _puff == null or _puff_material == null:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_puff.visible = true
	_puff.scale = Vector3.ONE * 0.3
	_puff_material.albedo_color.a = 0.8
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_puff, "scale", Vector3.ONE * 1.8, feedback_time)
	_tween.tween_property(_puff_material, "albedo_color:a", 0.0, feedback_time)
	_tween.chain().tween_callback(func() -> void: _puff.visible = false)
