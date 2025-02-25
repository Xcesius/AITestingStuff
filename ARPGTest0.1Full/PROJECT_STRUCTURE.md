# ARPG Project Structure

```
/
├── scenes/
│   ├── player/
│   │   ├── PlayerCharacter.tscn
│   │   └── player_scripts/
│   ├── enemies/
│   │   ├── EnemyCharacter.tscn
│   │   └── enemy_scripts/
│   ├── ui/
│   │   ├── HUD.tscn
│   │   └── InventoryUI.tscn
│   └── world/
│       └── Map.tscn
├── scripts/
│   ├── resources/
│   │   ├── character_stats.gd
│   │   ├── enemy_stats.gd
│   │   ├── item_data.gd
│   │   └── loot_table.gd
│   ├── autoload/
│   │   └── game_manager.gd
│   └── utils/
│       └── map_generator.gd
├── assets/
│   ├── sprites/
│   │   ├── player/
│   │   ├── enemies/
│   │   └── items/
│   ├── tilesets/
│   └── ui/
└── resources/
    ├── items/
    ├── enemies/
    └── player/
```

## Key Components

### Scenes
- **player**: Contains player-related scenes and scripts
- **enemies**: Enemy scenes and AI scripts
- **ui**: User interface scenes
- **world**: Map and environment-related scenes

### Scripts
- **resources**: Custom resource definitions
- **autoload**: Global singleton scripts
- **utils**: Utility scripts and helpers

### Assets
- **sprites**: Character and object sprites
- **tilesets**: Map tilesets
- **ui**: UI elements and icons

### Resources
- **items**: Item definitions
- **enemies**: Enemy configurations
- **player**: Player configurations 