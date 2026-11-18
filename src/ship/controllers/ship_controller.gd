class_name ShipController
extends CharacterBody2D

## Controller connecting player input, kinematics service, view representation,
## weapon combat systems, and platform docking/takeoff mechanics.

@export var player_id: int = 1
@export var player_tint: Color = Color(0.3, 1.0, 0.4) # Green ship by default

var state: ShipState = ShipState.new()
var active_platforms: Array = []
var spawn_position: Vector2 = Vector2.ZERO
var docking_cooldown: float = 0.0
var gun_cooldown: float = 0.0

var projectile_scene = preload("res://src/combat/views/projectile.tscn")

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
	state.angle_degrees = 180.0 # Facing UP at spawn
	state.is_docked = true      # Starts docked on platform!
	spawn_position = global_position
	
	action_thrust = "p%d_thrust" % player_id
	action_left = "p%d_left" % player_id
	action_right = "p%d_right" % player_id
	action_gun = "p%d_gun" % player_id
	action_special = "p%d_special" % player_id
	
	if view:
		view.modulate = player_tint
		view.update_orientation(state.angle_step_index)
		
	EventBus.ship_spawned.emit(player_id, global_position)
	_emit_resource_updates()

func set_active_platforms(platforms: Array) -> void:
	active_platforms = platforms

func _physics_process(delta: float) -> void:
	# 1. Dead / Respawn Handling
	if not state.is_alive:
		state.respawn_timer -= delta
		if state.respawn_timer <= 0.0:
			_respawn()
		return

	if docking_cooldown > 0.0:
		docking_cooldown = maxf(0.0, docking_cooldown - delta)
	if gun_cooldown > 0.0:
		gun_cooldown = maxf(0.0, gun_cooldown - delta)

	var is_thrusting = Input.is_action_pressed(action_thrust)
	
	# 2. Docking / Takeoff & Docked Weapon Selection
	if state.is_docked:
		ShipPhysicsService.process_docking(state, delta)
		_emit_resource_updates()
		
		# Weapon selection while docked
		if Input.is_action_just_pressed(action_special):
			state.selected_special = (state.selected_special % 4) + 1
			EventBus.play_sfx_requested.emit("changeWeapon", global_position)
		if Input.is_action_just_pressed(action_gun):
			state.selected_gun = (state.selected_gun % 4) + 1
			EventBus.play_sfx_requested.emit("changeWeapon", global_position)
			
		if is_thrusting and state.fuel > 0:
			state.is_docked = false # Takeoff!
			docking_cooldown = 0.35  # Grace period during ascent
			EventBus.ship_docked.emit(player_id, false)
		else:
			velocity = Vector2.ZERO
			view.update_orientation(state.angle_step_index)
			view.set_thrust_active(false, state.get_thrust_direction())
			return

	# 3. Continuous 216 deg/s Rotation Input
	_handle_rotation_input(delta)
	
	# 4. Weapon Combat Inputs
	if Input.is_action_pressed(action_gun) and gun_cooldown <= 0.0:
		_fire_gun()
		
	if Input.is_action_just_pressed(action_special):
		_fire_special()

	# 5. Apply Kinematics
	ShipPhysicsService.apply_kinematics(state, is_thrusting, delta)
	velocity = state.velocity
	
	var pre_move_vel = velocity
	move_and_slide()
	
	state.velocity = velocity
	state.position = global_position
	
	# 6. Platform Docking Check (when descending and not thrusting)
	if not state.is_docked and docking_cooldown <= 0.0 and not is_thrusting:
		if _check_platform_docking():
			return
	
	# 7. Terrain Impact Damage & Collision Bounce
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		var normal = collision.get_normal()
		var impact_speed = pre_move_vel.length()
		
		# High-speed impact damages shield
		if impact_speed > 75.0:
			var damage = int((impact_speed - 75.0) * 90.0)
			apply_damage(damage, Vector2.ZERO, 0)
			EventBus.play_sfx_requested.emit("shipHit2", global_position)
		else:
			EventBus.play_sfx_requested.emit("shipHit1", global_position)
			
		ShipPhysicsService.resolve_bounce(state, normal)
		velocity = state.velocity
		view.play_hit_effect()
		
	# 8. View & Flame Update
	view.update_orientation(state.angle_step_index)
	view.set_thrust_active(is_thrusting and state.fuel > 0, state.get_thrust_direction())
	_emit_resource_updates()

