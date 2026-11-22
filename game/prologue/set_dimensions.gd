extends Resource
## The real-world size table of the Map 1 prologue set, in real centimetres. Everything the
## prologue builds (counter, props, her hand, the pick, her mouth, the next table) is this number
## times WorldScale.game_m_per_real_cm. All values are approximate starting values; tune freely.
## Data: res://data/prologue/set_dimensions.tres. x runs along the counter, y up, z toward the
## camera; x = 0 is the left end of her counter section, y = 0 the floor, z = 0 the counter's middle.

@export_group("Counter")
@export var counter_top_height_cm: float = 75.0
@export var counter_depth_cm: float = 40.0
## Length of her section of the window counter (between the invisible left wall and the forearm).
@export var counter_length_cm: float = 90.0
@export var stool_seat_width_cm: float = 35.0
@export var stool_seat_height_cm: float = 45.0

@export_group("Props on her counter")
@export var cup_height_cm: float = 9.0
@export var cup_width_cm: float = 7.0
@export var plate_width_cm: float = 15.0
@export var plate_height_cm: float = 1.2
## Steamed 만두 (width; its height is mandu_height_fraction of it).
@export var mandu_width_cm: float = 5.0
@export var mandu_height_fraction: float = 0.7
## Napkin box: width (x), height (y), depth (z).
@export var napkin_box_cm: Vector3 = Vector3(12.0, 10.0, 8.0)
@export var spoon_holder_height_cm: float = 12.0
@export var spoon_holder_width_cm: float = 7.0
## Where the props stand along the counter, from its left end.
@export var cup_x_cm: float = 14.0
@export var plate_x_cm: float = 34.0
@export var napkin_x_cm: float = 47.0
@export var spoon_holder_x_cm: float = 57.0

@export_group("Her")
@export var pick_length_cm: float = 7.0
@export var pick_thickness_cm: float = 0.3
@export var hand_length_cm: float = 19.0
@export var mouth_width_cm: float = 5.0
## How far her mouth opens (jaw gap) while she lifts the pick to it.
@export var mouth_open_cm: float = 4.0
## Her other forearm, lying across the counter (width along the counter, and its height).
@export var forearm_width_cm: float = 6.5
@export var forearm_length_cm: float = 26.0

@export_group("Exit")
## Gap between the end of her counter and the next table (same height as her counter).
@export var next_table_gap_cm: float = 12.0
@export var next_table_length_cm: float = 120.0
@export var next_table_thickness_cm: float = 4.0

@export_group("Shop")
@export var shop_floor_min_x_cm: float = -800.0
@export var shop_floor_max_x_cm: float = 400.0
@export var dining_table_width_cm: float = 90.0
@export var dining_table_depth_cm: float = 60.0
@export var dining_table_x_cm: PackedFloat32Array = PackedFloat32Array([-150.0, -280.0, -410.0])
@export var dining_table_z_cm: float = -10.0
@export var back_wall_z_cm: float = -45.0
@export var menu_board_x_cm: float = -330.0
@export var kitchen_x_cm: float = -620.0
