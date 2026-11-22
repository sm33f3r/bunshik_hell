extends Node3D
## Her hand, gray box: a palm and four fingers (capsules) gripping the top of the pick, a thumb on
## the far side, and the forearm going up off the top of the screen. Her face and body are never
## drawn. Origin = the tip of the pick (the hand is a child of the pick rig); y points up the pick.

const PrologueSetScript := preload("res://prologue/prologue_set.gd")

const SKIN: Color = Color(0.93, 0.76, 0.66)
## How far down from the top of the pick her fingertips reach (metres).
const GRIP_BELOW_TOP_M: float = 0.45
const FINGERS: int = 4

var hand_length_m: float = 0.0


## `pick_length_m` = how long the pick is; `hand_length_m` = fingertip to wrist (real: 19 cm).
func build(pick_length_m: float, p_hand_length_m: float) -> void:
	hand_length_m = p_hand_length_m
	var finger_len: float = hand_length_m * 0.45
	var palm_len: float = hand_length_m - finger_len
	var palm_radius: float = hand_length_m * 0.15
	var finger_radius: float = palm_radius * 0.26
	var tips_y: float = pick_length_m - GRIP_BELOW_TOP_M
	var fingers: Node3D = Node3D.new()
	fingers.name = "Fingers"
	add_child(fingers)
	for i: int in FINGERS:
		var u: float = (float(i) / float(FINGERS - 1)) - 0.5
		_capsule(fingers, "Finger%d" % i, finger_radius, finger_len,
			Vector3(u * palm_radius * 1.5, tips_y + finger_len * 0.5, palm_radius * 0.6))
	_capsule(self, "Palm", palm_radius, palm_len, Vector3(0.0, tips_y + finger_len + palm_len * 0.5, palm_radius * 0.2))
	# The thumb closes on the far side of the pick.
	_capsule(self, "Thumb", finger_radius * 1.1, finger_len * 0.8,
		Vector3(palm_radius * 0.5, tips_y + finger_len * 0.55, -palm_radius * 0.5))
	# The forearm runs up out of the picture.
	_capsule(self, "Forearm", palm_radius * 0.8, 14.0, Vector3(0.0, tips_y + hand_length_m + 6.0, palm_radius * 0.2))


func _capsule(parent: Node3D, capsule_name: String, radius: float, height: float, at: Vector3) -> MeshInstance3D:
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.0)
	return PrologueSetScript.add_mesh(parent, capsule_name, mesh, SKIN, at)


## Fingertip to the top of the palm, in metres (what the real 19 cm turned into).
func measured_length_m() -> float:
	var skip: Array[String] = ["Forearm", "Thumb"]
	return PrologueSetScript.mesh_size(self, skip).y
