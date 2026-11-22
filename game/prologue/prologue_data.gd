extends Resource
## All numbers, shots, patterns, stages and lines of the Map 1 prologue (data/prologue/prologue.tres).
## Layout numbers (x, y) must match maps/ep01/map01_bunsikjip/map01.tscn.

const CutsceneShotScript := preload("res://prologue/cutscene_shot.gd")
const AngerStageScript := preload("res://prologue/anger_stage.gd")
const StabPatternScript := preload("res://prologue/stab_pattern.gd")
const PrologueLinesScript := preload("res://prologue/prologue_lines.gd")

@export_group("Content")
@export var shots: Array[CutsceneShotScript] = []
@export var stages: Array[AngerStageScript] = []
@export var patterns: Array[StabPatternScript] = []
@export var lines: PrologueLinesScript

@export_group("Wiggle")
## Opening pick: alternations of left/right needed inside window_s (= the time the pick takes to rise).
@export var required_alternations: int = 10
@export var window_s: float = 3.0
## Same mechanic after a big stab lifts him.
@export var lift_required_alternations: int = 10
@export var lift_window_s: float = 3.0
## How far the pick rises (m) by the end of the window (to her mouth, off-screen).
@export var pick_rise_m: float = 12.0
@export var lift_rise_m: float = 12.0

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
@export var plate_mandu_count: int = 6
## "Later in stage 1" line: said once the count reaches this (while still in stage 1).
@export var stage1_later_stab: int = 11

@export_group("Eaten")
@export var eaten_total_s: float = 2.6
@export var eaten_shake_s: float = 0.5
@export var eaten_blackout_s: float = 0.9
@export var game_over_text: String = "GAME OVER"

@export_group("Subtitles")
@export var line_duration_s: float = 3.0

@export_group("Layout")
@export var counter_top_y: float = 1.0
## Where the aimed stab column may be (the 떡 is kept between the walls anyway).
@export var section_min_x: float = 0.2
@export var section_max_x: float = 13.4
@export var cup_x: float = 3.2
@export var cup_top_y: float = 1.55
@export var plate_x: float = 6.0
## The stuck pick (the 30th stab) and the standable top of it.
@export var final_x: float = 13.4
@export var pick_top_y: float = 2.7
@export var next_table_top_y: float = 3.6
@export var next_table_min_x: float = 16.5
@export var next_table_max_x: float = 30.0
@export var start_spawn: Vector3 = Vector3(3.2, 1.8, 0.0)
@export var next_table_spawn: Vector3 = Vector3(18.0, 4.1, 0.0)
## Where the camera sits while he is on the pick (fixed, looking straight ahead).
@export var pick_camera_pos: Vector3 = Vector3(3.2, 4.0, 9.0)