func _handle_rotation_input(delta: float) -> void:
	if Input.is_action_pressed(action_left):
		state.rotate_left_continuous(delta)
	elif Input.is_action_pressed(action_right):
		state.rotate_right_continuous(delta)

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
			var dist = (global_position.y + 10.0) - plat_y
			if dist >= -4.0 and dist <= 9.0:
				state.is_docked = true
				state.velocity = Vector2.ZERO
				velocity = Vector2.ZERO
				global_position.y = plat_y - 10.0
				state.angle_degrees = 180.0 # Snap perfectly upright
				state.position = global_position
				view.update_orientation(state.angle_step_index)
				view.set_thrust_active(false, state.get_thrust_direction())
				EventBus.ship_docked.emit(player_id, true)
				EventBus.play_sfx_requested.emit("shipHitPLatform", global_position)
				EventBus.play_sfx_requested.emit("fuelFilling", global_position)
				return true
	return false

func _fire_gun() -> void:
	if state.ammo_gun < 500:
		return
		
	state.ammo_gun = maxi(0, state.ammo_gun - 500)
	gun_cooldown = 0.14 # Rate of fire
	
	var thrust_dir = state.get_thrust_direction()
	var spawn_pos = global_position + thrust_dir * 14.0
	var bullet_vel = state.velocity + thrust_dir * 380.0
	
	var proj = projectile_scene.instantiate()
	get_parent().add_child(proj)
	proj.setup(spawn_pos, bullet_vel, player_id, 1600)
	
	# Slight recoil impulse
	state.velocity -= thrust_dir * 12.0
	EventBus.play_sfx_requested.emit("gun1Sound1", global_position)

func _fire_special() -> void:
	const SPECIAL_COST: int = 13107 # 5 uses total from 65535
	if state.ammo_special < SPECIAL_COST:
		return
		
	state.ammo_special = maxi(0, state.ammo_special - SPECIAL_COST)
	var thrust_dir = state.get_thrust_direction()
	
	match state.selected_special:
		1: # Cluster Bomb
			EventBus.play_sfx_requested.emit("S1_1", global_position)
			_spawn_cluster_bomb(thrust_dir)
		2: # Homing Missile
			EventBus.play_sfx_requested.emit("S2_1", global_position)
			_spawn_missile(thrust_dir)
		3: # Shockwave
			EventBus.play_sfx_requested.emit("S3_1", global_position)
			_execute_shockwave()
		4: # Speed Boost
			EventBus.play_sfx_requested.emit("S4_1", global_position)
			state.velocity += thrust_dir * 250.0
			view.play_hit_effect()

func _spawn_cluster_bomb(dir: Vector2) -> void:
	var proj = projectile_scene.instantiate()
	get_parent().add_child(proj)
	proj.setup(global_position + dir * 16.0, state.velocity + dir * 280.0, player_id, 2800)

func _spawn_missile(dir: Vector2) -> void:
	var proj = projectile_scene.instantiate()
	get_parent().add_child(proj)
	proj.setup(global_position + dir * 16.0, state.velocity + dir * 320.0, player_id, 3500)

func _execute_shockwave() -> void:
	# Radial push against other ships
	EventBus.explosion_occurred.emit(global_position, 120.0)

func apply_damage(amount: int, impulse: Vector2, attacker_id: int) -> void:
	if not state.is_alive:
		return
		
	state.shield = maxi(0, state.shield - amount)
	state.velocity += impulse
	view.play_hit_effect()
	_emit_resource_updates()
	
	if state.shield <= 0:
		_destroy_ship(attacker_id)

func _destroy_ship(killer_id: int) -> void:
	state.is_alive = false
	state.lives -= 1
	state.respawn_timer = 2.0
	state.velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	view.play_explosion_effect()
	EventBus.play_sfx_requested.emit("shipExp", global_position)
	EventBus.ship_destroyed.emit(player_id, killer_id)

func _respawn() -> void:
	global_position = spawn_position
	state.reset_resources()
	view.reset_view()
	view.update_orientation(state.angle_step_index)
	EventBus.ship_spawned.emit(player_id, global_position)
	_emit_resource_updates()

func _emit_resource_updates() -> void:
	EventBus.ship_shield_changed.emit(player_id, state.shield, ShipState.MAX_RESOURCE_VALUE)
	EventBus.ship_fuel_changed.emit(player_id, state.fuel, ShipState.MAX_RESOURCE_VALUE)
	EventBus.ship_ammo_changed.emit(player_id, 1, state.ammo_gun)
	EventBus.ship_ammo_changed.emit(player_id, 2, state.ammo_special)
