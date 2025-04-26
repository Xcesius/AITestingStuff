# PlayerMovement.gd
extends CharacterBody2D

@export var stats: Resource # [PATH_TO_CHARACTER_STATS_RESOURCE]
@onready var anim = $AnimatedSprite2D

enum State { IDLE, WALKING, ATTACKING }
var state = State.IDLE

signal state_changed(new_state)

func _physics_process(delta):
    var input_vector = Vector2.ZERO
    input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
    input_vector = input_vector.normalized()
    velocity = input_vector * stats.speed
    move_and_slide()
    _update_state(input_vector)

func _update_state(input_vector):
    var prev_state = state
    if Input.is_action_just_pressed("attack"):
        state = State.ATTACKING
        emit_signal("state_changed", state)
        # [PLAYER_ATTACK_LOGIC]
    elif input_vector.length() > 0:
        state = State.WALKING
    else:
        state = State.IDLE
    if prev_state != state:
        emit_signal("state_changed", state)

# Animation control (placeholder)
func _on_state_changed(new_state):
    match new_state:
        State.IDLE:
            anim.play([PLAYER_IDLE_ANIMATION_NAME])
        State.WALKING:
            anim.play([PLAYER_WALK_RIGHT_ANIMATION_NAME])
        State.ATTACKING:
            anim.play([PLAYER_ATTACK_ANIMATION_NAME]) 