extends Resource
## One way the woman can stab. Patterns are picked at random with `weights` (one per anger
## stage). `kind` is one of: small, big, burst, hover, fake, drag, mandu.

@export var id: String = ""
@export var kind: String = "small"
## Odds per anger stage 0..3. Not normalised; 0 means "never in this stage".
@export var weights: PackedFloat32Array = PackedFloat32Array([1.0, 1.0, 1.0, 1.0])
## burst: how many quick small stabs (inclusive range).
@export var count_min: int = 1
@export var count_max: int = 1
## hover: how long she hesitates before the stab telegraph starts counting down (seconds).
@export var hover_min_s: float = 0.0
@export var hover_max_s: float = 0.0
## mandu: how long she pauses to eat afterwards (seconds).
@export var pause_min_s: float = 0.0
@export var pause_max_s: float = 0.0
## drag: how far (m) and how long (s) the pick drags along the tabletop.
@export var drag_length_m: float = 3.0
@export var drag_s: float = 1.4


func weight_for(stage: int) -> float:
	if weights.is_empty():
		return 0.0
	return weights[clampi(stage, 0, weights.size() - 1)]


## The fewest counted stabs this pattern can add (fake-outs and 만두 breaks add none).
func min_stabs() -> int:
	match kind:
		"fake", "mandu":
			return 0
		"burst":
			return maxi(count_min, 1)
		_:
			return 1
