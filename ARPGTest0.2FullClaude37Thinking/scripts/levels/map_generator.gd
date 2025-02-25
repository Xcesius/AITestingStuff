class_name MapGenerator
extends Node

signal map_generated(map_data)

@export_category("Map Settings")
@export var map_width: int = 50
@export var map_height: int = 50
@export var room_min_size: int = 5
@export var room_max_size: int = 12
@export var max_rooms: int = 15
@export var min_room_distance: int = 2

@export_category("Decoration Settings")
@export var decoration_density: float = 0.1
@export var enemy_density: float = 0.05
@export var item_density: float = 0.03

var tilemap: TileMap
var rooms: Array[Rect2] = []
var corridors: Array[Array] = []

enum TileType {
    WALL,
    FLOOR,
    DOOR,
    WATER,
    GRASS
}

func _ready() -> void:
    tilemap = get_parent() as TileMap

func generate_map() -> void:
    # Clear existing map
    if tilemap:
        tilemap.clear()
    
    rooms.clear()
    corridors.clear()
    
    # Generate rooms
    for i in range(max_rooms):
        var w = randi_range(room_min_size, room_max_size)
        var h = randi_range(room_min_size, room_max_size)
        var x = randi_range(1, map_width - w - 1)
        var y = randi_range(1, map_height - h - 1)
        
        var new_room = Rect2(x, y, w, h)
        var can_place = true
        
        # Check if room overlaps with existing rooms or is too close
        for existing_room in rooms:
            if new_room.intersects(existing_room, true):
                can_place = false
                break
                
            # Check minimum distance between rooms
            var expanded_room = existing_room.grow(min_room_distance)
            if expanded_room.intersects(new_room, true):
                can_place = false
                break
        
        if can_place:
            _create_room(new_room)
            
            if rooms.size() > 0:
                # Connect to previous room
                var prev_room_center = _get_room_center(rooms.back())
                var new_room_center = _get_room_center(new_room)
                
                # Store corridor positions for later use
                var corridor_points = []
                
                # 50% chance to start with horizontal corridor
                if randi() % 2 == 0:
                    corridor_points.append_array(_create_h_corridor(prev_room_center.x, new_room_center.x, prev_room_center.y))
                    corridor_points.append_array(_create_v_corridor(prev_room_center.y, new_room_center.y, new_room_center.x))
                else:
                    corridor_points.append_array(_create_v_corridor(prev_room_center.y, new_room_center.y, prev_room_center.x))
                    corridor_points.append_array(_create_h_corridor(prev_room_center.x, new_room_center.x, new_room_center.y))
                
                corridors.append(corridor_points)
            
            rooms.append(new_room)
    
    # Add doors between rooms and corridors
    _place_doors()
    
    # Add decorations
    _place_decorations()
    
    # Place player in first room
    var player_pos = _get_room_center(rooms.front())
    # Place exit in last room
    var exit_pos = _get_room_center(rooms.back())
    
    # Place enemies and items
    _place_enemies()
    _place_items()
    
    emit_signal("map_generated", {
        "rooms": rooms,
        "corridors": corridors,
        "player_start": player_pos,
        "exit_pos": exit_pos
    })

func _create_room(room: Rect2) -> void:
    # Fill room with floor tiles
    for x in range(room.position.x, room.end.x):
        for y in range(room.position.y, room.end.y):
            tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(1, 1))  # Floor tile
    
    # Add walls around the room
    for x in range(room.position.x - 1, room.end.x + 1):
        tilemap.set_cell(0, Vector2i(x, room.position.y - 1), 0, Vector2i(0, 0))  # Wall tile
        tilemap.set_cell(0, Vector2i(x, room.end.y), 0, Vector2i(0, 0))  # Wall tile
    
    for y in range(room.position.y, room.end.y):
        tilemap.set_cell(0, Vector2i(room.position.x - 1, y), 0, Vector2i(0, 0))  # Wall tile
        tilemap.set_cell(0, Vector2i(room.end.x, y), 0, Vector2i(0, 0))  # Wall tile

func _get_room_center(room: Rect2) -> Vector2:
    return Vector2(
        room.position.x + room.size.x / 2,
        room.position.y + room.size.y / 2
    )

func _create_h_corridor(x1: int, x2: int, y: int) -> Array:
    var corridor_points = []
    for x in range(min(x1, x2), max(x1, x2) + 1):
        tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(1, 1))  # Floor tile
        corridor_points.append(Vector2i(x, y))
        
        # Add walls if there's no floor already
        if tilemap.get_cell_source_id(0, Vector2i(x, y - 1)) == -1:
            tilemap.set_cell(0, Vector2i(x, y - 1), 0, Vector2i(0, 0))  # Wall above
        
        if tilemap.get_cell_source_id(0, Vector2i(x, y + 1)) == -1:
            tilemap.set_cell(0, Vector2i(x, y + 1), 0, Vector2i(0, 0))  # Wall below
    
    return corridor_points

