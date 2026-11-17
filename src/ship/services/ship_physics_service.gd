class_name ShipPhysicsService
extends RefCounted

## Newtonian gravity physics mathematically extracted 1:1 from Head-On PE assembly (0x40b820 / 0x401ab7).
##
## Original per-frame values at 60 FPS:
## - Thrust:  0.040 px/frame² -> 144.0 px/s²
## - Gravity: 0.008 px/frame² ->  28.8 px/s²
## - Friction: 0.990 factor   ->   0.60 per-second linear damping
## - Max Speed: (0.04 / 0.01) * 60 = 240.0 px/s (4.0 px/frame)
## - Max Fall:  (0.008 / 0.01) * 60 = 48.0 px/s (0.8 px/frame)

const GRAVITY: float = 28.8          # px/s² downwards (0.008 * 3600)
const THRUST: float = 144.0          # px/s² along heading (0.04 * 3600)
const AIR_FRICTION: float = 0.60     # continuous damping equivalent to * 0.99 at 60 FPS
const WATER_FRICTION: float = 2.40   # water friction (~4x air)
const BOUNCE_RESTITUTION: float = -0.5
const MAX_SPEED: float = 240.0       # terminal velocity cap (4.0 px/frame)
const FUEL_CONSUMPTION: float = 4500.0 # units per second

## Updates ship kinematics over time step delta (in seconds)
static func apply_kinematics(state: ShipState, is_thrusting: bool, delta: float) -> void:
	if not state.is_alive or state.is_docked:
		state.velocity = Vector2.ZERO
		return

	# 1. Gravity downwards (0.008 * dt)
	state.velocity.y += (GRAVITY * delta)

	# 2. Air / Water friction (* 0.99 at 60 FPS)
	var friction = WATER_FRICTION if state.is_in_water else AIR_FRICTION
	state.velocity *= maxf(0.0, 1.0 - (friction * delta))

	# 3. Thrust vector in ship orientation (0.04 * dt)
	if is_thrusting and state.fuel > 0:
		var thrust_dir = state.get_thrust_direction()
		state.velocity += thrust_dir * (THRUST * delta)
		state.fuel = maxi(0, state.fuel - int(FUEL_CONSUMPTION * delta))

	# 4. Terminal velocity cap
	if state.velocity.length() > MAX_SPEED:
		state.velocity = state.velocity.normalized() * MAX_SPEED

## Resolves an impact collision against solid terrain (restitution -0.5)
static func resolve_bounce(state: ShipState, normal: Vector2) -> void:
	if normal != Vector2.ZERO:
		state.velocity = state.velocity.bounce(normal) * absf(BOUNCE_RESTITUTION)
	else:
		state.velocity *= BOUNCE_RESTITUTION

## Platform docking recharge logic
static func process_docking(state: ShipState, delta: float) -> void:
	if state.is_docked:
		var recharge = int(25000.0 * delta)
		state.shield = mini(ShipState.MAX_RESOURCE_VALUE, state.shield + recharge)
		state.fuel = mini(ShipState.MAX_RESOURCE_VALUE, state.fuel + recharge)
		state.ammo_gun = mini(ShipState.MAX_RESOURCE_VALUE, state.ammo_gun + recharge)
		state.ammo_special = mini(ShipState.MAX_RESOURCE_VALUE, state.ammo_special + recharge)
