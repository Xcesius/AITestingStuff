class_name EnemyStateMachine
extends Node

signal state_changed(old_state, new_state)

# Reference to the enemy
var enemy: EnemyCharacter

# Dictionary to store all states
var states: Dictionary = {}

# Current active state
var current_state: EnemyState
var previous_state: EnemyState

func _ready() -> void:
    # Wait for enemy to be ready
    await owner.ready
    
    # Get enemy reference
    enemy = owner as EnemyCharacter
    assert(enemy != null, "State Machine must be a child of EnemyCharacter")
    
    # Register all child states
    for child in get_children():
        if child is EnemyState:
            states[child.name.to_lower()] = child
            child.state_machine = self
            child.enemy = enemy
    
    # Set initial state
    if states.has("idle"):
        change_state("idle")

func initialize(p_enemy: EnemyCharacter) -> void:
    enemy = p_enemy
    
    # Initialize all states
    for state_name in states:
        states[state_name].enemy = enemy

func _process(delta: float) -> void:
    if current_state:
        current_state.process(delta)

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_process(delta)

func change_state(new_state_name: String) -> void:
    # Skip if trying to change to the same state
    if current_state and current_state.name.to_lower() == new_state_name.to_lower():
        return
    
    # Debug output
    if OS.is_debug_build():
        print("Enemy state change: ", current_state.name if current_state else "null", " -> ", new_state_name)
    
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

func get_current_state_name() -> String:
    if current_state:
        return current_state.name
    return "" 