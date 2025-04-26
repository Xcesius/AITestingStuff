extends Node2D

var room_generator: RoomGenerator
var map_renderer: MapRenderer

func _ready() -> void:
	# Define the map bounds (origin and size)
	var map_bounds := Rect2i(Vector2i(0, 0), Vector2i(50, 50))
	room_generator = RoomGenerator.new(map_bounds, 1234)
	var rooms := room_generator.generate_rooms(10)
	map_renderer = $MapRenderer  # assumes a child MapRenderer node in the scene
	map_renderer.render_rooms(rooms) 