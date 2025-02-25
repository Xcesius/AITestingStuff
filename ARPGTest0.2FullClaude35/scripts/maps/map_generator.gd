class_name MapGenerator
extends Node

signal generation_completed

@export var min_room_size: Vector2i = Vector2i(6, 6)
@export var max_room_size: Vector2i = Vector2i(10, 10)
@export var map_size: Vector2i = Vector2i(50, 50)
@export var num_rooms: int = 15
@export var min_room_distance: int = 2

@onready var tilemap: TileMap = $TileMap

class Room:
    var position: Vector2i
    var size: Vector2i
    var center: Vector2i
    
    func _init(pos: Vector2i, s: Vector2i) -> void:
        position = pos
        size = s
        center = position + size / 2
    
    func intersects(other: Room, min_distance: int) -> bool:
        return not (position.x + size.x + min_distance < other.position.x or
                   other.position.x + other.size.x + min_distance < position.x or
                   position.y + size.y + min_distance < other.position.y or
                   other.position.y + other.size.y + min_distance < position.y)

var rooms: Array[Room] = []

func _ready() -> void:
    generate_dungeon()

func generate_dungeon() -> void:
    rooms.clear()
    clear_map()
    
    # Generate rooms
    var attempts = 0
    var max_attempts = 100
    
    while rooms.size() < num_rooms and attempts < max_attempts:
        var room = _generate_room()
        var valid = true
        
        for existing_room in rooms:
            if room.intersects(existing_room, min_room_distance):
                valid = false
                break
        
        if valid:
            rooms.append(room)
            _place_room(room)
        
        attempts += 1
    
    # Connect rooms
    if rooms.size() > 1:
        var mst = _generate_mst()
        for connection in mst:
            _connect_rooms(rooms[connection[0]], rooms[connection[1]])
    
    # Place doors and decorations
    _place_doors()
    _place_decorations()
    
    emit_signal("generation_completed")

func clear_map() -> void:
    tilemap.clear()

func _generate_room() -> Room:
    var size = Vector2i(
        randi_range(min_room_size.x, max_room_size.x),
        randi_range(min_room_size.y, max_room_size.y)
    )
    
    var position = Vector2i(
        randi_range(1, map_size.x - size.x - 1),
        randi_range(1, map_size.y - size.y - 1)
    )
    
    return Room.new(position, size)

func _place_room(room: Room) -> void:
    # Fill floor
    for x in range(room.position.x, room.position.x + room.size.x):
        for y in range(room.position.y, room.position.y + room.size.y):
            tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(1, 1))  # Floor tile
    
    # Place walls
    for x in range(room.position.x - 1, room.position.x + room.size.x + 1):
        tilemap.set_cell(0, Vector2i(x, room.position.y - 1), 0, Vector2i(0, 0))  # Wall tile
        tilemap.set_cell(0, Vector2i(x, room.position.y + room.size.y), 0, Vector2i(0, 0))
    
    for y in range(room.position.y - 1, room.position.y + room.size.y + 1):
        tilemap.set_cell(0, Vector2i(room.position.x - 1, y), 0, Vector2i(0, 0))
        tilemap.set_cell(0, Vector2i(room.position.x + room.size.x, y), 0, Vector2i(0, 0))

func _generate_mst() -> Array:
    var points = []
    var connections = []
    
    # Create points array with indices
    for i in range(rooms.size()):
        points.append(i)
    
    # Prim's algorithm
    var connected = [0]
    var candidates = []
    
    while connected.size() < points.size():
        # Find all possible connections from connected rooms
        for from_idx in connected:
            for to_idx in points:
                if to_idx in connected:
                    continue
                
                var distance = rooms[from_idx].center.distance_to(rooms[to_idx].center)
                candidates.append([from_idx, to_idx, distance])
        
        # Find shortest connection
        var shortest = candidates[0]
        var shortest_idx = 0
        
        for i in range(candidates.size()):
            if candidates[i][2] < shortest[2]:
                shortest = candidates[i]
                shortest_idx = i
        
        # Add connection
        connections.append([shortest[0], shortest[1]])
        connected.append(shortest[1])
        candidates.remove_at(shortest_idx)
    
    return connections

func _connect_rooms(from_room: Room, to_room: Room) -> void:
    var start = from_room.center
    var end = to_room.center
    
    # Create L-shaped corridor
    var corner = Vector2i(start.x, end.y)
    
    # Horizontal corridor
    var x_start = min(start.x, corner.x)
    var x_end = max(start.x, corner.x)
    for x in range(x_start, x_end + 1):
        _place_corridor_tile(Vector2i(x, start.y))
    
    # Vertical corridor
    var y_start = min(corner.y, end.y)
    var y_end = max(corner.y, end.y)
    for y in range(y_start, y_end + 1):
        _place_corridor_tile(Vector2i(corner.x, y))

func _place_corridor_tile(pos: Vector2i) -> void:
    tilemap.set_cell(0, pos, 0, Vector2i(1, 1))  # Floor tile
    
    # Place walls around corridor
    for x in range(pos.x - 1, pos.x + 2):
        for y in range(pos.y - 1, pos.y + 2):
            if tilemap.get_cell_source_id(0, Vector2i(x, y)) == -1:
                tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))  # Wall tile

func _place_doors() -> void:
    # Implementation depends on your tileset and door mechanics
    pass

func _place_decorations() -> void:
    # Implementation depends on your decoration tiles and placement rules
    pass 