class_name LevelLoaderService
extends RefCounted

## Service responsible for loading level assets, building verified polygon collision geometry,
## and providing verified platform spawn and docking coordinates.

const METADATA_PATH: String = "res://src/environment/assets/level_metadata.json"
const COLLISION_DATA_PATH: String = "res://src/environment/assets/level_collision_data.json"

static var _cached_metadata: Dictionary = {}
static var _cached_collision: Dictionary = {}

static func get_level_data(level_id: int) -> Dictionary:
	if _cached_metadata.is_empty():
		var file = FileAccess.open(METADATA_PATH, FileAccess.READ)
		if not file:
			push_error("Cannot open level metadata file: " + METADATA_PATH)
			return {}
		var json_str = file.get_as_text()
		_cached_metadata = JSON.parse_string(json_str)
		
	var key = str(level_id)
	if _cached_metadata.has(key):
		return _cached_metadata[key]
	return {}

static func get_level_platforms(level_id: int) -> Array:
	var data = get_level_data(level_id)
	if data.has("platforms"):
		return data["platforms"]
	return []

## Builds complete solid collision body from verified contour dataset
static func build_collision_body(level_id: int, map_width: int, map_height: int) -> StaticBody2D:
	var body = StaticBody2D.new()
	body.name = "TerrainCollider"
	body.collision_layer = 2
	body.collision_mask = 1
	
	if _cached_collision.is_empty():
		var col_file = FileAccess.open(COLLISION_DATA_PATH, FileAccess.READ)
		if col_file:
			_cached_collision = JSON.parse_string(col_file.get_as_text())
		else:
			push_error("Cannot open level collision data file: " + COLLISION_DATA_PATH)
			
	var key = str(level_id)
	if _cached_collision.has(key):
		var polys = _cached_collision[key]
		for poly_pts in polys:
			if poly_pts.size() >= 3:
				var col_poly = CollisionPolygon2D.new()
				var packed_pts = PackedVector2Array()
				packed_pts.resize(poly_pts.size())
				for i in range(poly_pts.size()):
					packed_pts[i] = Vector2(poly_pts[i][0], poly_pts[i][1])
				col_poly.polygon = packed_pts
				col_poly.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
				body.add_child(col_poly)
				
	# Add solid platform segment colliders
	var platforms = get_level_platforms(level_id)
	for plat in platforms:
		var plat_poly = CollisionPolygon2D.new()
		plat_poly.polygon = PackedVector2Array([
			Vector2(plat["x_start"], plat["y"]),
			Vector2(plat["x_end"], plat["y"]),
			Vector2(plat["x_end"], plat["y"] + plat["height"]),
			Vector2(plat["x_start"], plat["y"] + plat["height"])
		])
		plat_poly.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
		body.add_child(plat_poly)
				
	# Add perimeter boundary walls
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
