extends Resource
## Data of a hazard that strikes from above on a timer (metal chopsticks, a giant foot): how long its
## shadow warns, how often it strikes, how wide and how hard. Specific hazards extend this
## (chopsticks_def.gd, giant_foot_def.gd). Values are 🟡 (playtests).

## The shadow on the floor shows this long before the strike.
@export var telegraph_s: float = 0.8
## The strike itself is felt for this long (the first tick of it does the damage).
@export var strike_hold_s: float = 0.25
## Then the hazard goes back up this long before it starts waiting again.
@export var recover_s: float = 0.6
## Seconds between a strike's end and the next shadow: a random value between the two.
@export var cooldown_min_s: float = 3.0
@export var cooldown_max_s: float = 6.0
## Width of what comes down (real centimetres times the world scale).
@export var strike_width_cm: float = 12.0
## How far above the surface a strike reaches (metres).
@export var strike_height_m: float = 3.0
## Damage in half-hearts to the 떡 caught under it.
@export var damage_half_hearts: int = 1
## true: the shadow settles where he stands when it appears (if he is in the zone). false: anywhere.
@export var aim_player: bool = true
