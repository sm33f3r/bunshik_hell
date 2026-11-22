extends Node3D
## Her mouth, gray box: lips and teeth (upper and lower jaw) that slide into view at the top of the
## screen while the pick is lifted to her mouth, then close on him (the chomp). Her face is never
## drawn. Origin = the middle of the mouth opening. The lips are as wide as the real mouth (5 cm).

const PrologueSetScript := preload("res://prologue/prologue_set.gd")

const LIP_COLOR: Color = Color(0.78, 0.25, 0.28)
const TOOTH_COLOR: Color = Color(0.97, 0.96, 0.9)
const INSIDE_COLOR: Color = Color(0.25, 0.04, 0.06)
const LIP_THICKNESS_FRACTION: float = 0.17
const TEETH: int = 6

var width_m: float = 0.0
var open_gap_m: float = 0.0
var lip_radius_m: float = 0.0
var _upper: Node3D
var _lower: Node3D


func build(p_width_m: float, p_open_gap_m: float) -> void:
	width_m = p_width_m
	open_gap_m = p_open_gap_m
	lip_radius_m = width_m * LIP_THICKNESS_FRACTION
	var inside: MeshInstance3D = PrologueSetScript.add_mesh(self, "Inside",
		PrologueSetScript.box_mesh(Vector3(width_m * 0.9, open_gap_m + lip_radius_m, 0.2)), INSIDE_COLOR, Vector3(0.0, 0.0, -1.0))
	inside.name = "Inside"
	_upper = _jaw("UpperJaw", 1.0)
	_lower = _jaw("LowerJaw", -1.0)
	set_open(1.0)


## sign +1: upper jaw (lip above, teeth hang down); -1: lower jaw.
func _jaw(jaw_name: String, sign_y: float) -> Node3D:
	var jaw: Node3D = Node3D.new()
	jaw.name = jaw_name
	add_child(jaw)
	var lip_mesh: CapsuleMesh = CapsuleMesh.new()
	lip_mesh.radius = lip_radius_m
	lip_mesh.height = width_m # lying along x: the lips are exactly as wide as the mouth
	var lip: MeshInstance3D = PrologueSetScript.add_mesh(jaw, "Lip", lip_mesh, LIP_COLOR, Vector3(0.0, sign_y * lip_radius_m, 0.0))
	lip.rotation.z = PI * 0.5
	var teeth: Node3D = Node3D.new()
	teeth.name = "Teeth"
	jaw.add_child(teeth)
	var tooth_w: float = width_m * 0.78 / float(TEETH)
	for i: int in TEETH:
		var u: float = (float(i) + 0.5) / float(TEETH) - 0.5
		PrologueSetScript.add_mesh(teeth, "Tooth%d" % i,
			PrologueSetScript.box_mesh(Vector3(tooth_w * 0.9, lip_radius_m * 1.4, lip_radius_m * 0.9)), TOOTH_COLOR,
			Vector3(u * width_m * 0.78, -sign_y * lip_radius_m * 0.55, 0.0))
	return jaw


## 1 = fully open, 0 = shut. The jaws meet in the middle.
func set_open(amount: float) -> void:
	var half: float = open_gap_m * 0.5 * clampf(amount, 0.0, 1.0)
	if _upper != null:
		_upper.position.y = half + lip_radius_m * 0.6
		_lower.position.y = -half - lip_radius_m * 0.6


## The distance between the two sets of teeth, in metres.
func gap_m() -> float:
	return _upper.position.y - _lower.position.y if _upper != null else 0.0


## How wide the lips are, from the meshes (not from the number that was asked for).
func measured_width_m() -> float:
	var skip: Array[String] = ["Teeth"]
	return PrologueSetScript.mesh_size(_upper, skip).x
