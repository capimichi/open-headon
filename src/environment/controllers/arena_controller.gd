class_name ArenaController
extends Node2D

## Arena Controller managing dynamic level loading, terrain collision, and 2-Player Split Screen.

@export var current_level_id: int = 0

var ship_scene = preload("res://src/ship/views/ship.tscn")

var ship_p1: ShipController = null
var ship_p2: ShipController = null

@onready var viewport1: SubViewport = $CanvasLayer/SplitContainer/ViewportContainerP1/ViewportP1
@onready var viewport2: SubViewport = $CanvasLayer/SplitContainer/ViewportContainerP2/ViewportP2
@onready var world_root: Node2D = $CanvasLayer/SplitContainer/ViewportContainerP1/ViewportP1/WorldRoot
@onready var camera_p1: Camera2D = $CanvasLayer/SplitContainer/ViewportContainerP1/ViewportP1/CameraP1
@onready var camera_p2: Camera2D = $CanvasLayer/SplitContainer/ViewportContainerP2/ViewportP2/CameraP2

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
	
	# 1. Viewport 2 shares the 2D world space of Viewport 1
	viewport2.world_2d = viewport1.world_2d
	
	# 2. Clean previous world nodes
	for child in world_root.get_children():
		child.queue_free()
		
	# 3. Add Level Background Texture
	var bg_sprite = Sprite2D.new()
	bg_sprite.name = "Background"
	bg_sprite.texture = load(data["map_texture"])
	bg_sprite.centered = false
	world_root.add_child(bg_sprite)
	
	# 4. Add Level Solid Terrain Polygons & Boundaries
	var collider = LevelLoaderService.build_collision_body(level_id, map_w, map_h)
	world_root.add_child(collider)
	
	# 5. Spawn Ships on Platform Coordinates
	var spawns = data["spawns"]
	var platforms = LevelLoaderService.get_level_platforms(level_id)
	
	ship_p1 = ship_scene.instantiate() as ShipController
	ship_p1.player_id = 1
	ship_p1.player_tint = Color(0.3, 1.0, 0.4) # Green
	ship_p1.position = Vector2(spawns[0]["x"], spawns[0]["y"])
	ship_p1.set_active_platforms(platforms)
	world_root.add_child(ship_p1)
	
	ship_p2 = ship_scene.instantiate() as ShipController
	ship_p2.player_id = 2
	ship_p2.player_tint = Color(1.0, 0.25, 0.25) # Red
	ship_p2.position = Vector2(spawns[1]["x"], spawns[1]["y"])
	ship_p2.set_active_platforms(platforms)
	world_root.add_child(ship_p2)
	
	# 6. Configure Camera limits and immediate focus
	camera_p1.limit_left = 0
	camera_p1.limit_top = 0
	camera_p1.limit_right = map_w
	camera_p1.limit_bottom = map_h
	camera_p1.position = ship_p1.position
	camera_p1.reset_smoothing()
	camera_p1.make_current()
	
	camera_p2.limit_left = 0
	camera_p2.limit_top = 0
	camera_p2.limit_right = map_w
	camera_p2.limit_bottom = map_h
	camera_p2.position = ship_p2.position
	camera_p2.reset_smoothing()
	camera_p2.make_current()
	
	EventBus.level_loaded.emit(level_id)

func _process(_delta: float) -> void:
	if is_instance_valid(ship_p1) and is_instance_valid(camera_p1):
		camera_p1.position = ship_p1.position
		
	if is_instance_valid(ship_p2) and is_instance_valid(camera_p2):
		camera_p2.position = ship_p2.position
