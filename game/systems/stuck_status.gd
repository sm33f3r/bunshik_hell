extends RefCounted
## The `stick` status on the 떡: three ways out. (a) wiggle left/right, (b) enemy hits on him,
## (c) the fallback timer. One of them sets `released` and `reason` ("wiggle" | "enemy_hits" |
## "timeout"). Pure logic: the player feeds it presses, hits and time.

const WiggleScript := preload("res://systems/wiggle.gd")
const StickDefScript := preload("res://hazards/stick_def.gd")

var def: StickDefScript
var wiggle: WiggleScript
var hits: int = 0
var time: float = 0.0
var released: bool = false
var reason: String = ""
## Who stuck him (a gum patch): it is used up when he gets free.
var source: Object = null


func _init(p_def: StickDefScript, p_source: Object = null) -> void:
	def = p_def
	source = p_source
	wiggle = WiggleScript.new(def.wiggle_required)


func press(dir: int) -> void:
	if released:
		return
	if wiggle.press(dir):
		_free("wiggle")


## One enemy hit on him.
func enemy_hit() -> void:
	if released:
		return
	hits += 1
	if hits >= def.enemy_hits_required:
		_free("enemy_hits")


func tick(delta: float) -> void:
	if released:
		return
	time += delta
	if time >= def.timeout_s:
		_free("timeout")


func _free(why: String) -> void:
	released = true
	reason = why
