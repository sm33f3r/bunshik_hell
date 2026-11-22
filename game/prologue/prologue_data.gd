extends Resource
## All numbers, shots, patterns, stages and lines of the Map 1 prologue (data/prologue/prologue.tres).
## The layout (x, y in game metres) is not stored: it is derived from the real-size table
## (prologue/set_dimensions.gd) times the world scale (systems/world_scale.gd), so the set the
## PrologueSet builds and the numbers the director uses can never drift apart.

const CutsceneShotScript := preload("res://prologue/cutscene_shot.gd")
const AngerStageScript := preload("res://prologue/anger_stage.gd")
const StabPatternScript := preload("res://prologue/stab_pattern.gd")
const PrologueLinesScript := preload("res://prologue/prologue_lines.gd")
const WorldScaleScript := preload("res://systems/world_scale.gd")
const SetDimensionsScript := preload("res://prologue/set_dimensions.gd")
const DIMENSIONS_PATH: String = "res://data/prologue/set_dimensions.tres"

@export_group("Content")
@export var shots: Array[CutsceneShotScript] = []
@export var stages: Array[AngerStageScript] = []
@export var patterns: Array[StabPatternScript] = []
@export var lines: PrologueLinesScript
## Left empty = the defaults (data/world_scale.tres and data/prologue/set_dimensions.tres).
@export var world_scale: WorldScaleScript
@export var dimensions: SetDimensionsScript

@export_group("Wiggle")
## Opening pick: alternations of left/right needed inside window_s (= the time the pick takes to rise).
@export var required_alternations: int = 10
@export var window_s: float = 3.0
## Same mechanic after a big stab lifts him.
@export var lift_required_alternations: int = 10
@export var lift_window_s: float = 3.0
## Height of the pick tip above the counter when it reaches her mouth (m).
@export var pick_final_height_m: float = 4.7

@export_group("Stabs")
@export var stab_target: int = 30
## Damage in half-hearts.
@export var small_damage: int = 1
@export var big_damage: int = 2
@export var min_telegraph_s: float = 0.4
@export var big_telegraph_mult: float = 1.25
@export var burst_telegraph_mult: float = 0.6
## The shadow follows the 떡 until this fraction of the telegraph, then locks.
@export_range(0.0, 1.0) var lock_fraction: float = 0.6
@export var aim_jitter_m: float = 0.3
@export var strike_s: float = 0.1
@export var hold_s: float = 0.35
@export var retract_s: float = 0.35
@export var burst_retract_s: float = 0.12
@export var fake_retract_s: float = 0.4
@export var small_half_width: float = 0.3
@export var big_half_width: float = 0.55
@export var drag_half_width: float = 0.3
## The drag only hurts a 떡 whose feet are lower than this above the counter.
@export var drag_height_m: float = 0.7
## Half the 떡's body length: a stab column hurts him if any part of him is inside it.
@export var player_half_width: float = 0.45
## Pause after he slides off the pick before the first telegraph.
@export var pre_stab_delay_s: float = 1.5
## Live 만두 on her plate at the start (and after every restart).
@export var plate_mandu_count: int = 3
## A 만두 is in a stab's column when its middle is closer than the column half width plus this.
@export var mandu_half_width_m: float = 0.45
## "Later in stage 1" line: said once the count reaches this (while still in stage 1).
@export var stage1_later_stab: int = 11

@export_group("Eaten")
@export var eaten_total_s: float = 2.6
@export var eaten_shake_s: float = 0.5
@export var eaten_blackout_s: float = 0.9
@export var game_over_text: String = "GAME OVER"

@export_group("Subtitles")
@export var line_duration_s: float = 3.0

@export_group("Reactions")
## What she says after an attempted stab (a burst gets one, after the burst). One at random, never
## the same twice in a row. Her own words: do not "fix" them.
@export var reactions: PackedStringArray = PackedStringArray()
## Seconds after the stab (or burst) is over before the reaction shows.
@export var reaction_delay_s: float = 0.35
## How long a reaction stays on screen.
@export var reaction_duration_s: float = 1.6

@export_group("Mandu respawn")
## When the last live 만두 is gone, this many appear on her plate after the delay.
@export var mandu_respawn_count: int = 2
@export var mandu_respawn_delay_s: float = 1.5

@export_group("Spear")
## How deep the pick goes into him, measured from his top. Never more than his thickness minus
## the margin, so no part of the pick shows out of the other side.
@export var spear_depth_m: float = 0.56
@export var spear_margin_m: float = 0.08
## He slides off the pick this far to the side (clear of the cup's rim).
@export var slide_off_m: float = 1.25

