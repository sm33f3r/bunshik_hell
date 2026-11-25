extends Resource
## A whole map's layout as data: its sections, in the order he goes through them.

const MapSectionScript := preload("res://maps/layout/map_section.gd")

@export var sections: Array[MapSectionScript] = []
## Hints stay up this long unless a trigger says otherwise, the prompt text, the fade times.
@export var prompt_accept_text: String = "튜토리얼 하기"
@export var prompt_cancel_text: String = "건너뛰기"
@export var fade_out_s: float = 0.35
@export var fade_in_s: float = 0.35
## Fallen this far below the lowest top of the map he is put back at the checkpoint (no damage).
@export var fall_depth_m: float = 4.0
## Validation: a chair step under a table needs this much room between its top and the table's
## underside, and every point of a floor lane must be within this many metres of a way back up.
@export var headroom_m: float = 0.9
@export var climb_spacing_max_m: float = 60.0
## Validation: no spot of a spawn choice may be nearer than this (along x) to a 정수기's spout.
@export var spout_clearance_m: float = 10.0


## The fixture placed with this id; null when there is none.
func find_fixture(fixture_id: String) -> Resource:
	for s: MapSectionScript in sections:
		for f: Resource in s.fixtures:
			if f.id == fixture_id:
				return f
	return null


func section(section_id: String) -> MapSectionScript:
	for s: MapSectionScript in sections:
		if s.id == section_id:
			return s
	return null


## The checkpoint with this id and the section it belongs to; null when there is none.
func find_checkpoint(checkpoint_id: String) -> Resource:
	for s: MapSectionScript in sections:
		for c: Resource in s.checkpoints:
			if c.id == checkpoint_id:
				return c
	return null


## The 찜기 placed with this id; null when there is none.
func find_jjigi(jjigi_id: String) -> Resource:
	for s: MapSectionScript in sections:
		for j: Resource in s.jjigi:
			if j.id == jjigi_id:
				return j
	return null


## The section a respawn point (a checkpoint id or a 찜기 id) belongs to; null for neither.
func section_of_respawn(point_id: String) -> MapSectionScript:
	for s: MapSectionScript in sections:
		for j: Resource in s.jjigi:
			if j.id == point_id:
				return s
	return section_of_checkpoint(point_id)


func section_of_checkpoint(checkpoint_id: String) -> MapSectionScript:
	for s: MapSectionScript in sections:
		for c: Resource in s.checkpoints:
			if c.id == checkpoint_id:
				return s
	return null
