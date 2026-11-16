class_name ShipView
extends Node2D

## View layer for the Ship: strictly renders visuals, particles, and orientation.

@onready var sprite: Sprite2D = $Sprite2D
@onready var thrust_flame: Line2D = $ThrustFlame
@onready var audio_engine: AudioStreamPlayer2D = $EngineSound

func _ready() -> void:
	if thrust_flame:
		thrust_flame.visible = false

func update_orientation(angle_step_index: int) -> void:
	if sprite:
		# 64 frames: 8 columns x 8 rows in sprites.png
		sprite.frame = clampi(angle_step_index, 0, 63)

func set_thrust_active(active: bool, thrust_direction: Vector2) -> void:
	if thrust_flame:
		thrust_flame.visible = active
		if active:
			# Draw flame directly behind the ship nozzle
			var back_dir = -thrust_direction
			thrust_flame.clear_points()
			thrust_flame.add_point(back_dir * 4.0)
			thrust_flame.add_point(back_dir * 12.0)

	if audio_engine:
		if active and not audio_engine.playing:
			audio_engine.play()
		elif not active and audio_engine.playing:
			audio_engine.stop()

func play_hit_effect() -> void:
	# Flash effect
	var tween = create_tween()
	modulate = Color(2.5, 2.5, 2.5) # Overdrive brightness flash
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
