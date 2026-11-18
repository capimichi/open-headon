class_name ProjectileController
extends CharacterBody2D

## Projectile fired by Gun weapons (variants 1..4).
## Governed by Newtonian ballistic gravity and ricochet dynamics.

const GRAVITY: float = 57.6 # 0.016 * dt * 3600 (2x ship gravity)
const MAX_BOUNCES: int = 1

var shooter_player_id: int = 1
var damage: int = 1800 # ~2.7% of 65535 shield per hit
var bounces_left: int = MAX_BOUNCES
var lifetime: float = 3.5

@onready var visual: Line2D = $Visual

func _ready() -> void:
	collision_layer = 4 # Projectiles layer
	collision_mask = 1 | 2 # Hits Ships (1) and Terrain (2)

func setup(origin: Vector2, initial_vel: Vector2, p_id: int, dmg: int = 1800) -> void:
	global_position = origin
	velocity = initial_vel
	shooter_player_id = p_id
	damage = dmg

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
		
	# Ballistic gravity
	velocity.y += GRAVITY * delta
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider is ShipController:
			if collider.player_id != shooter_player_id and collider.state.is_alive:
				collider.apply_damage(damage, velocity * 0.1, shooter_player_id)
				_spawn_hit_spark(collision.get_position())
				queue_free()
				return
		elif collider is StaticBody2D: # Terrain
			if bounces_left > 0:
				bounces_left -= 1
				velocity = velocity.bounce(collision.get_normal()) * 0.65
				var ric_sounds = ["ric1", "ric2", "ric3"]
				var chosen = ric_sounds[randi() % ric_sounds.size()]
				EventBus.play_sfx_requested.emit(chosen, collision.get_position())
			else:
				_spawn_hit_spark(collision.get_position())
				queue_free()
				return

func _spawn_hit_spark(pos: Vector2) -> void:
	# Small visual feedback
	var spark = Node2D.new()
	spark.global_position = pos
	get_parent().add_child(spark)
	var tween = spark.create_tween()
	tween.tween_callback(spark.queue_free).set_delay(0.1)
