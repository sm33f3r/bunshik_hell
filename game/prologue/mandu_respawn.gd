extends RefCounted
## Keeps her plate stocked: when the LAST live 만두 is gone (killed by the 떡 or eaten by her),
## `count` new ones appear after `delay_s`. Pure logic, no nodes: the Map 1 scene feeds it the
## live count every physics tick and spawns what it returns.

var count: int = 2
var delay_s: float = 1.5

var _timer: float = -1.0
var _had_live: bool = false


func _init(p_count: int = 2, p_delay_s: float = 1.5) -> void:
	count = p_count
	delay_s = p_delay_s


## Back to the start (a restart puts the full starting plate back).
func reset() -> void:
	_timer = -1.0
	_had_live = false


func waiting() -> bool:
	return _timer >= 0.0


## `live`: live 만두 right now. `active`: the stabbing is going on (not the cutscene, the wiggles,
## the eaten beat or after the exit opened). Returns how many to spawn this tick (usually 0).
func update(live: int, delta: float, active: bool) -> int:
	if live > 0:
		_had_live = true
		_timer = -1.0
		return 0
	if not active:
		_timer = -1.0
		return 0
	if _timer < 0.0:
		if not _had_live:
			return 0
		_timer = delay_s
		_had_live = false
	_timer -= delta
	if _timer > 0.0:
		return 0
	_timer = -1.0
	return count
