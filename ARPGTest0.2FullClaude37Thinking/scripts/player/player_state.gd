class_name PlayerState
extends Node

# References
var player: PlayerCharacter
var state_machine: PlayerStateMachine

# State identifier
var state_name: String

# Virtual function called when entering this state
func enter() -> void:
    pass

# Virtual function called when exiting this state
func exit() -> void:
    pass

# Virtual function for processing logic in this state
func process(delta: float) -> void:
    pass

# Virtual function for physics processing in this state
func physics_process(delta: float) -> void:
    pass

# Virtual function for handling input in this state
func handle_input(event: InputEvent) -> void:
    pass

# Helper function to change to another state
func change_state(new_state: String) -> void:
    state_machine.change_state(new_state) 