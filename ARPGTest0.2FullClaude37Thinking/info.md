# ARPG Prototype - Detailed Implementation Guide

## Overview
This document provides detailed guidance for implementing each system in the ARPG prototype.

## Player System

### Scene Structure (PlayerCharacter.tscn)
```
- PlayerCharacter (CharacterBody2D)
  |- Sprite (AnimatedSprite2D)
  |- Collision (CollisionShape2D)
  |- HitBox (Area2D)
  |  |- CollisionShape2D
  |- Camera2D
  |- StateMachine
  |  |- IdleState
  |  |- MoveState
  |  |- AttackState
  |  |- HurtState
  |- AudioPlayers
```

### Required Scripts
1. **PlayerCharacter.gd**: Main player controller script
2. **PlayerMovement.gd**: Handles input and movement logic
3. **PlayerCombat.gd**: Manages attacks and damage
4. **PlayerStateMachine.gd**: Controls player states
5. **PlayerState.gd**: Base class for player states

### Custom Resources
1. **CharacterStats.gd**: Resource script for player stats
```gdscript
class_name CharacterStats
extends Resource

@export var max_health: int = [PLAYER_MAX_HEALTH]
@export var current_health: int = max_health
@export var attack_damage: int = [PLAYER_ATTACK_DAMAGE]
@export var defense: int = 1
@export var move_speed: float = [PLAYER_MOVE_SPEED]
@export var attack_speed: float = 1.0
@export var level: int = 1
@export var experience: int = 0
@export var next_level_exp: int = 100

func take_damage(amount: int) -> int:
    var actual_damage = max(amount - defense, 1)
    current_health = max(current_health - actual_damage, 0)
    return actual_damage
    
func heal(amount: int) -> void:
    current_health = min(current_health + amount, max_health)
    
func is_alive() -> bool:
    return current_health > 0
    
func add_experience(amount: int) -> bool:
    experience += amount
    if experience >= next_level_exp:
        level_up()
        return true
    return false
    
func level_up() -> void:
    level += 1
    experience -= next_level_exp
    next_level_exp = int(next_level_exp * 1.5)
    max_health += 5
    current_health = max_health
    attack_damage += 2
    defense += 1
```

## Enemy System

### Scene Structure (EnemyCharacter.tscn)
```
- EnemyCharacter (CharacterBody2D)
  |- Sprite (AnimatedSprite2D)
  |- Collision (CollisionShape2D)
  |- HitBox (Area2D)
  |  |- CollisionShape2D
  |- DetectionArea (Area2D)
  |  |- CollisionShape2D
  |- StateMachine
  |  |- IdleState
  |  |- ChaseState
  |  |- AttackState
  |  |- HurtState
  |- NavigationAgent2D
  |- AudioPlayers
```

### Enemy AI State Machine
```gdscript
class_name EnemyStateMachine
extends Node

signal state_changed(new_state_name)

var current_state: EnemyState
var states: Dictionary = {}
var enemy: CharacterBody2D

func _ready() -> void:
    enemy = owner as CharacterBody2D
    for child in get_children():
        if child is EnemyState:
            states[child.name.to_lower()] = child
            child.state_machine = self
    
    if states.has("idle"):
        change_state("idle")

func _process(delta: float) -> void:
    if current_state:
        current_state.process(delta)

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_process(delta)

func change_state(new_state_name: String) -> void:
    if current_state:
        current_state.exit()
    
    if states.has(new_state_name.to_lower()):
        current_state = states[new_state_name.to_lower()]
        current_state.enter()
        emit_signal("state_changed", new_state_name)
    else:
        push_error("No state found with name: " + new_state_name)
```

## Procedural Map Generation

### Map Generator Algorithm Overview
1. Create a grid of cells (potential rooms)
2. Randomly select some cells to be rooms
3. Determine room sizes within min/max constraints
4. Connect rooms with corridors
5. Add doors between rooms and corridors
6. Place decorations and enemies

