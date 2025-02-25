class_name StateMachine
extends Node

signal state_changed(state_name: String)

@export var initial_state: NodePath
var current_state: State
var states: Dictionary = {}

func _ready() -> void:
    for child in get_children():
        if child is State:
            states[child.name.to_lower()] = child
    
    if initial_state:
        initial_state = get_node(initial_state)
        transition_to(initial_state.name.to_lower())

func _unhandled_input(event: InputEvent) -> void:
    if current_state:
        current_state.handle_input(event)

func _process(delta: float) -> void:
    if current_state:
        current_state.update(delta)

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_update(delta)

func transition_to(state_name: String) -> void:
    if not states.has(state_name.to_lower()):
        push_warning("State " + state_name + " not found in state machine")
        return
    
    if current_state:
        current_state.exit()
    
    current_state = states[state_name.to_lower()]
    current_state.enter()
    
    emit_signal("state_changed", state_name) 