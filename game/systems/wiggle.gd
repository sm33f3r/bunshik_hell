extends RefCounted
## Counts left/right alternations: the squirm that gets him off a pick, a pair of chopsticks, gum. The
## rule is the prologue's (PrologueDirector.wiggle_press): every press in a different direction than
## the one before counts, the first press counts too. No time limit here: whoever owns the wiggle
## decides what a slow player gets (the chopsticks let go, the gum times out).

## Alternations needed to be free.
var required: int = 1
var count: int = 0
var last_dir: int = 0


func _init(p_required: int = 1) -> void:
	required = maxi(p_required, 1)


## dir: -1 left, +1 right. Returns true once enough alternations were made.
func press(dir: int) -> bool:
	if dir == 0:
		return done()
	if dir != last_dir:
		last_dir = dir
		count += 1
	return done()


func done() -> bool:
	return count >= required


func progress() -> float:
	return clampf(float(count) / float(required), 0.0, 1.0)


func reset() -> void:
	count = 0
	last_dir = 0
