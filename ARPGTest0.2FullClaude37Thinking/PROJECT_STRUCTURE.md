# ARPG Prototype - Project Structure

## Overview
This document outlines the structure of our 2D ARPG prototype built with Godot 4.x.

## Directory Structure

```
/
├── assets/                     # All game assets
│   ├── sprites/                # Character and object sprites
│   ├── tilesets/               # Map tilesets
│   ├── ui/                     # UI elements and icons
│   └── effects/                # Visual effects
├── scenes/                     # Scene files (.tscn)
│   ├── player/                 # Player-related scenes
│   ├── enemies/                # Enemy scenes
│   ├── items/                  # Item pickup and related scenes
│   ├── ui/                     # UI scenes (HUD, inventory, menus)
│   ├── levels/                 # Level scenes
│   └── autoload/               # Singleton scenes
├── scripts/                    # GDScript files (.gd)
│   ├── player/                 # Player-related scripts
│       ├── item_interaction_controller.gd # Item interaction system
│       └── player_item_interactor.gd # Player component for item interactions
│   ├── enemies/                # Enemy scripts
│   ├── items/                  # Item scripts
│       ├── item_pickup.gd      # Base item pickup class
│       ├── weapon_pickup.gd    # Weapon pickup specialization
│       ├── healing_item_pickup.gd # Healing item pickup
│       ├── treasure_chest.gd   # Container for multiple items
│       └── interactable.gd     # Base class for interactive objects
│   ├── ui/                     # UI scripts
│       └── interaction_prompt.gd # UI for interaction prompts
│   ├── levels/                 # Level generation scripts
│       ├── map_generator.gd    # Procedural dungeon generation
│       ├── level_manager.gd    # Level entity management
│       ├── dungeon_level.gd    # Base level scene controller
│       └── dungeon_exit.gd     # Level exit portal
│   ├── autoload/               # Global script singletons
│   └── resources/              # Resource script files
├── resources/                  # Resource files (.tres)
│   ├── items/                  # Item data resources
│   ├── characters/             # Character stat resources
│   └── loot_tables/            # Loot table configurations
├── addons/                     # Godot plugins and tools
│   └── arpg_tools/             # Custom tools for this project
│       ├── debug_console/      # Debug console tools
│       ├── map_generator/      # Map generation preview tools
│       └── loot_simulator/     # Loot simulation tools
├── project.godot               # Main Godot project file
└── README.md                   # Project documentation
```

## Core Systems

1. **Player System**
   - Character movement and animations
   - Combat and health management
   - Inventory and equipment

2. **Enemy System**
   - AI and pathfinding
   - Combat behavior
   - Loot dropping

3. **Item System**
   - Pickup mechanics
   - Item data and properties
   - Inventory integration

4. **Map System**
   - Procedural generation
   - Level transitions
   - Environmental interactions

5. **UI System**
   - HUD elements
   - Inventory display
   - Menus and dialogs

6. **Tool System**
   - Debug console
   - Map generation preview
   - Loot balance simulation
   - AI state visualization

## Directories and Files

