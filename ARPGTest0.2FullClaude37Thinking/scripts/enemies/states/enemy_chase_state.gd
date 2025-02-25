class_name EnemyChaseState
extends EnemyState

# Chase behavior settings
@export var path_update_interval: float = 0.2
@export var max_chase_duration: float = 10.0
@export var lost_target_time: float = 2.0

# State variables
var path_update_timer: float = 0.0
var lost_target_timer: float = 0.0
var lost_sight: bool = false

func enter() -> void:
    super.enter()
    
    # Reset timers
    path_update_timer = 0.0
    lost_target_timer = 0.0
    lost_sight = false
    
    # Immediately update navigation path
    if enemy.target:
        enemy.nav_agent.target_position = enemy.target.global_position

func exit() -> void:
    # Nothing special needed when exiting chase state
    pass

func process(delta: float) -> void:
    super.process(delta)
    
    # Check for timeout (prevent infinite chasing)
    if time_in_state > max_chase_duration:
        change_state("return")
        return
    
    # Check if target exists
    if not enemy.target:
        change_state("return")
        return
    
    # Check if we can attack the target
    if enemy.can_attack_target():
        change_state("attack")
        return
    
    # Check if we lost sight of the target
    if not enemy.can_see_target():
        if not lost_sight:
            lost_sight = true
            lost_target_timer = 0.0
        else:
            lost_target_timer += delta
            if lost_target_timer >= lost_target_time:
                change_state("return")
                return
    else:
        lost_sight = false
        lost_target_timer = 0.0
    
    # Update navigation path periodically
    path_update_timer += delta
    if path_update_timer >= path_update_interval:
        path_update_timer = 0.0
        if enemy.target:
            enemy.nav_agent.target_position = enemy.target.global_position

func physics_process(delta: float) -> void:
    # Skip if knockback is active
    if enemy.knockback_timer > 0:
        return
    
    # If we have a target, navigate towards it
    if enemy.target:
        enemy.navigate_to_target(enemy.target.global_position, delta)
    else:
        # Apply friction if no target
        enemy.velocity = enemy.velocity.move_toward(Vector2.ZERO, enemy.friction * delta) 