class_name ShipController
extends CharacterBody2D

## Controller connecting player input, kinematics service, view representation,
## and platform docking/takeoff mechanics.

@export var player_id: int = 1
@export var player_tint: Color = Color(0.3, 1.0, 0.4) # Green ship by default

var state: ShipState = ShipState.new()
var active_platforms: Array = []
var docking_cooldown: float = 0.0

@onready var view: ShipView = $ShipView
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Input action names
var action_thrust: String
var action_left: String
var action_right: String
var action_gun: String
var action_special: String

func _ready() -> void:
	state.player_id = player_id
	state.angle_step_index = 32 # Facing UP at spawn
	state.is_docked = true     # Starts docked on platform!
	
	action_thrust = "p%d_thrust" % player_id
	action_left = "p%d_left" % player_id
	action_right = "p%d_right" % player_id
	action_gun = "p%d_gun" % player_id
	action_special = "p%d_special" % player_id
	
	if view:
		view.modulate = player_tint
		view.update_orientation(state.angle_step_index)
		
	EventBus.ship_spawned.emit(player_id, global_position)

func set_active_platforms(platforms: Array) -> void:
	active_platforms = platforms

func _physics_process(delta: float) -> void:
	if docking_cooldown > 0.0:
		docking_cooldown = maxf(0.0, docking_cooldown - delta)

	var is_thrusting = Input.is_action_pressed(action_thrust)
	
	# Docking / Takeoff handling
	if state.is_docked:
		ShipPhysicsService.process_docking(state, delta)
		if is_thrusting and state.fuel > 0:
			state.is_docked = false # Takeoff!
			docking_cooldown = 0.35  # Grace period during ascent
			EventBus.ship_docked.emit(player_id, false)
			# Velocity begins smoothly from zero: kinematics handles thrust acceleration
		else:
			velocity = Vector2.ZERO
			view.update_orientation(state.angle_step_index)
			view.set_thrust_active(false, state.get_thrust_direction())
			return

	_handle_rotation_input()
	
	# Apply Physics
	ShipPhysicsService.apply_kinematics(state, is_thrusting, delta)
	velocity = state.velocity
	
	move_and_slide()
	
	# Sync resulting velocity and position
	state.velocity = velocity
	state.position = global_position
	
	# Platform Docking Landing Check (only when not actively thrusting upwards)
	if not state.is_docked and docking_cooldown <= 0.0 and not is_thrusting:
		if _check_platform_docking():
			return
	
	# Handle terrain and obstacle collisions
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		var normal = collision.get_normal()
		
		# Regular bounce against rock / obstacles
		ShipPhysicsService.resolve_bounce(state, normal)
		velocity = state.velocity
		view.play_hit_effect()
		EventBus.play_sfx_requested.emit("shipHit1", global_position)
		
	# Update View
	view.update_orientation(state.angle_step_index)
	view.set_thrust_active(is_thrusting and state.fuel > 0, state.get_thrust_direction())

func _check_platform_docking() -> bool:
	if velocity.y < -5.0:
		return false
	if absi(state.angle_step_index - 32) > 5:
		return false
		
	for plat in active_platforms:
		var x_start = float(plat["x_start"])
		var x_end = float(plat["x_end"])
		var plat_y = float(plat["y"])
		
		# Check horizontal contact within platform pad limits
		if global_position.x >= (x_start - 4.0) and global_position.x <= (x_end + 4.0):
			# Ship bottom is at global_position.y + 10.0 (circle radius 10)
			var dist = (global_position.y + 10.0) - plat_y
			if dist >= -4.0 and dist <= 9.0:
				state.is_docked = true
				state.velocity = Vector2.ZERO
				velocity = Vector2.ZERO
				global_position.y = plat_y - 10.0
				state.angle_step_index = 32
				state.position = global_position
				view.update_orientation(state.angle_step_index)
				view.set_thrust_active(false, state.get_thrust_direction())
				EventBus.ship_docked.emit(player_id, true)
				EventBus.play_sfx_requested.emit("shipHitPLatform", global_position)
				EventBus.play_sfx_requested.emit("fuelFilling", global_position)
				return true
	return false

func _handle_rotation_input() -> void:
	if Input.is_action_just_pressed(action_left):
		state.rotate_left()
	elif Input.is_action_just_pressed(action_right):
		state.rotate_right()
	
	# Continuous rotation when holding keys (3-frame interval)
	if Input.is_action_pressed(action_left) and not Input.is_action_just_pressed(action_left):
		if Engine.get_physics_frames() % 3 == 0:
			state.rotate_left()
	elif Input.is_action_pressed(action_right) and not Input.is_action_just_pressed(action_right):
		if Engine.get_physics_frames() % 3 == 0:
			state.rotate_right()
