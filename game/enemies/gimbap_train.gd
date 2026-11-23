extends Node3D
## 김밥 slice train: a line of slices led by the uncut end piece (꼬다리), marching along a table.
## The train builds its slices (each its own small enemy body, enemies/gimbap_slice.gd) and drives
## them: the leader walks and turns at edges and walls, every other slice follows the path the leader
## walked (so the line bends around a turn like a snake and nobody walks off an edge early). A roll
## breaks the line: from then on every slice walks on its own. Numbers: data/enemies/gimbap.tres.
## Deferred: the uncut charging roll variant (Roster §5: an uncut roll charges in a straight line).

signal line_broken
## Every slice is gone.
signal cleared

const SliceScene: PackedScene = preload("res://enemies/gimbap_slice.tscn")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")
const WorldScaleScript := preload("res://systems/world_scale.gd")
## A follower may close up on its place on the trail this much faster than the leader walks.
const CATCH_UP: float = 2.0
## The trail keeps a point every time the leader walked this far (metres).
const TRAIL_STEP_M: float = 0.05

@export var def: EnemyDefScript
@export var start_dir: float = 1.0
## Game metres per real centimetre; -1 = read the world scale data.
@export var m_per_cm: float = -1.0
@export var speed_scale: float = 1.0
## 0 = the number in the EnemyDef.
@export var slice_count: int = 0

## The slices still in the line, leader first.
var slices: Array[Node3D] = []
var broken: bool = false
var spacing_m: float = 0.0
var leader_dir: float = 1.0

var _trail_path: Array[float] = []
var _trail_x: Array[float] = []
var _path: float = 0.0
var _last_x: float = 0.0
var _trail_ready: bool = false


func _ready() -> void:
	add_to_group("gimbap_trains")
	leader_dir = start_dir
	build()


## Makes the slices (call once; _ready does).
func build() -> void:
	if def == null or not slices.is_empty():
		return
	var scale_m: float = m_per_cm if m_per_cm > 0.0 else _world_m_per_cm()
	spacing_m = (def.slice_size_cm + def.slice_gap_cm) * scale_m
	var count: int = slice_count if slice_count > 0 else def.train_slices
	for i: int in count:
		var slice: Node3D = SliceScene.instantiate() as Node3D
		slice.name = "Slice%d" % i
		slice.set("m_per_cm", scale_m)
		slice.set("speed_scale", speed_scale)
		slice.set("start_dir", start_dir)
		slice.set("is_end_piece", i == 0)
		slice.set("slice_index", i)
		slice.set("train", self)
		slice.position = Vector3(-start_dir * float(i) * spacing_m, 0.0, 0.0)
		add_child(slice)
		slices.append(slice)


func _world_m_per_cm() -> float:
	var world: Resource = WorldScaleScript.load_default()
	return (world as WorldScaleScript).game_m_per_real_cm() if world != null else 0.1745


## The slices that are still alive, leader first.
func living() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for slice: Node3D in slices:
		if is_instance_valid(slice) and bool(slice.get("alive")):
			out.append(slice)
	return out


func leader() -> Node3D:
	var alive: Array[Node3D] = living()
	return alive[0] if not alive.is_empty() else null


## Called by a slice every physics tick while it is in the line (before it moves).
func drive(slice: Node3D, delta: float) -> void:
	var alive: Array[Node3D] = living()
	if alive.is_empty():
		return
	if not _trail_ready:
		_start_trail(alive)
	var speed: float = (def.walk_speed_mps if def != null else 0.0) * float(slice.call("speed_factor")) * speed_scale
	if slice == alive[0]:
		if slice.is_on_wall() and signf(slice.get_wall_normal().x) == -leader_dir:
			leader_dir = -leader_dir
		elif slice.is_on_floor() and bool(slice.call("edge_ahead", leader_dir)):
			leader_dir = -leader_dir
		slice.velocity.x = leader_dir * speed
		_record(slice)
		return
	var index: int = alive.find(slice)
	var want_x: float = _trail_x_at(_path - float(index) * spacing_m)
	var step: float = (want_x - slice.global_position.x) / maxf(delta, 0.0001)
	slice.velocity.x = clampf(step, -speed * CATCH_UP, speed * CATCH_UP)


func _start_trail(alive: Array[Node3D]) -> void:
	_trail_ready = true
	var x0: float = alive[0].global_position.x
	var behind: float = float(alive.size()) * spacing_m
	_trail_path = [-behind, 0.0]
	_trail_x = [x0 - leader_dir * behind, x0]
	_path = 0.0
	_last_x = x0


func _record(head: Node3D) -> void:
	var x: float = head.global_position.x
	var moved: float = absf(x - _last_x)
	if moved < TRAIL_STEP_M:
		return
	_path += moved
	_last_x = x
	_trail_path.append(_path)
	_trail_x.append(x)
	# Forget what no slice can still be standing on.
	var oldest: float = _path - float(slices.size() + 1) * spacing_m
	while _trail_path.size() > 2 and _trail_path[1] < oldest:
		_trail_path.remove_at(0)
		_trail_x.remove_at(0)


## Where the path was `s` metres along it (clamped to what is known).
func _trail_x_at(s: float) -> float:
	if s <= _trail_path[0]:
		return _trail_x[0]
	for i: int in range(1, _trail_path.size()):
		if s <= _trail_path[i]:
			var span: float = _trail_path[i] - _trail_path[i - 1]
			var t: float = (s - _trail_path[i - 1]) / span if span > 0.0 else 1.0
			return lerpf(_trail_x[i - 1], _trail_x[i], t)
	return _trail_x[_trail_x.size() - 1]


## A roll: the line breaks and every slice walks on its own, hopping apart (alternating directions
## away from where it was hit).
func break_line(hit_dir: float) -> void:
	if broken:
		return
	broken = true
	var side: float = hit_dir if hit_dir != 0.0 else leader_dir
	var i: int = 0
	for slice: Node3D in living():
		slice.call("scatter", side if i % 2 == 0 else -side)
		i += 1
	line_broken.emit()


## A slice of the line died: the line closes up (and, if it was the head, the next slice leads).
func slice_died(slice: Node3D) -> void:
	var was_head: bool = not slices.is_empty() and slices[0] == slice
	slices.erase(slice)
	if was_head and not broken and not slices.is_empty():
		_trail_ready = false
	if slices.is_empty():
		cleared.emit()
