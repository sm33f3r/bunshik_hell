extends Resource
## One anger stage of the woman. `first_stab` is the number of the first stab that belongs to
## the stage (1, 8, 16, 24). Telegraph and gap lengths shorten as the stages go up.

@export var first_stab: int = 1
## Base telegraph length of a normal stab (seconds). Never goes below PrologueData.min_telegraph_s.
@export var telegraph_s: float = 1.0
## Pause between two patterns, rolled between these (seconds).
@export var gap_min_s: float = 1.0
@export var gap_max_s: float = 1.5
