class_name PlayerMovement
extends Node

# Player reference
var player: PlayerCharacter

# Input variables
var input_direction: Vector2 = Vector2.ZERO
var is_running: bool = false

# Called when the node enters the scene tree for the first time
func _ready() -> void:
    player = get_parent() as PlayerCharacter
    assert(player != null, "PlayerMovement must be a child of PlayerCharacter")

# Called during the physics processing phase
func _physics_process(delta: float) -> void:
    # Skip movement processing if player is attacking or in knockback
    if player.is_attacking or player.knockback_timer > 0:
        return
    
    # Get input direction
    _get_input()
    
    # Apply movement
    _apply_movement(delta)

# Handle player input
func _get_input() -> void:
    # Get movement input
    input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    input_direction = input_direction.normalized()
    
    # Check for running input (e.g., holding Shift)
    is_running = Input.is_action_pressed("run")
    
    # Handle attack input
    if Input.is_action_just_pressed("attack"):
        player.attack()

# Apply movement to the player character
func _apply_movement(delta: float) -> void:
    # Calculate target velocity
    var target_velocity = Vector2.ZERO
    
    if input_direction != Vector2.ZERO:
        # Calculate speed based on running state
        var speed_multiplier = 1.5 if is_running else 1.0
        var target_speed = player.max_speed * player.stats.move_speed * speed_multiplier
        
        # Calculate target velocity based on input direction and speed
        target_velocity = input_direction * target_speed
        
        # Apply acceleration
        player.velocity = player.velocity.move_toward(target_velocity, player.acceleration * delta)
    else:
        # Apply friction to slow down
        player.velocity = player.velocity.move_toward(Vector2.ZERO, player.friction * delta)

# Interface for the state machine to call
func move(delta: float) -> void:
    _get_input()
    _apply_movement(delta)

# Reset movement and stop the player
func stop() -> void:
    input_direction = Vector2.ZERO
    player.velocity = Vector2.ZERO 