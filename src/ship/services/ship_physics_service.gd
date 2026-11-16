class_name ShipPhysicsService
extends RefCounted

## Pure business logic for ship Newtonian physics and docking.
## Formulas verified from decompiled assembly at 0x40b820.

# Original constants scaled to internal fixed step (dt = 72.0 / ms)
const GRAVITY_FACTOR: float = 0.008
const FRICTION_FACTOR: float = 0.01
const THRUST_FACTOR: float = 0.04
const WATER_FRICTION_MULTIPLIER: float = 3.5
const BOUNCE_RESTITUTION: float = -0.5
const FUEL_CONSUMPTION_RATE: int = 120 # per second of thrust

## Updates ship kinematics over time step dt
static func apply_kinematics(state: ShipState, is_thrusting: bool, dt: float) -> void:
	if not state.is_alive or state.is_docked:
		state.velocity = Vector2.ZERO
		return

	# 1. Gravity downwards
	state.velocity.y += (GRAVITY_FACTOR * dt)

	# 2. Air / Water friction
	var current_friction = FRICTION_FACTOR * dt
	if state.is_in_water:
		current_friction *= WATER_FRICTION_MULTIPLIER
	state.velocity *= maxf(0.0, 1.0 - current_friction)

	# 3. Thrust vector in ship orientation
	if is_thrusting and state.fuel > 0:
		var rad = state.get_angle_radians()
		var thrust_vec = Vector2(cos(rad), sin(rad)) * (THRUST_FACTOR * dt)
		state.velocity += thrust_vec
		state.fuel = maxi(0, state.fuel - int(FUEL_CONSUMPTION_RATE * dt))

## Resolves an impact collision against solid terrain (0x80)
static func resolve_bounce(state: ShipState, normal: Vector2) -> void:
	if normal != Vector2.ZERO:
		state.velocity = state.velocity.bounce(normal) * absf(BOUNCE_RESTITUTION)
	else:
		state.velocity *= BOUNCE_RESTITUTION

## Platform docking recharge logic
static func process_docking(state: ShipState, dt: float) -> void:
	if state.is_docked:
		var recharge_speed = int(15000.0 * dt)
		state.shield = mini(ShipState.MAX_RESOURCE_VALUE, state.shield + recharge_speed)
		state.fuel = mini(ShipState.MAX_RESOURCE_VALUE, state.fuel + recharge_speed)
		state.ammo_gun = mini(ShipState.MAX_RESOURCE_VALUE, state.ammo_gun + recharge_speed)
		state.ammo_special = mini(ShipState.MAX_RESOURCE_VALUE, state.ammo_special + recharge_speed)