### Map Generator Snippet
```gdscript
class_name MapGenerator
extends Node

signal map_generated(map_data)

@export var map_width: int = [MAP_WIDTH]
@export var map_height: int = [MAP_HEIGHT]
@export var room_min_size: int = [ROOM_MIN_SIZE]
@export var room_max_size: int = [ROOM_MAX_SIZE]
@export var max_rooms: int = [MAX_ROOMS]

var tilemap: TileMap
var rooms: Array = []

func _ready() -> void:
    tilemap = get_parent() as TileMap

func generate_map() -> void:
    # Clear existing map
    if tilemap:
        tilemap.clear()
    
    rooms.clear()
    
    # Generate rooms
    for i in range(max_rooms):
        var w = randi_range(room_min_size, room_max_size)
        var h = randi_range(room_min_size, room_max_size)
        var x = randi_range(1, map_width - w - 1)
        var y = randi_range(1, map_height - h - 1)
        
        var new_room = Rect2(x, y, w, h)
        var can_place = true
        
        # Check if room overlaps with existing rooms
        for existing_room in rooms:
            if new_room.intersects(existing_room, true):
                can_place = false
                break
        
        if can_place:
            _create_room(new_room)
            
            if rooms.size() > 0:
                # Connect to previous room
                var prev_room_center = _get_room_center(rooms.back())
                var new_room_center = _get_room_center(new_room)
                
                # 50% chance to start with horizontal corridor
                if randi() % 2 == 0:
                    _create_h_corridor(prev_room_center.x, new_room_center.x, prev_room_center.y)
                    _create_v_corridor(prev_room_center.y, new_room_center.y, new_room_center.x)
                else:
                    _create_v_corridor(prev_room_center.y, new_room_center.y, prev_room_center.x)
                    _create_h_corridor(prev_room_center.x, new_room_center.x, new_room_center.y)
            
            rooms.append(new_room)
    
    # Place player in first room
    var player_pos = _get_room_center(rooms.front())
    # Place exit in last room
    var exit_pos = _get_room_center(rooms.back())
    
    # Place enemies and items
    _place_enemies()
    _place_items()
    
    emit_signal("map_generated", {
        "rooms": rooms,
        "player_start": player_pos,
        "exit_pos": exit_pos
    })

func _create_room(room: Rect2) -> void:
    # Fill room with floor tiles
    for x in range(room.position.x, room.position.x + room.size.x):
        for y in range(room.position.y, room.position.y + room.size.y):
            tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(1, 1))  # Floor tile
    
    # Add walls around the room
    for x in range(room.position.x - 1, room.position.x + room.size.x + 1):
        tilemap.set_cell(0, Vector2i(x, room.position.y - 1), 0, Vector2i(0, 0))  # Wall tile
        tilemap.set_cell(0, Vector2i(x, room.position.y + room.size.y), 0, Vector2i(0, 0))  # Wall tile
    
    for y in range(room.position.y, room.position.y + room.size.y):
        tilemap.set_cell(0, Vector2i(room.position.x - 1, y), 0, Vector2i(0, 0))  # Wall tile
        tilemap.set_cell(0, Vector2i(room.position.x + room.size.x, y), 0, Vector2i(0, 0))  # Wall tile

func _get_room_center(room: Rect2) -> Vector2:
    return Vector2(
        room.position.x + room.size.x / 2,
        room.position.y + room.size.y / 2
    )

func _create_h_corridor(x1: int, x2: int, y: int) -> void:
    for x in range(min(x1, x2), max(x1, x2) + 1):
        tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(1, 1))  # Floor tile
        tilemap.set_cell(0, Vector2i(x, y - 1), 0, Vector2i(0, 0))  # Wall above
        tilemap.set_cell(0, Vector2i(x, y + 1), 0, Vector2i(0, 0))  # Wall below

func _create_v_corridor(y1: int, y2: int, x: int) -> void:
    for y in range(min(y1, y2), max(y1, y2) + 1):
        tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(1, 1))  # Floor tile
        tilemap.set_cell(0, Vector2i(x - 1, y), 0, Vector2i(0, 0))  # Wall left
        tilemap.set_cell(0, Vector2i(x + 1, y), 0, Vector2i(0, 0))  # Wall right

func _place_enemies() -> void:
    # Skip the first room (player spawn)
    for i in range(1, rooms.size()):
        var room = rooms[i]
        var num_enemies = randi_range(0, 2 + i / 3)  # More enemies in later rooms
        
        for j in range(num_enemies):
            var x = randi_range(room.position.x + 1, room.position.x + room.size.x - 2)
            var y = randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
            
            # Placeholder for enemy placement
            # Will be replaced with actual enemy instance creation
            # Enemy type can be varied based on room distance from start
            print("Enemy placed at: ", Vector2(x, y))

func _place_items() -> void:
    for room in rooms:
        # 60% chance for item in each room
        if randf() < 0.6:
            var x = randi_range(room.position.x + 1, room.position.x + room.size.x - 2)
            var y = randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
            
            # Placeholder for item placement
            # Will be replaced with actual item instance creation
            print("Item placed at: ", Vector2(x, y))
```

