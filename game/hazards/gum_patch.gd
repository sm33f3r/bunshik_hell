extends Area3D
## A gum patch on the floor (Roster: the floor lane). Touching it sticks him (the `stick` status,
## data/hazards/gum.tres): no walking, no jumping, until he wiggles free, enemy hits shake him loose,
## or the fallback timer runs out. Contact is not damage. Jumping over it avoids it. When he gets free
## the patch is used up for `rearm_s` (the simpler of the two options in the task: consumed, not weaker).
## `tick(delta)` is the whole logic; tests drive it without a scene.

const Layers := preload("res://systems/layers.gd")
const StickDefScript := preload("res://hazards/stick_def.gd")
const PrologueSetScript := preload("res://prologue/prologue_set.gd")
const WorldScaleScript := preload("res://systems/world_scale.gd")

const COLOR: Color = Color(0.95, 0.5, 0.7, 0.85)
const USED_COLOR: Color = Color(0.7, 0.55, 0.6, 0.3)
## The touch box: this tall above the floor (jumping over it keeps him out).
const TOUCH_HEIGHT_M: float = 0.35

@export var def: StickDefScript
## Width of the patch in game metres (a spawn's size_cm sets it).
@export var width_m: float = 2.5
@export var m_per_cm: float = -1.0
## false: inert (tests, the floor-lane run).
@export var enabled: bool = true

## Ready to stick him.
var armed: bool = true
## He is stuck on this patch right now.
var holding: bool = false
var rearm_left: float = 0.0
var target_player: Node3D = null

var _mesh: MeshInstance3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER
	add_to_group("hazards")
	add_to_group("gum_patches")
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(width_m, TOUCH_HEIGHT_M, 1.2)
	shape.shape = box
	shape.position = Vector3(0.0, TOUCH_HEIGHT_M * 0.5, 0.0)
	add_child(shape)
	_mesh = PrologueSetScript.add_mesh(self, "Mesh", PrologueSetScript.box_mesh(Vector3(width_m, 0.12, 1.0)), COLOR, Vector3(0.0, 0.06, 0.0))


func set_enabled(on: bool) -> void:
	enabled = on
	monitoring = on
	if _mesh != null:
		_mesh.visible = on


func _physics_process(delta: float) -> void:
	tick(delta)


## One tick: stick him if he touches an armed patch; notice when he got free; re-arm after a while.
func tick(delta: float) -> void:
	if not enabled or def == null:
		return
	var player: Node3D = _touching_player()
	if holding:
		if target_player == null or not is_instance_valid(target_player) or not bool(target_player.call("is_stuck_by", self)):
			holding = false
			armed = false
			rearm_left = def.rearm_s
			_show_state()
		return
	if not armed:
		rearm_left -= delta
		if rearm_left <= 0.0:
			armed = true
			_show_state()
		return
	if player != null and bool(player.call("apply_stick", def, self)):
		holding = true
		target_player = player


## The 떡 if he is in the patch. (Without a scene, tests say who is in it through target_player.)
func _touching_player() -> Node3D:
	if is_inside_tree():
		for body: Node3D in get_overlapping_bodies():
			if body.is_in_group("player"):
				return body
		return null
	return target_player if (target_player != null and is_instance_valid(target_player)) else null


func _show_state() -> void:
	if _mesh == null:
		return
	var material: StandardMaterial3D = PrologueSetScript.material(COLOR if armed else USED_COLOR)
	_mesh.material_override = material
