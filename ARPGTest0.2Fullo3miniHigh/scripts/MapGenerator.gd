# MapGenerator.gd
extends Node2D

# Parameters for dungeon generation – replace placeholders with actual config values
export var map_width = [MAP_WIDTH]
export var map_height = [MAP_HEIGHT]
export var room_min_size = [ROOM_MIN_SIZE]
export var room_max_size = [ROOM_MAX_SIZE]
export var max_rooms = [MAX_ROOMS]

var rooms = []

func _ready():
    generate_map()

func generate_map():
    rooms.clear()
    for i in range(max_rooms):
        var room_size = Vector2(
            randi() % (room_max_size - room_min_size + 1) + room_min_size,
            randi() % (room_max_size - room_min_size + 1) + room_min_size
        )
        var room_pos = Vector2(
            randi() % (map_width - room_size.x),
            randi() % (map_height - room_size.y)
        )
        var new_room = Rect2(room_pos, room_size)
        var overlaps = false
        for other in rooms:
            if new_room.intersects(other):
                overlaps = true
                break
        if not overlaps:
            rooms.append(new_room)
            create_room(new_room)

func create_room(room_rect: Rect2):
    # Pseudo-code: Draw room floor cells in TileMap node
    for x in range(int(room_rect.position.x), int(room_rect.position.x + room_rect.size.x)):
        for y in range(int(room_rect.position.y), int(room_rect.position.y + room_rect.size.y)):
            $TileMap.set_cell(x, y, 0)  # Use cell index 0 as floor (adjust as needed) 