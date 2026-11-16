class_name ShipState
extends RefCounted

## State model for a player's ship. Pure data, no rendering or scene tree dependency.

const MAX_RESOURCE_VALUE: int = 65535 # 0xFFFF (16-bit integer as in original 1999 binary)
const STEP_ANGLE_COUNT: int = 64
const STEP_ANGLE_DEGREES: float = 360.0 / float(STEP_ANGLE_COUNT) # 5.625 degrees

var player_id: int = 1
var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO

var angle_step_index: int = 32 # 0..63 (facing down / 180 deg by default)
var lives: int = 4
var shield: int = MAX_RESOURCE_VALUE
var fuel: int = MAX_RESOURCE_VALUE
var ammo_gun: int = MAX_RESOURCE_VALUE
var ammo_special: int = MAX_RESOURCE_VALUE

var selected_gun: int = 1     # 1..4
var selected_special: int = 1 # 1..4

var is_docked: bool = false
var is_in_water: bool = false
var is_alive: bool = true

func get_angle_radians() -> float:
	return float(angle_step_index) * deg_to_rad(STEP_ANGLE_DEGREES)

func rotate_left() -> void:
	angle_step_index = (angle_step_index - 1 + STEP_ANGLE_COUNT) % STEP_ANGLE_COUNT

func rotate_right() -> void:
	angle_step_index = (angle_step_index + 1) % STEP_ANGLE_COUNT