func _create_v_corridor(y1: int, y2: int, x: int) -> Array:
    var corridor_points = []
    for y in range(min(y1, y2), max(y1, y2) + 1):
        tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(1, 1))  # Floor tile
        corridor_points.append(Vector2i(x, y))
        
        # Add walls if there's no floor already
        if tilemap.get_cell_source_id(0, Vector2i(x - 1, y)) == -1:
            tilemap.set_cell(0, Vector2i(x - 1, y), 0, Vector2i(0, 0))  # Wall left
        
        if tilemap.get_cell_source_id(0, Vector2i(x + 1, y)) == -1:
            tilemap.set_cell(0, Vector2i(x + 1, y), 0, Vector2i(0, 0))  # Wall right
    
    return corridor_points

func _place_doors() -> void:
    # Find potential door locations: floor tiles with exactly 2 adjacent walls and 2 adjacent floor tiles
    for corridor in corridors:
        for point in corridor:
            var adjacent_walls = 0
            var adjacent_floors = 0
            
            # Check cardinal directions
            var directions = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
            for dir in directions:
                var check_pos = point + dir
                var cell_id = tilemap.get_cell_source_id(0, check_pos)
                
                if cell_id == 0 and tilemap.get_cell_atlas_coords(0, check_pos) == Vector2i(0, 0):
                    adjacent_walls += 1
                elif cell_id == 0 and tilemap.get_cell_atlas_coords(0, check_pos) == Vector2i(1, 1):
                    adjacent_floors += 1
            
            # If we have exactly 2 walls and 2 floors, and they're opposite each other, this is a doorway
            if adjacent_walls == 2 and adjacent_floors == 2:
                # 20% chance to place a door
                if randf() < 0.2:
                    tilemap.set_cell(0, point, 0, Vector2i(2, 0))  # Door tile

func _place_decorations() -> void:
    # Place decorations in rooms (not corridors)
    for room in rooms:
        # Skip a few tiles from the edges
        for x in range(room.position.x + 1, room.end.x - 1):
            for y in range(room.position.y + 1, room.end.y - 1):
                if randf() < decoration_density:
                    # 70% chance for light decoration, 30% for heavy decoration
                    if randf() < 0.7:
                        tilemap.set_cell(1, Vector2i(x, y), 0, Vector2i(0, 2))  # Light decoration
                    else:
                        tilemap.set_cell(1, Vector2i(x, y), 0, Vector2i(1, 2))  # Heavy decoration

func _place_enemies() -> void:
    # Simple placeholder for enemy placement
    for room in rooms:
        # Skip first and last room (player start and exit)
        if room == rooms.front() or room == rooms.back():
            continue
            
        # Calculate how many enemies to place based on room size and density
        var room_area = room.size.x * room.size.y
        var enemy_count = int(room_area * enemy_density)
        
        # Ensure at least one enemy per room unless it's tiny
        enemy_count = max(enemy_count, 1 if room_area > 25 else 0)
        
        # Place the enemies
        for i in range(enemy_count):
            var x = randi_range(room.position.x + 1, room.end.x - 2)
            var y = randi_range(room.position.y + 1, room.end.y - 2)
            
            # Signal to spawn enemy at position (x, y)
            # This would be implemented in the level manager
            print("Enemy at: ", Vector2(x, y))

func _place_items() -> void:
    # Simple placeholder for item placement
    for room in rooms:
        # Calculate how many items to place based on room size and density
        var room_area = room.size.x * room.size.y
        var item_count = int(room_area * item_density)
        
        # Place the items
        for i in range(item_count):
            var x = randi_range(room.position.x + 1, room.end.x - 2)
            var y = randi_range(room.position.y + 1, room.end.y - 2)
            
            # Signal to spawn item at position (x, y)
            # This would be implemented in the level manager
            print("Item at: ", Vector2(x, y))

func get_random_position_in_room(room_index: int = -1) -> Vector2:
    if rooms.size() == 0:
        return Vector2.ZERO
        
    var room: Rect2
    if room_index == -1 or room_index >= rooms.size():
        # Get random room
        room = rooms[randi() % rooms.size()]
    else:
        room = rooms[room_index]
    
    return Vector2(
        randi_range(room.position.x + 1, room.end.x - 2),
        randi_range(room.position.y + 1, room.end.y - 2)
    ) 