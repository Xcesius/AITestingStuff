class_name LevelManager
extends Node2D

signal level_generated
signal player_spawned(player_instance, position)
signal exit_spawned(position)
signal enemy_spawned(enemy_instance, position)
signal item_spawned(item_instance, position)

@export var player_scene: PackedScene
@export var exit_scene: PackedScene
@export var tilemap: TileMap
@export var map_generator: MapGenerator
@export_category("Enemy Spawning")
@export var enemy_scenes: Array[PackedScene] = []
@export_category("Item Spawning")
@export var common_item_scenes: Array[PackedScene] = []
@export var rare_item_scenes: Array[PackedScene] = []
@export var chest_scene: PackedScene

var current_level: int = 1
var player_instance: CharacterBody2D
var map_data: Dictionary
var enemy_instances: Array[CharacterBody2D] = []
var item_instances: Array[Node2D] = []

func _ready() -> void:
    if map_generator:
        map_generator.connect("map_generated", _on_map_generated)
        
func generate_level(level_number: int = 1) -> void:
    current_level = level_number
    
    # Clear existing entities
    _clear_entities()
    
    # Generate the map
    if map_generator:
        map_generator.generate_map()
    else:
        printerr("No MapGenerator assigned to LevelManager!")

func _on_map_generated(data: Dictionary) -> void:
    map_data = data
    
    # Spawn player at start position
    _spawn_player(data.player_start)
    
    # Spawn exit at exit position
    _spawn_exit(data.exit_pos)
    
    # Spawn enemies and items
    _spawn_enemies()
    _spawn_items()
    
    emit_signal("level_generated")

func _clear_entities() -> void:
    # Remove all existing enemies
    for enemy in enemy_instances:
        if is_instance_valid(enemy):
            enemy.queue_free()
    enemy_instances.clear()
    
    # Remove all existing items
    for item in item_instances:
        if is_instance_valid(item):
            item.queue_free()
    item_instances.clear()
    
    # Only clear player if it exists and we're not continuing the game
    if player_instance and current_level == 1:
        player_instance.queue_free()
        player_instance = null

func _spawn_player(position: Vector2) -> void:
    if not player_scene:
        printerr("No player scene assigned!")
        return
        
    if not player_instance:
        player_instance = player_scene.instantiate() as CharacterBody2D
        add_child(player_instance)
    
    player_instance.global_position = tilemap.map_to_local(Vector2i(position))
    emit_signal("player_spawned", player_instance, player_instance.global_position)

func _spawn_exit(position: Vector2) -> void:
    if not exit_scene:
        printerr("No exit scene assigned!")
        return
        
    var exit = exit_scene.instantiate()
    add_child(exit)
    exit.global_position = tilemap.map_to_local(Vector2i(position))
    emit_signal("exit_spawned", exit.global_position)
    
    # Connect to exit signal
    if exit.has_signal("player_entered"):
        exit.connect("player_entered", _on_exit_entered)

func _on_exit_entered() -> void:
    # Proceed to next level
    current_level += 1
    generate_level(current_level)

func _spawn_enemies() -> void:
    if enemy_scenes.size() == 0:
        printerr("No enemy scenes assigned!")
        return
        
    # Place enemies in each room based on the map generator's enemy placement data
    for room in map_data.rooms:
        # Skip first and last room (player start and exit)
        if room == map_data.rooms.front() or room == map_data.rooms.back():
            continue
            
        # Calculate how many enemies to spawn based on room size
        var room_area = room.size.x * room.size.y
        var base_enemy_count = int(room_area * 0.05)  # 5% of room area
        
        # Scale by level difficulty
        var enemy_count = base_enemy_count + int(current_level * 0.5)
        
        # Ensure at least one enemy per room unless it's tiny
        enemy_count = max(enemy_count, 1 if room_area > 25 else 0)
        
        # Spawn the enemies
        for i in range(enemy_count):
            # Get random position in room
            var pos = Vector2(
                randi_range(room.position.x + 1, room.end.x - 2),
                randi_range(room.position.y + 1, room.end.y - 2)
            )
            
            # Select random enemy type based on difficulty
            var difficulty_index = min(current_level - 1, enemy_scenes.size() - 1)
            var enemy_index = randi_range(0, min(difficulty_index + 1, enemy_scenes.size() - 1))
            var enemy_scene = enemy_scenes[enemy_index]
            
            _spawn_enemy(enemy_scene, pos)

func _spawn_enemy(enemy_scene: PackedScene, position: Vector2) -> void:
    var enemy = enemy_scene.instantiate() as CharacterBody2D
    add_child(enemy)
    
    # Convert tilemap position to world position
    enemy.global_position = tilemap.map_to_local(Vector2i(position))
    
    # Scale enemy stats based on level
    if enemy.has_method("scale_difficulty"):
        enemy.scale_difficulty(current_level)
    
    enemy_instances.append(enemy)
    emit_signal("enemy_spawned", enemy, enemy.global_position)

func _spawn_items() -> void:
    if common_item_scenes.size() == 0 and chest_scene == null:
        return
        
    # Add some random items and chests to rooms
    for room in map_data.rooms:
        # Skip first room (player start)
        if room == map_data.rooms.front():
            continue
            
        # Calculate how many items to spawn based on room size
        var room_area = room.size.x * room.size.y
        var item_count = int(room_area * 0.03)  # 3% of room area
        
        # Spawn the items
        for i in range(item_count):
            # 30% chance for a chest instead of a regular item
            var spawn_chest = randf() < 0.3 and chest_scene != null
            
            # Get random position in room
            var pos = Vector2(
                randi_range(room.position.x + 1, room.end.x - 2),
                randi_range(room.position.y + 1, room.end.y - 2)
            )
            
            if spawn_chest:
                _spawn_chest(pos)
            else:
                _spawn_item(pos)

func _spawn_item(position: Vector2) -> void:
    if common_item_scenes.size() == 0:
        return
        
    # Determine rarity - 80% common, 20% rare
    var is_rare = randf() < 0.2 and rare_item_scenes.size() > 0
    
    var item_array = rare_item_scenes if is_rare else common_item_scenes
    var item_index = randi() % item_array.size()
    var item_scene = item_array[item_index]
    
    var item = item_scene.instantiate()
    add_child(item)
    
    # Convert tilemap position to world position
    item.global_position = tilemap.map_to_local(Vector2i(position))
    
    item_instances.append(item)
    emit_signal("item_spawned", item, item.global_position)

func _spawn_chest(position: Vector2) -> void:
    if not chest_scene:
        return
        
    var chest = chest_scene.instantiate()
    add_child(chest)
    
    # Convert tilemap position to world position
    chest.global_position = tilemap.map_to_local(Vector2i(position))
    
    # Scale chest loot based on level
    if chest.has_method("set_level"):
        chest.set_level(current_level)
    
    item_instances.append(chest)
    emit_signal("item_spawned", chest, chest.global_position)

func get_player_instance() -> CharacterBody2D:
    return player_instance

func get_enemies() -> Array[CharacterBody2D]:
    return enemy_instances

func get_nearest_enemy_to(position: Vector2, max_distance: float = 1000.0) -> CharacterBody2D:
    var nearest_enemy = null
    var nearest_distance = max_distance
    
    for enemy in enemy_instances:
        if is_instance_valid(enemy) and enemy.has_method("is_alive") and enemy.is_alive():
            var distance = position.distance_to(enemy.global_position)
            if distance < nearest_distance:
                nearest_distance = distance
                nearest_enemy = enemy
                
    return nearest_enemy 