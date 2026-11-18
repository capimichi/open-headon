class_name ShipState
extends RefCounted

## State model for a player's ship. Pure data, no rendering or scene tree dependency.
## Conforms 1:1 with Head-On PE assembly architecture (0x40b820 / 0x401801).

const MAX_RESOURCE_VALUE: int = 65535 # 0xFFFF (16-bit integer as in original 1999 binary)
const STEP_ANGLE_COUNT: int = 64
const STEP_ANGLE_DEGREES: float = 360.0 / float(STEP_ANGLE_COUNT) # 5.625 degrees
const ROTATION_SPEED_DEGREES: float = 216.0 # 3.0 deg per logic dt unit (~216 deg/s at 60 FPS)

var player_id: int = 1
var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO

## Continuous rotation angle in degrees:
## 0° = DOWN, 90° = RIGHT, 180° = UP (spawn default), 270° = LEFT
var angle_degrees: float = 180.0

var lives: int = 4
var score: int = 0
var shield: int = MAX_RESOURCE_VALUE
var fuel: int = MAX_RESOURCE_VALUE
var ammo_gun: int = MAX_RESOURCE_VALUE
var ammo_special: int = MAX_RESOURCE_VALUE

var selected_gun: int = 1     # 1..4
var selected_special: int = 1 # 1..4

var is_docked: bool = false
var is_in_water: bool = false
var is_alive: bool = true
var respawn_timer: float = 0.0

## Gets the discrete sprite frame index [0..63] quantized from continuous angle
var angle_step_index: int:
	get:
		var step = int(round(angle_degrees / STEP_ANGLE_DEGREES)) % STEP_ANGLE_COUNT
		return step if step >= 0 else step + STEP_ANGLE_COUNT
	set(val):
		angle_degrees = wrapf(float(val) * STEP_ANGLE_DEGREES, 0.0, 360.0)

## Radians for mathematical functions
func get_angle_radians() -> float:
	return deg_to_rad(angle_degrees)

## Exact Newtonian heading vector for thrust, weapons, and particle recoil
func get_thrust_direction() -> Vector2:
	# 0° = DOWN (0, 1), 90° = RIGHT (1, 0), 180° = UP (0, -1), 270° = LEFT (-1, 0)
	var rad = get_angle_radians()
	return Vector2(sin(rad), -cos(rad))

## Continuous rotation methods (smooth linear 216 deg/s)
func rotate_left_continuous(delta: float) -> void:
	# Counter-clockwise: 180° (UP) -> 270° (LEFT)
	angle_degrees = wrapf(angle_degrees + (ROTATION_SPEED_DEGREES * delta), 0.0, 360.0)

func rotate_right_continuous(delta: float) -> void:
	# Clockwise: 180° (UP) -> 90° (RIGHT)
	angle_degrees = wrapf(angle_degrees - (ROTATION_SPEED_DEGREES * delta), 0.0, 360.0)

## Discrete single-step helpers for discrete weapon selection or docking adjustments
func rotate_left() -> void:
	angle_degrees = wrapf(angle_degrees + STEP_ANGLE_DEGREES, 0.0, 360.0)

func rotate_right() -> void:
	angle_degrees = wrapf(angle_degrees - STEP_ANGLE_DEGREES, 0.0, 360.0)

func reset_resources() -> void:
	shield = MAX_RESOURCE_VALUE
	fuel = MAX_RESOURCE_VALUE
	ammo_gun = MAX_RESOURCE_VALUE
	ammo_special = MAX_RESOURCE_VALUE
	velocity = Vector2.ZERO
	angle_degrees = 180.0
	is_docked = true
	is_alive = true
