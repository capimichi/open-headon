class_name ShipController
extends CharacterBody2D

## Controller connecting player input, kinematics service, and view representation.

@export var player_id: int = 1
@export var player_tint: Color = Color(0.3, 1.0, 0.4) # Green ship by default

var state: ShipState = ShipState.new()

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

func _physics_process(delta: float) -> void:
	var is_thrusting = Input.is_action_pressed(action_thrust)
	
	# Docking / Takeoff handling
	if state.is_docked:
		ShipPhysicsService.process_docking(state, delta)
		if is_thrusting:
			state.is_docked = false # Takeoff!
			state.velocity = state.get_thrust_direction() * 100.0 # Initial upward boost
			velocity = state.velocity
			EventBus.ship_docked.emit(player_id, false)
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
	
	# Handle terrain and platform collisions
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		var normal = collision.get_normal()
		
		# Gentle landing on platform
		if normal.y < -0.7 and state.velocity.length() < 60.0 and absi(state.angle_step_index - 32) <= 4:
			state.is_docked = true
			state.velocity = Vector2.ZERO
			velocity = Vector2.ZERO
			EventBus.ship_docked.emit(player_id, true)
			EventBus.play_sfx_requested.emit("fuelFilling", global_position)
		else:
			# Regular bounce
			ShipPhysicsService.resolve_bounce(state, normal)
			velocity = state.velocity
			view.play_hit_effect()
			EventBus.play_sfx_requested.emit("shipHit1", global_position)
		
	# Update View
	view.update_orientation(state.angle_step_index)
	view.set_thrust_active(is_thrusting and state.fuel > 0, state.get_thrust_direction())

func _handle_rotation_input() -> void:
	if Input.is_action_just_pressed(action_left):
		state.rotate_left()
	elif Input.is_action_just_pressed(action_right):
		state.rotate_right()
	
	# Continuous rotation when holding keys
	if Input.is_action_pressed(action_left) and not Input.is_action_just_pressed(action_left):
		if Engine.get_physics_frames() % 3 == 0:
			state.rotate_left()
	elif Input.is_action_pressed(action_right) and not Input.is_action_just_pressed(action_right):
		if Engine.get_physics_frames() % 3 == 0:
			state.rotate_right()
