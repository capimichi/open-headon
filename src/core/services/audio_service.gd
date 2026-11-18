extends Node

## Global sound manager playing SFX requests via AudioStreamPlayer pool.

var sfx_streams: Dictionary = {}
var player_pool: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 16

func _ready() -> void:
	_load_sound_assets()
	_create_player_pool()
	EventBus.play_sfx_requested.connect(_on_play_sfx_requested)

func _load_sound_assets() -> void:
	var sound_files = {
		"gun1Sound1": "res://src/combat/assets/gun1Sound1.wav",
		"ric1": "res://src/combat/assets/ric1.wav",
		"ric2": "res://src/combat/assets/ric2.wav",
		"ric3": "res://src/combat/assets/ric3.wav",
		"shipExp": "res://src/combat/assets/shipExp.wav",
		"changeWeapon": "res://src/combat/assets/changeWeapon.wav",
		"S1_1": "res://src/combat/assets/S1_1.wav",
		"S1_2": "res://src/combat/assets/S1_2.wav",
		"S2_1": "res://src/combat/assets/S2_1.wav",
		"S2_2": "res://src/combat/assets/S2_2.wav",
		"S2_3": "res://src/combat/assets/S2_3.wav",
		"S2_4": "res://src/combat/assets/S2_4.wav",
		"S3_1": "res://src/combat/assets/S3_1.wav",
		"S3_2": "res://src/combat/assets/S3_2.wav",
		"S4_1": "res://src/combat/assets/S4_1.wav",
		"S4_2": "res://src/combat/assets/S4_2.wav",
		"shipHit1": "res://src/ship/assets/shipHit1.wav",
		"shipHit2": "res://src/ship/assets/shipHit2.wav",
		"shipHitPLatform": "res://src/ship/assets/shipHitPLatform.wav",
		"fuelFilling": "res://src/ship/assets/fuelFilling.wav",
		"outOfWater": "res://src/ship/assets/outOfWater.wav",
		"inToWater": "res://src/ship/assets/inToWater.wav",
		"outOfControl": "res://src/ship/assets/outOfControl.wav",
		"tick": "res://src/ui/assets/tick.wav",
		"getit": "res://src/match/assets/getit.wav"
	}
	
	for key in sound_files:
		var path = sound_files[key]
		if ResourceLoader.exists(path):
			sfx_streams[key] = load(path)
		else:
			push_warning("Sound file not found: " + path)

func _create_player_pool() -> void:
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		player_pool.append(p)

func _on_play_sfx_requested(sfx_name: String, _pos: Vector2) -> void:
	if not sfx_streams.has(sfx_name):
		return
		
	var stream = sfx_streams[sfx_name]
	# Find an available player
	for p in player_pool:
		if not p.playing:
			p.stream = stream
			p.play()
			return
			
	# If all busy, steal the oldest
	player_pool[0].stream = stream
	player_pool[0].play()
