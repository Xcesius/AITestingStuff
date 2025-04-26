extends Node
class_name RoomGenerator

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var map_bounds: Rect2i
var seed_value: int = 1234
var min_room_size: int = 4
var max_room_size: int = 10

func _init(_map_bounds: Rect2i, _seed: int = 1234) -> void:
	map_bounds = _map_bounds
	seed_value = _seed
	rng.seed = seed_value

func generate_rooms(room_count: int) -> Array[Room]:
	var rooms: Array[Room] = []
	for i in range(room_count):
		var width := rng.randi_range(min_room_size, max_room_size)
		var height := rng.randi_range(min_room_size, max_room_size)
		var max_x := map_bounds.position.x + map_bounds.size.x - width
		var max_y := map_bounds.position.y + map_bounds.size.y - height
		var pos_x := rng.randi_range(map_bounds.position.x, max_x)
		var pos_y := rng.randi_range(map_bounds.position.y, max_y)
		var pos := Vector2i(pos_x, pos_y)
		var metadata := {"name": "Room_%s" % i}
		var room := Room.new(i, pos, Vector2i(width, height), metadata)
		rooms.push_back(room)
	return rooms 