```
/
|--- scripts/                          # Contains all GDScript files
|    |--- components/                  # Reusable components for game objects
|    |    |--- health_component.gd     # Health management for entities
|    |    |--- hitbox_component.gd     # Hitbox for damage detection
|    |    |--- hurtbox_component.gd    # Hurtbox for receiving damage
|    |    |--- pickup_component.gd     # Handles item pickups
|    |    |--- equipment_controller.gd # Manages character equipment
|    |
|    |--- enemy/                       # Enemy-related scripts
|    |    |--- enemy.gd                # Base enemy script
|    |    |--- enemy_spawner.gd        # Spawns enemies in the world
|    |
|    |--- items/                       # Item-related scripts
|    |    |--- item_pickup.gd          # Base item pickup script
|    |    |--- weapon_pickup.gd        # Weapon pickup script
|    |    |--- armor_pickup.gd         # Armor pickup script
|    |    |--- potion_pickup.gd        # Potion pickup script
|    |
|    |--- player/                      # Player-related scripts
|    |    |--- player_character.gd     # Main player character script
|    |    |--- player_movement.gd      # Player movement system
|    |    |--- player_state_machine.gd # State machine for player
|    |    |--- player_state.gd         # Base state for state machine
|    |    |--- player_item_interactor.gd # Interacts with items in the world
|    |    |--- states/                 # Player state implementations
|    |         |--- player_idle_state.gd   # Idle state
|    |         |--- player_move_state.gd   # Movement state
|    |         |--- player_attack_state.gd # Attack state
|    |         |--- player_hurt_state.gd   # Hurt state
|    |         |--- player_death_state.gd  # Death state
|    |
|    |--- resources/                   # Resource scripts
|    |    |--- character_stats.gd      # Character statistics
|    |    |--- inventory.gd            # Inventory system
|    |    |--- item_data.gd            # Base item data
|    |    |--- weapon_data.gd          # Weapon data extending item data
|    |    |--- armor_data.gd           # Armor data extending item data
|    |    |--- potion_data.gd          # Potion data extending item data
|    |    |--- food_data.gd            # Food data extending item data
|    |    |--- equipment_data.gd       # Equipment data base class
|    |    |--- accessory_data.gd       # Accessory data class
|    |    |--- equipment_system.gd     # System managing equipped items
|    |
|    |--- ui/                          # UI-related scripts
|    |    |--- health_bar.gd           # Player health display
|    |    |--- inventory_ui.gd         # Inventory interface
|    |    |--- equipment_ui.gd         # Equipment interface
|    |
|    |--- utils/                       # Utility scripts
|    |    |--- constants.gd            # Game constants
|    |    |--- helpers.gd              # Helper functions
|    |
|    |--- world/                       # World-related scripts
|         |--- world.gd                # Main world script
|         |--- tile_map.gd             # Tile map manager
|         |--- procedural_generator.gd # Procedural level generation
|
|--- scenes/                           # Contains all game scenes
|    |--- enemies/                     # Enemy scenes
|    |--- items/                       # Item scenes
|    |--- player/                      # Player scenes
|    |--- ui/                          # UI scenes
|    |--- world/                       # World scenes
|
|--- assets/                           # Game assets
     |--- sprites/                     # Sprite assets
     |--- audio/                       # Audio assets
     |--- fonts/                       # Font assets
```

## Key Components

### Player

The player character uses a state machine architecture for handling different states like idle, movement, attacking, and hurt states. It manages health, inventory, and equipment.

### Equipment System

The equipment system handles equipped items with specialized slots for weapons, armor, accessories, etc. It applies stat bonuses from equipment to the character's base stats.

* `EquipmentSystem`: Core resource that manages equipped items in different slots
* `EquipmentController`: Component that interfaces between the player and the equipment system
* `EquipmentData`: Base class for all equippable items
* `WeaponData`, `ArmorData`, `AccessoryData`: Specialized equipment types with unique properties

### Inventory

The inventory system keeps track of items the player has collected. It handles item stacking, sorting, and provides methods for adding, removing, and using items.

### Items

Items are categorized into different types:
- Equipment (Weapons, Armor, Accessories)
- Consumables (Potions, Food)
- Resources (Crafting materials, etc.)

### Character Stats

Character stats manage attributes like health, attack damage, defense, movement speed, and experience. The system handles stat modifications from equipment, temporary buffs, and level-ups.

### Enemy System

Enemies use their own implementations of health, stats, and behavior with simple AI targeting the player. The spawner generates enemies based on game difficulty and player level.

### World Generation

The world is generated procedurally, creating unique levels with different room layouts and structures. The system places enemies, items, and obstacles based on difficulty parameters.

## UI Scenes

- `scenes/ui/main_menu.tscn` - The main menu when starting the game
- `scenes/ui/hud.tscn` - The in-game HUD showing player information
- `scenes/ui/inventory_ui.tscn` - The player's inventory interface
- `scenes/ui/equipment_ui.tscn` - The player's equipment interface
- `scenes/ui/pause_menu.tscn` - The in-game pause menu
- `scenes/ui/debug_console.tscn` - Debug console for testing and development

## Debug Tools

- `scenes/tools/debug_tools.tscn` - Main debug tools interface with tabs for different tools
- `scenes/tools/map_preview_tool.tscn` - Tool for previewing and testing map generation parameters
- `scripts/tools/loot_simulator_tool.gd` - Tool for simulating and analyzing loot drops from different enemies and loot tables
- `scripts/tools/ai_visualizer_tool.gd` - Tool for visualizing and debugging enemy AI states and behavior
- `scripts/tools/performance_monitor_tool.gd` - Tool for monitoring and analyzing game performance metrics in real-time 