## Item & Loot System

### ItemData Resource
```gdscript
class_name ItemData
extends Resource

enum ItemType { WEAPON, ARMOR, CONSUMABLE, QUEST }

@export var id: String = "item_001"
@export var name: String = "Item Name"
@export var description: String = "Item description"
@export var icon: Texture2D
@export var item_type: ItemType
@export var stack_size: int = 1
@export var value: int = 0

# Type-specific properties
@export_group("Weapon Properties")
@export var damage: int = 0
@export var attack_speed: float = 1.0

@export_group("Armor Properties")
@export var defense: int = 0

@export_group("Consumable Properties")
@export var health_restore: int = 0
@export var effect_duration: float = 0.0

func use(character) -> bool:
    match item_type:
        ItemType.CONSUMABLE:
            if health_restore > 0:
                character.stats.heal(health_restore)
            return true
        ItemType.WEAPON, ItemType.ARMOR:
            # Equipping logic will be handled by inventory system
            return false
        ItemType.QUEST:
            # Quest items typically can't be used
            return false
    return false
```

### LootTable Resource
```gdscript
class_name LootTable
extends Resource

class LootEntry:
    var item_id: String
    var weight: int
    var min_count: int
    var max_count: int
    
    func _init(p_item_id: String, p_weight: int, p_min_count: int = 1, p_max_count: int = 1):
        item_id = p_item_id
        weight = p_weight
        min_count = p_min_count
        max_count = p_max_count

@export var table_id: String = "loot_table_001"
@export var guaranteed_drops: Array[String] = []
@export var drop_chance: float = 1.0  # 0-1 chance of any drop happening

var entries: Array[LootEntry] = []
var total_weight: int = 0

func _init():
    # Example initialization
    add_entry("gold_coin", 80, 1, 10)  # Common drop, 1-10 coins
    add_entry("health_potion", 40, 1, 1)  # Uncommon drop
    add_entry("iron_sword", 10, 1, 1)  # Rare drop

func add_entry(item_id: String, weight: int, min_count: int = 1, max_count: int = 1) -> void:
    var entry = LootEntry.new(item_id, weight, min_count, max_count)
    entries.append(entry)
    total_weight += weight

func roll_loot() -> Array:
    var result = []
    
    # Add guaranteed drops
    for item_id in guaranteed_drops:
        result.append({"item_id": item_id, "count": 1})
    
    # Check if we get any random drops
    if randf() > drop_chance:
        return result
    
    # Roll for random drops
    if total_weight > 0 and entries.size() > 0:
        var roll = randi_range(1, total_weight)
        var current_weight = 0
        
        for entry in entries:
            current_weight += entry.weight
            if roll <= current_weight:
                var count = randi_range(entry.min_count, entry.max_count)
                result.append({"item_id": entry.item_id, "count": count})
                break
    
    return result
```

## UI System

### HUD Scene Structure (HUD.tscn)
```
- HUD (CanvasLayer)
  |- MarginContainer
  |  |- VBoxContainer
  |     |- HBoxContainer (TopBar)
  |     |  |- HealthDisplay
  |     |  |  |- TextureRect (Heart Icon)
  |     |  |  |- Label (Health Value)
  |     |  |- ExperienceBar (ProgressBar)
  |     |- MarginContainer (Spacer)
  |     |- HBoxContainer (ActionBar)
  |        |- TextureButton (Inventory)
  |        |- TextureButton (Character)
  |        |- TextureButton (Settings)
```

### Inventory UI Scene Structure (InventoryUI.tscn)
```
- InventoryUI (Control)
  |- Panel (Background)
  |  |- VBoxContainer
  |     |- Label (Title)
  |     |- GridContainer (ItemGrid)
  |     |  |- ItemSlot (x[INVENTORY_SLOTS_COUNT])
  |     |- HBoxContainer (Buttons)
  |        |- Button (Close)
  |        |- Button (Sort)
```

## Debug Console Tool

