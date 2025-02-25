class_name PlayerMoveState
extends PlayerState

var is_running: bool = false
var input_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
    state_name = "move"

func enter() -> void:
    # Nothing specific needed on enter
    pass

func exit() -> void:
    # Reset movement variables when exiting move state
    input_direction = Vector2.ZERO
    is_running = false

func process(delta: float) -> void:
    # Update animation based on movement direction
    _update_animation()

func physics_process(delta: float) -> void:
    # Get input direction
    input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    input_direction = input_direction.normalized()
    
    # Check for running input
    is_running = Input.is_action_pressed("run")
    
    # If no movement input, transition back to idle
    if input_direction == Vector2.ZERO:
        change_state("idle")
        return
    
    # Update facing direction
    player.facing_direction = input_direction
    
    # Calculate target velocity
    var speed_multiplier = 1.5 if is_running else 1.0
    var target_speed = player.max_speed * player.stats.move_speed * speed_multiplier
    var target_velocity = input_direction * target_speed
    
    # Apply acceleration
    player.velocity = player.velocity.move_toward(target_velocity, player.acceleration * delta)
    
    # Move the player
    player.move_and_slide()

func handle_input(event: InputEvent) -> void:
    # Check for attack input
    if event.is_action_pressed("attack"):
        change_state("attack")
        get_viewport().set_input_as_handled()
    # Check for dodge/roll input if implemented
    elif event.is_action_pressed("dodge") and player.stats.is_alive():
        change_state("dodge")
        get_viewport().set_input_as_handled()

func _update_animation() -> void:
    # Set movement animation based on direction
    if abs(input_direction.x) > abs(input_direction.y):
        if input_direction.x > 0:
            player.sprite.play("walk_right")
        else:
            player.sprite.play("walk_left")
    else:
        if input_direction.y > 0:
            player.sprite.play("walk_down")
        else:
            player.sprite.play("walk_up")
            
    # If running, could use run animations instead
    if is_running:
        # Assuming run animations follow naming pattern "run_direction"
        var current_anim = player.sprite.animation
        if current_anim.begins_with("walk_"):
            var direction = current_anim.substr(5)
            var run_anim = "run_" + direction
            
            # Check if run animation exists
            if player.sprite.sprite_frames.has_animation(run_anim):
                player.sprite.play(run_anim) 