class_name ShipPhysicsService
extends RefCounted

## Newtonian gravity physics and docking logic scaled for modern 60/120 Hz timesteps.

const GRAVITY: float = 140.0         # px/s² downwards
const THRUST: float = 380.0          # px/s² along ship heading
const AIR_FRICTION: float = 0.25     # linear damping factor
const WATER_FRICTION: float = 2.5    # water resistance
const BOUNCE_RESTITUTION: float = -0.5
const MAX_SPEED: float = 380.0       # max speed cap
const FUEL_CONSUMPTION: float = 8000.0 # units per second

## Updates ship kinematics over time step delta (in seconds)
static func apply_kinematics(state: ShipState, is_thrusting: bool, delta: float) -> void:
	if not state.is_alive or state.is_docked:
		state.velocity = Vector2.ZERO
		return

	# 1. Gravity downwards
	state.velocity.y += (GRAVITY * delta)

	# 2. Air / Water friction
	var friction = WATER_FRICTION if state.is_in_water else AIR_FRICTION
	state.velocity *= maxf(0.0, 1.0 - (friction * delta))

	# 3. Thrust vector in ship orientation
	if is_thrusting and state.fuel > 0:
		var thrust_dir = state.get_thrust_direction()
		state.velocity += thrust_dir * (THRUST * delta)
		state.fuel = maxi(0, state.fuel - int(FUEL_CONSUMPTION * delta))

	# 4. Speed clamp
	if state.velocity.length() > MAX_SPEED:
		state.velocity = state.velocity.normalized() * MAX_SPEED

## Resolves an impact collision against solid terrain
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