## Project Structure

```
project.godot
|
├── scenes/
│   ├── player/
│   │   └── player.tscn
│   ├── enemies/
│   │   └── enemy_base.tscn
│   ├── items/
│   │   └── item_pickup.tscn
│   ├── maps/
│   │   └── test_map.tscn
│   ├── ui/
│   │   ├── hud.tscn
│   │   ├── inventory_ui.tscn
│   │   ├── debug_console.tscn
│   │   ├── dialogue_option_button.tscn
│   │   └── save_slot.tscn
│   ├── npcs/
│   │   └── npc_base.tscn
│   └── tools/
│       ├── debug_tools.tscn
│       └── map_preview_tool.tscn
│
├── scripts/
│   ├── player/
│   │   ├── player_character.gd
│   │   ├── player_movement.gd
│   │   └── player_combat.gd
│   ├── enemies/
│   │   ├── enemy_base.gd
│   │   └── enemy_ai.gd
│   ├── items/
│   │   ├── item_data.gd
│   │   └── item_pickup.gd
│   ├── maps/
│   │   └── map_generator.gd
│   ├── ui/
│   │   ├── hud.gd
│   │   ├── inventory_ui.gd
│   │   ├── debug_console.gd
│   │   ├── dialogue_manager.gd
│   │   └── save_slot.gd
│   │   └── save_load_menu.gd
│   ├── camera/
│   │   └── game_camera.gd
│   ├── fx/
│   │   └── particle_manager.gd
│   ├── npcs/
│   │   └── npc_base.gd
│   ├── tools/
│   │   ├── debug_tools.gd
│   │   ├── map_preview_tool.gd
│   │   ├── loot_simulator_tool.gd
│   │   ├── ai_visualizer_tool.gd
│   │   └── performance_monitor_tool.gd
│   ├── autoload/
│   │   ├── event_bus.gd
│   │   ├── audio_manager.gd
│   │   ├── save_system.gd
│   │   └── quest_manager.gd
│   └── resources/
│       ├── character_stats.gd
│       └── loot_table.gd
│
└── assets/
    ├── sprites/
    │   ├── characters/
    │   ├── items/
    │   ├── tiles/
    │   └── ui/
    ├── audio/
    │   ├── music/
    │   ├── sfx/
    │   └── voice/
    └── shaders/
```

## New Features Added

### Save/Load System
- `scripts/autoload/save_system.gd`: Manages game saving and loading with encryption
- `scripts/ui/save_load_menu.gd`: UI for managing save files
- `scripts/ui/save_slot.gd`: Individual save slot UI component

### Audio System
- `scripts/autoload/audio_manager.gd`: Advanced audio system with cross-fading and audio pooling

### Camera System
- `scripts/camera/game_camera.gd`: Camera with smooth following, screen shake and zoom effects

### Particle Effects System
- `scripts/fx/particle_manager.gd`: Centralized particle effect manager with pooling

### Quest System
- `scripts/autoload/quest_manager.gd`: Manages quest tracking and progression
- Quest integration with NPC system

### NPC Interaction
- `scripts/npcs/npc_base.gd`: Base NPC with interaction, movement and quest functionality
- `scripts/ui/dialogue_manager.gd`: Manages NPC dialogue with branching conversations

## Implementation Details

### Save System
The save system uses encrypted JSON files to store game data. It handles:
- Player stats, inventory, equipment and position
- World state including quests and game time
- Game settings

### Audio System
The audio manager provides:
- Categorized audio (Music, SFX, UI, Ambient, Voice)
- Music cross-fading
- Sound pooling for performance
- Volume control per category

### Camera System
The game camera includes:
- Smooth player following with look-ahead
- Screen shake with trauma system
- Zoom effects
- Position focusing

### Particle System
The particle manager features:
- Pooled particles for performance
- Easy to use API for common effects
- Automatic cleanup of inactive particles

### Quest System
The quest system provides:
- Multiple objective types (kill, collect, talk, etc)
- Quest prerequisites and follow-ups
- Quest rewards
- Integration with NPCs and dialogue

### NPC System
The NPC system includes:
- Interaction with player
- Random movement
- Dialogue support
- Quest giving
- Vendor functionality 