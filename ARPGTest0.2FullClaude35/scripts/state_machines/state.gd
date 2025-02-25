class_name State
extends Node

# Virtual function to be overridden by concrete states
func enter() -> void:
    pass

# Virtual function to be overridden by concrete states
func exit() -> void:
    pass

# Virtual function to be overridden by concrete states
func update(_delta: float) -> void:
    pass

# Virtual function to be overridden by concrete states
func physics_update(_delta: float) -> void:
    pass

# Virtual function to be overridden by concrete states
func handle_input(_event: InputEvent) -> void:
    pass 