@export_group("Her mouth and forearm")
## The jaws close on him in this time (the chomp) at the start of the eaten beat.
@export var eaten_chomp_s: float = 0.3
## The lips slide into view from this fraction of the wiggle window on.
@export_range(0.0, 1.0) var mouth_appear_from: float = 0.3
@export var mouth_start_height_m: float = 12.0
## She yanks her forearm away in this time when the exit opens.
@export var forearm_yank_s: float = 0.4

@export_group("Camera and falling")
@export var pick_camera_height_m: float = 1.6
@export var pick_camera_dist_m: float = 9.0
## While he walks the counter the camera sits this far from him (the stock side camera is 2.5 up and
## 14 back): lower, so the counter is not under the subtitle box at the bottom of the screen.
@export var stab_camera_offset: Vector3 = Vector3(0.0, 1.4, 14.0)
@export var camera_near: float = 0.1
@export var camera_far: float = 600.0
## Fallen this far below the counter top, he is put back (the floor is a long way down).
@export var fall_catch_depth_m: float = 4.0
@export var fall_return_inset_m: float = 1.0


func scale_resource() -> WorldScaleScript:
	if world_scale == null:
		world_scale = WorldScaleScript.load_default() as WorldScaleScript
	return world_scale


func dims() -> SetDimensionsScript:
	if dimensions == null:
		dimensions = load(DIMENSIONS_PATH) as SetDimensionsScript
	return dimensions


## Game metres per real centimetre (see WorldScale).
func m_per_cm() -> float:
	return scale_resource().game_m_per_real_cm()


func cm(value: float) -> float:
	return value * m_per_cm()


# --- Layout in game metres (derived) -----------------------------------------------------------

var counter_top_y: float:
	get: return cm(dims().counter_top_height_cm)
var counter_length_m: float:
	get: return cm(dims().counter_length_cm)
var cup_x: float:
	get: return cm(dims().cup_x_cm)
var cup_top_y: float:
	get: return counter_top_y + cm(dims().cup_height_cm)
var plate_x: float:
	get: return cm(dims().plate_x_cm)
## Her forearm lies across the counter just before its right end: its left face blocks him.
var forearm_right_x: float:
	get: return counter_length_m - 0.15
var forearm_left_x: float:
	get: return forearm_right_x - cm(dims().forearm_width_cm)
## Where the aimed stab column may be (he is kept between the left wall and the forearm anyway).
var section_min_x: float:
	get: return 0.3
var section_max_x: float:
	get: return forearm_left_x - 0.1
## Where the 30th (final) stab lands: at the forearm end, where he usually is.
var final_x: float:
	get: return section_max_x
## The next table: the same height as her counter, a short jump away.
var next_table_top_y: float:
	get: return counter_top_y
var next_table_min_x: float:
	get: return counter_length_m + cm(dims().next_table_gap_cm)
var next_table_max_x: float:
	get: return next_table_min_x + cm(dims().next_table_length_cm)
var start_spawn: Vector3:
	get: return Vector3(cup_x, cup_top_y + 0.35, 0.0)
var next_table_spawn: Vector3:
	get: return Vector3(next_table_min_x + 1.5, next_table_top_y + 0.5, 0.0)
## Where the camera sits while he is on the pick (fixed, looking straight ahead).
var pick_camera_pos: Vector3:
	get: return Vector3(cup_x, counter_top_y + pick_camera_height_m, pick_camera_dist_m)
## Where he is put back if he falls off the counter (the floor is far below).
var fall_return_x: float:
	get: return counter_length_m - fall_return_inset_m - 0.5
var fall_catch_y: float:
	get: return counter_top_y - fall_catch_depth_m
## How far the pick rises while he wiggles: from the cup to her mouth, and from the counter.
var pick_rise_m: float:
	get: return counter_top_y + pick_final_height_m - (cup_top_y + 0.05)
var lift_rise_m: float:
	get: return pick_final_height_m - 0.02


## Cutscene shot positions are written in real centimetres; these give the camera in game metres.
func shot_from(shot: CutsceneShotScript) -> Vector3:
	return shot.from_pos * m_per_cm()


func shot_to(shot: CutsceneShotScript) -> Vector3:
	return pick_camera_pos if shot.end_on_pick_camera else shot.to_pos * m_per_cm()


func shot_look_from(shot: CutsceneShotScript) -> Vector3:
	return shot.look_from * m_per_cm()


func shot_look_to(shot: CutsceneShotScript) -> Vector3:
	if shot.end_on_pick_camera:
		var at: Vector3 = pick_camera_pos
		return Vector3(at.x, at.y, 0.0) # straight ahead: the same view as the pick camera
	return shot.look_to * m_per_cm()
