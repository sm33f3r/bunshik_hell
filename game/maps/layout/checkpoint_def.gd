extends Resource
## A checkpoint of a section: standing on `platform_id` reaches it. Dying (or falling) puts him
## back here with full hearts, and the sauce and 나트륨 he had when he got here.

@export var id: String = ""
@export var platform_id: String = ""
## Metres from the platform's left edge, and how high above its top he is put back.
@export var along_m: float = 2.0
@export var lift_m: float = 0.5
## Reaching this one counts as finishing the tutorial.
@export var finishes_tutorial: bool = false
