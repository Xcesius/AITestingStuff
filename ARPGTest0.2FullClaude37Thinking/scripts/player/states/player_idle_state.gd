class_name PlayerIdleState
extends PlayerState

func _ready() -> void:
    state_name = "idle"

func enter() -> void:
    # Ensure the player is playing the idle animation
    var facing = player.facing_direction
    
    if abs(facing.x) > abs(facing.y):
        if facing.x > 0:
            player.sprite.play("idle_right")
        else:
            player.sprite.play("idle_left")
    else:
        if facing.y > 0:
            player.sprite.play("idle_down")
        else:
            player.sprite.play("idle_up")

func exit() -> void:
    # Nothing special needed when exiting idle state
    pass

func physics_process(delta: float) -> void:
    # Check for movement input to transition to move state
    var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    
    if input_direction != Vector2.ZERO:
        change_state("move")
        return
    
    # Apply friction to slow down any remaining movement
    player.velocity = player.velocity.move_toward(Vector2.ZERO, player.friction * delta)
    player.move_and_slide()

func handle_input(event: InputEvent) -> void:
    # Check for attack input
    if event.is_action_pressed("attack"):
        change_state("attack")
        get_viewport().set_input_as_handled()
    # Check for inventory input
    elif event.is_action_pressed("inventory"):
        # This would typically trigger the inventory UI rather than a state change
        # But we could also have an "inventory" state if needed
        pass 