class_name DungeonLevel
extends Node2D

@export var map_generator_path: NodePath
@export var tilemap_path: NodePath 
@export var player_scene: PackedScene
@export var exit_scene: PackedScene
@export var enemy_scenes: Array[PackedScene] = []
@export var common_item_scenes: Array[PackedScene] = []
@export var rare_item_scenes: Array[PackedScene] = []
@export var chest_scene: PackedScene
@export var auto_generate: bool = true
@export var starting_level: int = 1

var level_manager: LevelManager
var map_generator: MapGenerator
var tilemap: TileMap

func _ready() -> void:
    # Setup node references
    map_generator = get_node_or_null(map_generator_path)
    tilemap = get_node_or_null(tilemap_path)
    
    if not map_generator or not tilemap:
        printerr("Missing required components: MapGenerator or TileMap")
        return
    
    # Create and setup level manager
    level_manager = LevelManager.new()
    add_child(level_manager)
    
    level_manager.player_scene = player_scene
    level_manager.exit_scene = exit_scene
    level_manager.tilemap = tilemap
    level_manager.map_generator = map_generator
    level_manager.enemy_scenes = enemy_scenes
    level_manager.common_item_scenes = common_item_scenes
    level_manager.rare_item_scenes = rare_item_scenes
    level_manager.chest_scene = chest_scene
    
    # Connect signals
    level_manager.connect("level_generated", _on_level_generated)
    level_manager.connect("player_spawned", _on_player_spawned)
    
    # Generate the initial level if auto-generate is enabled
    if auto_generate:
        level_manager.generate_level(starting_level)

func _on_level_generated() -> void:
    print("Level ", level_manager.current_level, " generated")

func _on_player_spawned(player: CharacterBody2D, position: Vector2) -> void:
    # Example: Setup camera to follow player
    if player and player.has_node("Camera2D"):
        var camera = player.get_node("Camera2D")
        camera.make_current()
    
    print("Player spawned at: ", position)

func get_player() -> CharacterBody2D:
    return level_manager.get_player_instance()

func generate_new_level(level_number: int = 1) -> void:
    level_manager.generate_level(level_number)

func get_nearest_enemy_to_player(max_distance: float = 1000.0) -> CharacterBody2D:
    var player = get_player()
    if not player:
        return null
        
    return level_manager.get_nearest_enemy_to(player.global_position, max_distance) 