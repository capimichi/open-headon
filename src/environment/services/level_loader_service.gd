class_name LevelLoaderService
extends RefCounted

## Service responsible for loading level assets, building polygon collision geometry,
## and providing verified platform spawn coordinates.

const METADATA_PATH: String = "res://src/environment/assets/level_metadata.json"

static func get_level_data(level_id: int) -> Dictionary:
	var file = FileAccess.open(METADATA_PATH, FileAccess.READ)
	if not file:
		push_error("Cannot open level metadata file: " + METADATA_PATH)
		return {}
	var json_str = file.get_as_text()
	var json_data = JSON.parse_string(json_str)
	var key = str(level_id)
	if json_data and json_data.has(key):
		return json_data[key]
	return {}

## Builds solid collision bodies from level_solid mask using BitMap polygon extraction
static func build_collision_body(solid_mask_path: String, map_width: int, map_height: int) -> StaticBody2D:
	var body = StaticBody2D.new()
	body.name = "TerrainCollider"
	body.collision_layer = 2
	body.collision_mask = 1
	
	# 1. Convert solid mask image into polygon contours
	var img = Image.load_from_file(ProjectSettings.globalize_path(solid_mask_path))
	if img:
		var bitmap = BitMap.new()
		bitmap.create_from_image_alpha(img, 0.5)
		
		# Epsilon 2.0 produces optimized, faithful polygon boundaries
		var polygons = bitmap.opaque_to_polygons(Rect2i(0, 0, map_width, map_height), 2.0)
		for poly in polygons:
			if poly.size() >= 3:
				var col_poly = CollisionPolygon2D.new()
				col_poly.polygon = poly
				body.add_child(col_poly)
				
	# 2. Add impenetrable perimeter boundaries (100px thick boxes around the world)
	_add_perimeter_walls(body, map_width, map_height)
	
	return body

static func _add_perimeter_walls(body: StaticBody2D, w: int, h: int) -> void:
	var thickness = 100.0
	
	# Top wall
	var top = CollisionShape2D.new()
	var top_box = RectangleShape2D.new()
	top_box.size = Vector2(w + thickness * 2, thickness)
	top.shape = top_box
	top.position = Vector2(w / 2.0, -thickness / 2.0)
	body.add_child(top)
	
	# Bottom wall
	var bottom = CollisionShape2D.new()
	var bottom_box = RectangleShape2D.new()
	bottom_box.size = Vector2(w + thickness * 2, thickness)
	bottom.shape = bottom_box
	bottom.position = Vector2(w / 2.0, h + thickness / 2.0)
	body.add_child(bottom)
	
	# Left wall
	var left = CollisionShape2D.new()
	var left_box = RectangleShape2D.new()
	left_box.size = Vector2(thickness, h + thickness * 2)
	left.shape = left_box
	left.position = Vector2(-thickness / 2.0, h / 2.0)
	body.add_child(left)
	
	# Right wall
	var right = CollisionShape2D.new()
	var right_box = RectangleShape2D.new()
	right_box.size = Vector2(thickness, h + thickness * 2)
	right.shape = right_box
	right.position = Vector2(w + thickness / 2.0, h / 2.0)
	body.add_child(right)
