extends Resource
## How big the world is around Ddeok Dude. His size, collision and movement never change; the
## world grows around him instead. A 떡볶이 떡 is about `real_ddeok_length_cm` long in real life,
## and he is `ddeok_length_m` long in the game, so one real centimetre is
## `game_m_per_real_cm = ddeok_length_m / real_ddeok_length_cm` game metres.
## Data: res://data/world_scale.tres.

const DDEOK_SCENE_PATH: String = "res://player/ddeok.tscn"
const DATA_PATH: String = "res://data/world_scale.tres"

## A real 떡볶이 떡 (starting value; tunable).
@export var real_ddeok_length_cm: float = 5.5

static var _measured_length_m: float = -1.0


## Ddeok Dude's length in game metres along X, read from his collision capsule in ddeok.tscn
## (he lies on his side, so the capsule's long axis points along X). Cached.
static func measure_ddeok_length_m() -> float:
	if _measured_length_m > 0.0:
		return _measured_length_m
	var scene: PackedScene = load(DDEOK_SCENE_PATH) as PackedScene
	if scene == null:
		return 0.0
	var root: Node = scene.instantiate()
	var body: CollisionShape3D = root.get_node_or_null("CollisionShape3D") as CollisionShape3D
	var length: float = 0.0
	if body != null:
		var capsule: CapsuleShape3D = body.shape as CapsuleShape3D
		if capsule != null:
			# The capsule is a segment of (height - 2 * radius) plus a sphere radius at both ends.
			var axis_x: float = absf(body.transform.basis.y.x)
			length = (capsule.height - 2.0 * capsule.radius) * axis_x + 2.0 * capsule.radius
	root.free()
	_measured_length_m = length
	return length


static func load_default() -> Resource:
	return load(DATA_PATH)


## Game metres per real centimetre.
func game_m_per_real_cm(ddeok_length_m: float = -1.0) -> float:
	var length: float = ddeok_length_m if ddeok_length_m > 0.0 else measure_ddeok_length_m()
	return length / maxf(real_ddeok_length_cm, 0.001)


func cm_to_m(cm: float, ddeok_length_m: float = -1.0) -> float:
	return cm * game_m_per_real_cm(ddeok_length_m)


func cm_to_m3(cm: Vector3, ddeok_length_m: float = -1.0) -> Vector3:
	return cm * game_m_per_real_cm(ddeok_length_m)
