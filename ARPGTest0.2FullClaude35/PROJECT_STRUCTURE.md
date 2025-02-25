# ARPG Project Structure

## Core Directories
- `/scenes` - Main game scenes
  - `/player` - Player-related scenes and scripts
  - `/enemies` - Enemy-related scenes and scripts
  - `/ui` - UI scenes and components
  - `/maps` - Map scenes and generation scripts
  - `/items` - Item scenes and related scripts
- `/scripts` - Shared scripts and utilities
  - `/resources` - Custom resource scripts
  - `/autoload` - Singleton/global scripts
  - `/state_machines` - State machine implementations
  - `/tools` - Debug and development tools
- `/assets` - Game assets (placeholders)
  - `/sprites` - Character and item sprites
  - `/tilesets` - Map tilesets
  - `/ui` - UI assets
- `/resources` - Resource files (.tres)
  - `/items` - Item data
  - `/characters` - Character stats
  - `/enemies` - Enemy configurations
  - `/loot_tables` - Loot drop configurations

## Core Files
- `project.godot` - Godot project configuration
- `default_env.tres` - Default environment settings
- `todo.md` - Project tasks and progress
- `info.md` - Project documentation and notes 