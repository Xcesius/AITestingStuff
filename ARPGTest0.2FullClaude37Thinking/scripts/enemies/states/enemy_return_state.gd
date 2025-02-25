class_name EnemyReturnState
extends EnemyState

# Return behavior settings
@export var path_update_interval: float = 0.3
@export var home_threshold: float = 10.0
@export var return_speed_modifier: float = 1.1

# State variables
var path_update_timer: float = 0.0
var returning_home: bool = true

func enter() -> void:
    super.enter()
    
    # Set target to home position
    enemy.nav_agent.target_position = enemy.home_position
    
    # Update path immediately
    _update_path()
    
    # Setting flags
    returning_home = true
    
    # Play walk animation
    _update_animation()

func exit() -> void:
    # Nothing specific needed when exiting return state
    pass

func process(delta: float) -> void:
    super.process(delta)
    
    # Check if target appears during return
    if enemy.target and enemy.can_see_target():
        change_state("chase")
        return
    
    # Update path periodically
    path_update_timer += delta
    if path_update_timer >= path_update_interval:
        path_update_timer = 0.0
        _update_path()
    
    # Check if we're close enough to home
    var distance_to_home = enemy.global_position.distance_to(enemy.home_position)
    if distance_to_home <= home_threshold:
        change_state("idle")
        returning_home = false
        return
    
    # Update animation based on movement
    _update_animation()

func physics_process(delta: float) -> void:
    # Skip if knockback is active
    if enemy.knockback_timer > 0:
        return
    
    if returning_home:
        # Navigate to home position
        _navigate_to_home(delta)
    else:
        # If not returning home, apply friction to stop
        enemy.velocity = enemy.velocity.move_toward(Vector2.ZERO, enemy.friction * delta)
    
    # Move the enemy
    enemy.move_and_slide()
    
    # Update facing direction based on movement
    if enemy.velocity.length() > 0.1:
        enemy.facing_direction = enemy.velocity.normalized()

func _navigate_to_home(delta: float) -> void:
    if enemy.nav_agent.is_navigation_finished():
        # We've reached the target point
        return
    
    # Get next path position
    var next_position = enemy.nav_agent.get_next_path_position()
    var direction = enemy.global_position.direction_to(next_position)
    
    # Calculate speed with modifier
    var target_speed = enemy.move_speed * return_speed_modifier
    
    # Set velocity based on direction
    var target_velocity = direction * target_speed
    
    # Apply acceleration
    enemy.velocity = enemy.velocity.move_toward(target_velocity, enemy.acceleration * delta)

func _update_path() -> void:
    # Update path to home position
    enemy.nav_agent.target_position = enemy.home_position

func _update_animation() -> void:
    var movement = enemy.velocity.normalized()
    
    if movement.length() > 0.1:
        # Play walk animation based on direction
        if abs(movement.x) > abs(movement.y):
            if movement.x > 0:
                enemy.sprite.play("walk_right")
            else:
                enemy.sprite.play("walk_left")
        else:
            if movement.y > 0:
                enemy.sprite.play("walk_down")
            else:
                enemy.sprite.play("walk_up")
    else:
        # Fallback to idle animation if not moving
        if abs(enemy.facing_direction.x) > abs(enemy.facing_direction.y):
            if enemy.facing_direction.x > 0:
                enemy.sprite.play("idle_right")
            else:
                enemy.sprite.play("idle_left")
        else:
            if enemy.facing_direction.y > 0:
                enemy.sprite.play("idle_down")
            else:
                enemy.sprite.play("idle_up") 