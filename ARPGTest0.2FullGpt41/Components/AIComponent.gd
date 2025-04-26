# AIComponent.gd
extends Node

@export var ai_type: String = "basic"

enum State { IDLE, CHASING, ATTACKING, RETREATING, DEAD }
var state = State.IDLE

signal state_changed(new_state)

func set_state(new_state):
    if state != new_state:
        state = new_state
        emit_signal("state_changed", state)

func process_ai(player):
    match state:
        State.IDLE:
            # [AI_IDLE_LOGIC]
            pass
        State.CHASING:
            # [AI_CHASING_LOGIC]
            pass
        State.ATTACKING:
            # [AI_ATTACKING_LOGIC]
            pass
        State.RETREATING:
            # [AI_RETREATING_LOGIC]
            pass
        State.DEAD:
            # [AI_DEAD_LOGIC]
            pass 