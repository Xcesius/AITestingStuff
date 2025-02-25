class_name EnemyWanderState
extends EnemyState

# Wander behavior settings
@export var min_wander_time: float = 1.0
@export var max_wander_time: float = 3.0
@export var wander_speed_modifier: float = 0.7
@export var direction_change_time: float = 1.5

# State variables
var wander_duration: float
var direction_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
var wander_target: Vector2

func _ready() -> void:
    randomize()

func enter() -> void:
    super.enter()
    
    # Determine wander duration
    wander_duration = randf_range(min_wander_time, max_wander_time)
    
    # Choose initial wander direction and target
    _choose_wander_direction()
    
    # Play walk animation
    _update_animation()

func exit() -> void:
    # Reset wander direction
    wander_direction = Vector2.ZERO

func process(delta: float) -> void:
    super.process(delta)
    
    # Check if we should transition to chase
    if enemy.target and enemy.can_see_target():
        change_state("chase")
        return
    
    # Check if we've wandered long enough
    if time_in_state >= wander_duration:
        change_state("idle")
        return
    
    # Change direction periodically
    direction_timer += delta
    if direction_timer >= direction_change_time:
        direction_timer = 0.0
        _choose_wander_direction()
    
    # Update animation based on movement
    _update_animation()
    
    # Check if we've reached the wander target
    var distance_to_target = enemy.global_position.distance_to(wander_target)
    if distance_to_target < 5.0:  # Close enough to target
        _choose_wander_direction()

func physics_process(delta: float) -> void:
    # Skip if knockback is active
    if enemy.knockback_timer > 0:
        return
    
    # Calculate speed with modifier
    var target_speed = enemy.move_speed * wander_speed_modifier
    
    # Set velocity based on wander direction
    var target_velocity = wander_direction * target_speed
    
    # Apply acceleration
    enemy.velocity = enemy.velocity.move_toward(target_velocity, enemy.acceleration * delta)
    
    # Move the enemy
    enemy.move_and_slide()
    
    # Update facing direction based on movement
    if enemy.velocity.length() > 0.1:
        enemy.facing_direction = enemy.velocity.normalized()

func _choose_wander_direction() -> void:
    # Choose a random angle
    var angle = randf_range(0, 2 * PI)
    wander_direction = Vector2(cos(angle), sin(angle)).normalized()
    
    # Set wander target within the wander radius
    var target_distance = randf_range(20, enemy.wander_radius)
    wander_target = enemy.global_position + (wander_direction * target_distance)
    
    # Check if target is too far from home position
    var distance_from_home = wander_target.distance_to(enemy.home_position)
    if distance_from_home > enemy.wander_radius:
        # Adjust target to stay within wander radius of home
        var direction_to_home = (enemy.home_position - enemy.global_position).normalized()
        wander_direction = direction_to_home
        wander_target = enemy.home_position + (wander_direction * enemy.wander_radius * 0.8)

func _update_animation() -> void:
    if wander_direction.length() > 0.1:
        # Play walk animation based on direction
        if abs(wander_direction.x) > abs(wander_direction.y):
            if wander_direction.x > 0:
                enemy.sprite.play("walk_right")
            else:
                enemy.sprite.play("walk_left")
        else:
            if wander_direction.y > 0:
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