extends Resource
## One thing a section puts on a platform: an enemy, a hazard zone, a pickup.

const SpawnCandidateScript := preload("res://maps/layout/spawn_candidate.gd")

@export var platform_id: String = ""
## The scene (our own content, so it may be referenced directly).
@export var scene: PackedScene
## Metres from the platform's left edge. Negative: from its right edge.
@export var along_m: float = 2.0
## "" = along_m is on platform_id, the usual way. Else along_m is metres from the RIGHT end of this
## platform, or from the middle of this fixture (negative: back from it). platform_id still says what it
## stands on. See LayoutGeometry.item_x.
@export var from_id: String = ""
## Real centimetres; 0 = the thing's own size (the 단무지 sizes itself from its EnemyDef). For a
## hazard zone it is the width of the zone.
@export var size_cm: float = 0.0
@export var start_dir: float = 1.0
## Properties set on the node after it is created (e.g. {"speed_scale": 0.0}).
@export var params: Dictionary = {}
## Free text: which beat or lane the entry belongs to, for tests and the debug HUD.
@export var group: String = ""

@export_group("Respawn")
## The way on needs this thing (a 단무지 he bounces on or climbs). It always comes back at its start
## spot after respawn_delay_s when it is no use any more: dead, taken away, fallen off, or knocked flat
## where a flat one is no use (see below); and at once when he steps onto its platform again. A flat one
## he is standing on stays until he steps off. The soft-lock check (ProgressGraph) fails the tests if a
## thing the way on depends on is not marked, so a wasted one can never block him. It implies the
## respawn below (respawn_when_out_of_reach does not also have to be set).
@export var required_for_progress: bool = false
## If it ends up out of reach (see below) for respawn_delay_s it is put back as it started. It is
## also put back at once when he steps onto its platform again. false = never.
@export var respawn_when_out_of_reach: bool = false
@export var respawn_delay_s: float = 4.0
## A required thing that is knocked over (flat): true = a flat one is a platform that stays until he has
## left the beat (the useful stretch below says where it has to lie); false = a flat one is spent, it
## springs back upright after respawn_delay_s (a bounce source: rolling it must not cost him the bounce).
@export var usable_when_flat: bool = true
## Out of reach: it fell this far below its platform's top ...
@export var out_below_m: float = 1.5
## ... or it is knocked over (flat) anywhere outside this stretch of its platform (metres along it,
## negative from its right edge). Both 0 = any flat position is fine. (For a wheel with usable_when_flat
## false it is the stretch where its flat body would be a step: the soft-lock check uses that.)
@export var useful_from_m: float = 0.0
@export var useful_to_m: float = 0.0

@export_group("Spawn choice")
## A "spawn choice": instead of one fixed spot (platform_id / along_m above) the thing has several candidate
## spots and ONE is picked per new game, from the game's seed (GameState.spawn_pick). The pick is saved,
## so reloads and respawns keep the spot; a new game picks again. `choice_id` names the choice.
@export var choice_id: String = ""
@export var candidates: Array[SpawnCandidateScript] = []
## The thing's footprint for the layout checks of a choice (real cm): it must fit every candidate spot and
## be one he can hop over. A test keeps these equal to the thing's own def.
@export var choice_width_cm: float = 0.0
@export var choice_height_cm: float = 0.0


func has_choice() -> bool:
	return choice_id != "" and not candidates.is_empty()


func candidate_ids() -> Array[String]:
	var out: Array[String] = []
	for c: SpawnCandidateScript in candidates:
		out.append(c.id)
	return out


func candidate(spot_id: String) -> SpawnCandidateScript:
	for c: SpawnCandidateScript in candidates:
		if c.id == spot_id:
			return c
	return null


## This entry with the spot `spot_id` filled in (a copy: the data entry itself is never changed). An entry
## without a choice, or an unknown spot, comes back as it is.
func resolved(spot_id: String) -> Resource:
	var c: SpawnCandidateScript = candidate(spot_id)
	if c == null:
		return self
	var copy: Resource = duplicate()
	copy.platform_id = c.platform_id
	copy.along_m = c.along_m
	copy.from_id = c.from_id
	return copy
