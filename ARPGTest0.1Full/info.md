# ARPG Project Information

## Project Specifications
- Engine: Godot 4.x (Forward+ renderer)
- Art Style: 2D Pixel Art (16x16 or 32x32)
- Genre: Action RPG
- View: Top-down 2D

## Design Guidelines
- Modular architecture
- Data-driven design using Resources
- Signal-based communication
- Scalable systems

## Asset Guidelines
- Sprites: 16x16 or 32x32 pixel art
- Animations: 4-8 frames per action
- Tilesets: 16x16 base tiles

## Code Style
- Use PascalCase for node names and classes
- Use snake_case for functions and variables
- Comment all public functions and complex logic
- Use signals for decoupled communication
- Organize code into logical groups using regions

## Resource Naming
- Scene files: PascalCase.tscn
- Script files: snake_case.gd
- Resource files: snake_case.tres

## Version Control
- Comment all major changes
- Keep commits focused and atomic
- Use descriptive commit messages

## Performance Guidelines
- Use object pooling for frequent instantiation
- Minimize physics bodies when possible
- Use Area2D for simple collision detection
- Implement proper cleanup in _exit_tree() 