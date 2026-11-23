extends Resource
## One kind of thing that customers drop on the floor lane (a metal chopstick, a spoon): how it looks and
## how heavy it hits while it falls, and what it becomes once it has landed. Data: data/hazards/*.tres.
## Sizes are real centimetres times the world scale. Values are 🟡 (playtests).

@export var id: String = ""
## How likely this one is next to the others in the zone's list (relative).
@export var weight: float = 1.0
## Falling: speed in m/s, and the size of what hurts (width x, length y).
@export var fall_speed_mps: float = 14.0
@export var fall_width_cm: float = 3.0
@export var fall_length_cm: float = 14.0
## Damage in half-hearts to the 떡 it lands on while it falls. No grab.
@export var damage_half_hearts: int = 1
## Landed: a solid box (length x, height y, depth z): low, he can jump over it or stand on it.
@export var prop_size_cm: Vector3 = Vector3(20.0, 1.8, 2.0)
@export var color: Color = Color(0.75, 0.77, 0.8)
