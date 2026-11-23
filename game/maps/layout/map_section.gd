extends Resource
## One stretch of the map, as data: its platforms, enemies, checkpoints and hints.

const PlatformDefScript := preload("res://maps/layout/platform_def.gd")
const SpawnEntryScript := preload("res://maps/layout/spawn_entry.gd")
const CheckpointDefScript := preload("res://maps/layout/checkpoint_def.gd")
const PromptTriggerScript := preload("res://maps/layout/prompt_trigger.gd")
const JjigiPlacementScript := preload("res://maps/layout/jjigi_placement.gd")

@export var id: String = ""
## Built and run by other code (the prologue): nothing to build from here.
@export var external: bool = false
@export var platforms: Array[PlatformDefScript] = []
@export var spawns: Array[SpawnEntryScript] = []
@export var checkpoints: Array[CheckpointDefScript] = []
## The 찜기 standing in this section (each gives one heal and save, once).
@export var jjigi: Array[JjigiPlacementScript] = []
@export var triggers: Array[PromptTriggerScript] = []
## Tutorial skipping: the skills granted, and the toast shown.
@export var skip_grants: PackedStringArray = PackedStringArray()
@export var skip_source: String = "tutorial"
@export var skip_toast: String = ""
## Where the skip takes him: a checkpoint id (of a later section).
@export var skip_to_checkpoint: String = ""
## A solid wall after the last platform, with this text on it (dev note: the map goes on here).
@export var end_wall_text: String = ""
