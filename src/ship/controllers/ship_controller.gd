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
	# Fixed step normalization matching original loop (dt = 72.0 / ms)
	var dt: float = delta * 60.0 # ~1.0 at 60 FPS
	
	_handle_rotation_input()
	
	var is_thrusting = Input.is_action_pressed(action_thrust)
	ShipPhysicsService.apply_kinematics(state, is_thrusting, dt)
	
	# Pass velocity to CharacterBody2D in pixels/sec
	velocity = state.velocity * 60.0
	move_and_slide()
	
	# Sync resulting velocity and position back to model
	state.velocity = velocity / 60.0
	state.position = global_position
	
	# Handle wall bounces (coefficient -0.5)
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		ShipPhysicsService.resolve_bounce(state, collision.get_normal())
		velocity = state.velocity * 60.0
		view.play_hit_effect()
		EventBus.play_sfx_requested.emit("shipHit1", global_position)
		
	# Update View
	view.update_orientation(state.angle_step_index)
	view.set_thrust_active(is_thrusting and state.fuel > 0, state.get_angle_radians())

func _handle_rotation_input() -> void:
	if Input.is_action_just_pressed(action_left):
		state.rotate_left()
	elif Input.is_action_just_pressed(action_right):
		state.rotate_right()
	
	# Continuous rotation when holding keys
	if Input.is_action_pressed(action_left) and not Input.is_action_just_pressed(action_left):
		if Engine.get_physics_frames() % 3 == 0: # ~20 rotation steps / sec
			state.rotate_left()
	elif Input.is_action_pressed(action_right) and not Input.is_action_just_pressed(action_right):
		if Engine.get_physics_frames() % 3 == 0:
			state.rotate_right()
