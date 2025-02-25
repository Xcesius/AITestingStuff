class_name PlayerStateMachine
extends Node

signal state_changed(old_state, new_state)

# Reference to the player
var player: PlayerCharacter

# Dictionary to store all states
var states: Dictionary = {}

# Current active state
var current_state: PlayerState
var previous_state: PlayerState

func _ready() -> void:
    # Wait for player to be ready
    await owner.ready
    
    # Get player reference
    player = owner as PlayerCharacter
    assert(player != null, "State Machine must be a child of PlayerCharacter")
    
    # Register all child states
    for child in get_children():
        if child is PlayerState:
            states[child.name.to_lower()] = child
            child.state_machine = self
            child.player = player
    
    # Set initial state
    if states.has("idle"):
        change_state("idle")

func initialize(p_player: PlayerCharacter) -> void:
    player = p_player
    
    # Initialize all states
    for state_name in states:
        states[state_name].player = player

func _process(delta: float) -> void:
    if current_state:
        current_state.process(delta)

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_process(delta)

func _unhandled_input(event: InputEvent) -> void:
    if current_state:
        current_state.handle_input(event)

func change_state(new_state_name: String) -> void:
    # Skip if trying to change to the same state
    if current_state and current_state.name.to_lower() == new_state_name.to_lower():
        return
        
    # Exit current state
    if current_state:
        current_state.exit()
        previous_state = current_state
    
    # Enter new state if it exists
    if states.has(new_state_name.to_lower()):
        current_state = states[new_state_name.to_lower()]
        current_state.enter()
        emit_signal("state_changed", previous_state.name if previous_state else "", current_state.name)
    else:
        push_error("No state found with name: " + new_state_name)
        current_state = null 