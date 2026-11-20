extends Node3D
## A sheet of spilled water along the floor. Every enemy it touches gets attack "water" once
## (the reaction table decides what that does). Fades after `lifetime_s`.
## Origin: where the bottle stood, at floor level. It runs `length` metres toward `direction`.

const EnvQueryScript := preload("res://items/env_query.gd")

const ATTACK: String = "water"
## Height of the wet zone above the floor (a standing enemy's feet are inside it).
const SHEET_HEIGHT: float = 0.3
const SHEET_DEPTH: float = 2.0

var length: float = 3.0
## +1 spills to the right, -1 to the left.
var direction: float = 1.0
var lifetime_s: float = 4.0
## Ids of enemies already splashed (each is hit once per sheet).
var hit_ids: Array[int] = []
var age: float = 0.0


func setup(length_m: float, dir: float, lifetime: float) -> void:
	length = length_m
	direction = signf(dir) if dir != 0.0 else 1.0
	lifetime_s = lifetime


func _ready() -> void:
	add_to_group("water_sheets")
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(length, 0.05, 1.0)
	mesh.mesh = box
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.6, 1.0, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	mesh.position = Vector3(direction * length * 0.5, 0.03, 0.0)
	add_child(mesh)


func _physics_process(delta: float) -> void:
	step(delta)


## One tick: splash what it touches, then age. Public so tests can drive it.
func step(delta: float) -> void:
	if is_inside_tree():
		splash()
	age += delta
	if age >= lifetime_s and is_inside_tree():
		queue_free()


func box_center() -> Vector3:
	return global_position + Vector3(direction * length * 0.5, SHEET_HEIGHT * 0.5, 0.0)


## Hits every enemy in the wet zone that has not been splashed yet. Returns how many.
func splash() -> int:
	var count: int = 0
	var size: Vector3 = Vector3(length, SHEET_HEIGHT, SHEET_DEPTH)
	for enemy in EnvQueryScript.enemies_in_box(get_world_3d(), box_center(), size):
		var id: int = enemy.get_instance_id()
		if hit_ids.has(id):
			continue
		hit_ids.append(id)
		enemy.receive_attack(ATTACK, direction)
		count += 1
	return count
