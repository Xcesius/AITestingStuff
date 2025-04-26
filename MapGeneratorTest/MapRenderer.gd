extends Node2D
class_name MapRenderer

@export var tilemap_layer_path: NodePath
@onready var tilemap_layer: TileMapLayer = get_node(tilemap_layer_path)

var floor_source_id: int = 0
var wall_source_id: int = 1
var atlas_coords := Vector2i(0, 0)  # Default atlas coordinates
var alternative_tile: int = 0       # Default alternative tile

func render_rooms(rooms: Array[Room]) -> void:
	for room in rooms:
		render_room(room)
	# Force update the TileMapLayer
	tilemap_layer.update_internals()

func render_room(room: Room) -> void:
	# Render floor tiles inside the room
	for x in range(room.position.x, room.position.x + room.size.x):
		for y in range(room.position.y, room.position.y + room.size.y):
			tilemap_layer.set_cell(Vector2i(x, y), floor_source_id, atlas_coords, alternative_tile)
	
	# Render walls around the room: top & bottom
	for x in range(room.position.x - 1, room.position.x + room.size.x + 1):
		tilemap_layer.set_cell(Vector2i(x, room.position.y - 1), wall_source_id, atlas_coords, alternative_tile)
		tilemap_layer.set_cell(Vector2i(x, room.position.y + room.size.y), wall_source_id, atlas_coords, alternative_tile)
	
	# Render walls: left & right sides
	for y in range(room.position.y, room.position.y + room.size.y):
		tilemap_layer.set_cell(Vector2i(room.position.x - 1, y), wall_source_id, atlas_coords, alternative_tile)
		tilemap_layer.set_cell(Vector2i(room.position.x + room.size.x, y), wall_source_id, atlas_coords, alternative_tile) 