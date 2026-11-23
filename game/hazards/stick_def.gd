extends Resource
## The `stick` status as data (gum now; 쫀드기 and cheese later): how he gets free again. Stuck: he
## cannot walk, jump or roll. Data: data/hazards/gum.tres.

## Left/right alternations of the wiggle (slow: a lot of them).
@export var wiggle_required: int = 14
## Enemy hits on him that free him (each one counts; they still hurt).
@export var enemy_hits_required: int = 3
## Fallback: he is freed after this long whatever he does.
@export var timeout_s: float = 10.0
## After he got free, the patch that stuck him is used up for this long.
@export var rearm_s: float = 3.0
