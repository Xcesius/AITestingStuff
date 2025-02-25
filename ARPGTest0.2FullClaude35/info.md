# ARPG Project Information

## Project Overview
2D Action RPG prototype built with Godot 4.x, featuring procedural dungeon generation, advanced combat mechanics, and modular systems design.

## Technical Specifications
- Engine: Godot 4.x
- Renderer: Forward+
- Art Style: 2D Pixel Art
- Target Platform: Windows (initially)

## Core Systems Architecture

### State Machine Pattern
```gdscript
# Basic state machine structure
class_name StateMachine
extends Node

var current_state: State
var states: Dictionary = {}

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.update(delta)
```

### Signal Architecture
- Global event bus for decoupled communication
- Direct signals for immediate parent-child interaction
- Custom signal patterns for UI updates

### Resource System
- Data-driven design using Custom Resources
- Centralized configuration management
- Runtime resource loading for flexibility

## Coding Standards
- Use PascalCase for classes/nodes
- Use snake_case for functions/variables
- Organize code with regions and clear comments
- Implement error handling and logging

## Performance Considerations
- Object pooling for frequent instantiation
- Efficient collision layer management
- Optimized tilemap handling
- Smart use of physics layers

## Debug Tools
- State visualization
- Performance monitoring
- AI behavior debugging
- Map generation preview

## Asset Guidelines
- Consistent pixel art scale
- Defined color palette
- Animation frame guidelines
- Tile size standards 