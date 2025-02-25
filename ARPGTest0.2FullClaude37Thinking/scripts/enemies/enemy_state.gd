class_name EnemyState
extends Node

# References
var enemy: EnemyCharacter
var state_machine: EnemyStateMachine

# State duration tracking
var time_in_state: float = 0.0

# Virtual function called when entering this state
func enter() -> void:
    time_in_state = 0.0

# Virtual function called when exiting this state
func exit() -> void:
    pass

# Virtual function for processing logic in this state
func process(delta: float) -> void:
    time_in_state += delta

# Virtual function for physics processing in this state
func physics_process(delta: float) -> void:
    pass

# Helper function to change to another state
func change_state(new_state: String) -> void:
    state_machine.change_state(new_state) 