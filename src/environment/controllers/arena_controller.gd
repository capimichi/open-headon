class_name ArenaController
extends Node2D

## Arena Controller managing dynamic level loading, terrain collision, and 2-Player Split Screen.

@export var current_level_id: int = 0

var ship_scene = preload("res://src/ship/views/ship.tscn")

var ship_p1: ShipController = null
var ship_p2: ShipController = null

var camera_p1: Camera2D = null
var camera_p2: Camera2D = null

@onready var split_container: HBoxContainer = $CanvasLayer/SplitContainer
@onready var viewport1: SubViewport = $CanvasLayer/SplitContainer/ViewportContainerP1/ViewportP1
@onready var viewport2: SubViewport = $CanvasLayer/SplitContainer/ViewportContainerP2/ViewportP2
@onready var world_root: Node2D = $WorldRoot

func _ready() -> void:
	load_level(current_level_id)

func load_level(level_id: int) -> void:
	current_level_id = level_id
	var data = LevelLoaderService.get_level_data(level_id)
	if data.is_empty():
		push_error("Failed to retrieve data for level " + str(level_id))
		return
		
	var map_w = data["width"]
	var map_h = data["height"]
	
	# 1. Clean previous world nodes
	for child in world_root.get_children():
		child.queue_free()
		
	# 2. Add Level Background Texture
	var bg_sprite = Sprite2D.new()
	bg_sprite.name = "Background"
	bg_sprite.texture = load(data["map_texture"])
	bg_sprite.centered = false
	world_root.add_child(bg_sprite)
	
	# 3. Add Level Solid Terrain Polygons & Boundaries
	var collider = LevelLoaderService.build_collision_body(data["solid_mask"], map_w, map_h)
	world_root.add_child(collider)
	
	# 4. Spawn Ships on Platform Coordinates
	var spawns = data["spawns"]
	
	ship_p1 = ship_scene.instantiate() as ShipController
	ship_p1.player_id = 1
	ship_p1.player_tint = Color(0.3, 1.0, 0.4) # Green
	ship_p1.position = Vector2(spawns[0]["x"], spawns[0]["y"])
	world_root.add_child(ship_p1)
	
	ship_p2 = ship_scene.instantiate() as ShipController
	ship_p2.player_id = 2
	ship_p2.player_tint = Color(1.0, 0.25, 0.25) # Red
	ship_p2.position = Vector2(spawns[1]["x"], spawns[1]["y"])
	world_root.add_child(ship_p2)
	
	# 5. Configure Split Screen SubViewports to share the same World2D
	viewport2.world_2d = viewport1.world_2d
	
	# Setup Camera for Player 1
	camera_p1 = Camera2D.new()
	camera_p1.limit_left = 0
	camera_p1.limit_top = 0
	camera_p1.limit_right = map_w
	camera_p1.limit_bottom = map_h
	camera_p1.position_smoothing_enabled = true
	camera_p1.position_smoothing_speed = 10.0
	viewport1.add_child(camera_p1)
	
	# Setup Camera for Player 2
	camera_p2 = Camera2D.new()
	camera_p2.limit_left = 0
	camera_p2.limit_top = 0
	camera_p2.limit_right = map_w
	camera_p2.limit_bottom = map_h
	camera_p2.position_smoothing_enabled = true
	camera_p2.position_smoothing_speed = 10.0
	viewport2.add_child(camera_p2)
	
	EventBus.level_loaded.emit(level_id)

func _process(_delta: float) -> void:
	# Cameras follow their respective ships in the shared world
	if is_instance_valid(ship_p1) and is_instance_valid(camera_p1):
		camera_p1.global_position = ship_p1.global_position
		
	if is_instance_valid(ship_p2) and is_instance_valid(camera_p2):
		camera_p2.global_position = ship_p2.global_position