### Console Scene Structure (DebugConsole.tscn)
```
- DebugConsole (CanvasLayer)
  |- Panel
  |  |- VBoxContainer
  |     |- RichTextLabel (OutputText)
  |     |- HBoxContainer
  |        |- LineEdit (CommandInput)
  |        |- Button (Execute)
```

### Debug Console Script
```gdscript
class_name DebugConsole
extends CanvasLayer

@onready var output_text = $Panel/VBoxContainer/RichTextLabel
@onready var command_input = $Panel/VBoxContainer/HBoxContainer/LineEdit
@onready var panel = $Panel

var commands = {
    "help": {
        "description": "Show available commands",
        "function": func(): _cmd_help()
    },
    "spawn_enemy": {
        "description": "Spawn an enemy at player position",
        "function": func(enemy_type = "basic"): _cmd_spawn_enemy(enemy_type)
    },
    "give_item": {
        "description": "Add item to player inventory",
        "function": func(item_id, count = 1): _cmd_give_item(item_id, int(count))
    },
    "teleport": {
        "description": "Teleport player to coordinates",
        "function": func(x, y): _cmd_teleport(float(x), float(y))
    },
    "heal": {
        "description": "Heal player to full health",
        "function": func(): _cmd_heal()
    },
    "toggle_god": {
        "description": "Toggle god mode (invincibility)",
        "function": func(): _cmd_toggle_god()
    }
}

var visible_default = false
var god_mode = false

func _ready() -> void:
    panel.visible = visible_default
    
    # Connect signals
    command_input.text_submitted.connect(_on_command_submitted)
    
    # Add to tool group for retrieval
    add_to_group("debug_tools")
    
    output_text.text = "Debug Console Initialized\n"

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_GRAVE:  # Tilde/backtick key
            panel.visible = !panel.visible
            if panel.visible:
                command_input.grab_focus()

func _on_command_submitted(text: String) -> void:
    if text.strip_edges().is_empty():
        return
    
    output_text.text += "> " + text + "\n"
    
    var args = text.split(" ")
    var command = args[0].to_lower()
    args.remove_at(0)
    
    if commands.has(command):
        var cmd_func = commands[command]["function"]
        
        match args.size():
            0: cmd_func.call()
            1: cmd_func.call(args[0])
            2: cmd_func.call(args[0], args[1])
            3: cmd_func.call(args[0], args[1], args[2])
            _: output_text.text += "Error: Too many arguments\n"
    else:
        output_text.text += "Unknown command: " + command + "\n"
    
    command_input.text = ""

func _cmd_help() -> void:
    output_text.text += "Available commands:\n"
    for cmd in commands.keys():
        output_text.text += "  " + cmd + " - " + commands[cmd]["description"] + "\n"

func _cmd_spawn_enemy(enemy_type: String) -> void:
    # Implementation will reference the game world and player position
    output_text.text += "Spawned enemy of type: " + enemy_type + "\n"

func _cmd_give_item(item_id: String, count: int) -> void:
    # Implementation will reference the player's inventory
    output_text.text += "Added " + str(count) + "x " + item_id + " to inventory\n"

func _cmd_teleport(x: float, y: float) -> void:
    # Implementation will reference the player's position
    output_text.text += "Teleported player to: " + str(Vector2(x, y)) + "\n"

func _cmd_heal() -> void:
    # Implementation will reference the player's health
    output_text.text += "Player healed to full health\n"

func _cmd_toggle_god() -> void:
    god_mode = !god_mode
    output_text.text += "God mode: " + ("ON" if god_mode else "OFF") + "\n"

func log(message: String) -> void:
    output_text.text += message + "\n"
```

## Implementation Best Practices

1. **Scene Organization**
   - Use clear, descriptive node names
   - Group related nodes with Node2D containers
   - Keep scene hierarchies shallow when possible

2. **Script Organization**
   - One script per scene/class
   - Separate UI logic from game logic
   - Use signals for cross-scene communication

3. **Resource Management**
   - Load resources at initialization
   - Use resource preloading for frequently needed assets
   - Implement resource caching for dynamic loading

4. **Performance Considerations**
   - Use object pooling for frequently instantiated objects
   - Implement visibility notifiers for off-screen objects
   - Optimize collision shapes and physics interactions

5. **Debugging Tips**
   - Implement debugging visualization tools
   - Use print_debug() in development
   - Create editor tools to test game mechanics 