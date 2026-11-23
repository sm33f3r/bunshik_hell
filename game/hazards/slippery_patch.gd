extends Area3D
## A slippery patch on the floor (what a spilled 김밥 leaves). While he stands in it his ground
## acceleration and braking drop (MovementTuning slip_*), and the effect lingers a moment after he
## leaves. It dries up after `lifetime_s`. Built from code: see make().

const Layers := preload("res://systems/layers.gd")
const PrologueSetScript := preload("res://prologue/prologue_set.gd")

const COLOR: Color = Color(0.55, 0.75, 0.35, 0.55)
## Height of the touch box above the floor (metres): standing in it, not jumping over it.
const TOUCH_HEIGHT_M: float = 0.5

var width_m: float = 2.0
var lifetime_s: float = 6.0
var linger_s: float = 0.25
var age: float = 0.0


## A patch of this width and life at `feet` (the floor under it), added to `parent`.
static func make(parent: Node, feet: Vector3, p_width_m: float, p_lifetime_s: float, p_linger_s: float) -> Area3D:
	var patch: Area3D = (load("res://hazards/slippery_patch.gd") as GDScript).new() as Area3D
	patch.set("width_m", p_width_m)
	patch.set("lifetime_s", p_lifetime_s)
	patch.set("linger_s", p_linger_s)
	patch.name = "SlipperyPatch"
	parent.add_child(patch)
	patch.global_position = feet
	return patch


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER
	monitoring = true
	add_to_group("slippery_patches")
	add_to_group("section_decor")
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(width_m, TOUCH_HEIGHT_M, 1.2)
	shape.shape = box
	shape.position = Vector3(0.0, TOUCH_HEIGHT_M * 0.5, 0.0)
	add_child(shape)
	PrologueSetScript.add_mesh(self, "Mesh", PrologueSetScript.box_mesh(Vector3(width_m, 0.05, 1.0)), COLOR, Vector3(0.0, 0.03, 0.0))


func _physics_process(delta: float) -> void:
	age += delta
	if age >= lifetime_s:
		queue_free()
		return
	for body: Node3D in get_overlapping_bodies():
		if body.has_method("apply_slip"):
			body.call("apply_slip", linger_s)
