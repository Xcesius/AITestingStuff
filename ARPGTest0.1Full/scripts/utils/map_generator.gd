extends Node
class_name MapGenerator

class Room:
    var x: int
    var y: int
    var width: int
    var height: int
    
    func _init(p_x: int, p_y: int, p_width: int, p_height: int) -> void:
        x = p_x
        y = p_y
        width = p_width
        height = p_height
    
    func center() -> Vector2:
        return Vector2(x + width / 2, y + height / 2)
    
    func intersects(other: Room) -> bool:
        return (x <= other.x + other.width and x + width >= other.x and
                y <= other.y + other.height and y + height >= other.y)

var rng = RandomNumberGenerator.new()
var rooms: Array[Room] = []
var min_room_size: int = 6
var max_room_size: int = 12
var map_width: int = 50
var max_rooms: int = 15

func _init() -> void:
    rng.randomize()

func generate_dungeon(tilemap: TileMap) -> Array[Room]:
    rooms.clear()
    
    for _i in range(max_rooms):
        var width = rng.randi_range(min_room_size, max_room_size)
        var height = rng.randi_range(min_room_size, max_room_size)
        var x = rng.randi_range(1, map_width - width - 1)
        var y = rng.randi_range(1, map_width - height - 1)
        
        var new_room = Room.new(x, y, width, height)
        var can_place = true
        
        for room in rooms:
            if new_room.intersects(room):
                can_place = false
                break
        
        if can_place:
            create_room(new_room, tilemap)
            
            if rooms.size() > 0:
                var new_center = new_room.center()
                var prev_center = rooms[-1].center()
                
                # Create corridors
                if rng.randi_range(0, 1) == 1:
                    create_horizontal_corridor(tilemap, prev_center.x, new_center.x, prev_center.y)
                    create_vertical_corridor(tilemap, prev_center.y, new_center.y, new_center.x)
                else:
                    create_vertical_corridor(tilemap, prev_center.y, new_center.y, prev_center.x)
                    create_horizontal_corridor(tilemap, prev_center.x, new_center.x, new_center.y)
            
            rooms.append(new_room)
    
    return rooms

func create_room(room: Room, tilemap: TileMap) -> void:
    for x in range(room.x, room.x + room.width):
        for y in range(room.y, room.y + room.height):
            tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))

func create_horizontal_corridor(tilemap: TileMap, x1: float, x2: float, y: float) -> void:
    for x in range(min(x1, x2), max(x1, x2) + 1):
        tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))

func create_vertical_corridor(tilemap: TileMap, y1: float, y2: float, x: float) -> void:
    for y in range(min(y1, y2), max(y1, y2) + 1):
        tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))

func get_random_room() -> Room:
    if rooms.is_empty():
        return null
    return rooms[rng.randi() % rooms.size()]

func get_room_positions() -> Array[Vector2]:
    var positions: Array[Vector2] = []
    for room in rooms:
        positions.append(room.center())
    return positions 