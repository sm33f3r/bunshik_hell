extends Resource
## One 찜기 placed on a platform of a section, as data. The id is unique and stable for the whole
## game: it is what the save remembers as "used" (e.g. "map01_dining_mid").

const JjigiDefScript := preload("res://items/jjigi_def.gd")

@export var id: String = ""
@export var def: JjigiDefScript
@export var platform_id: String = ""
## Metres from the platform's left edge to the 찜기's middle, and how high above its top it stands.
@export var along_m: float = 2.0
@export var lift_m: float = 0.0
