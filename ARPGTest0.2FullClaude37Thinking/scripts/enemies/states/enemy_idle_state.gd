class_name EnemyIdleState
extends EnemyState

# Idle behavior settings
@export var min_idle_time: float = 1.0
@export var max_idle_time: float = 3.0
@export var wander_chance: float = 0.5

# State variables
var idle_duration: float
var should_wander: bool = false

func _ready() -> void:
    randomize()

func enter() -> void:
    super.enter()
    
    # Play idle animation
    var facing = enemy.facing_direction
    
    if abs(facing.x) > abs(facing.y):
        if facing.x > 0:
            enemy.sprite.play("idle_right")
        else:
            enemy.sprite.play("idle_left")
    else:
        if facing.y > 0:
            enemy.sprite.play("idle_down")
        else:
            enemy.sprite.play("idle_up")
    
    # Apply friction to stop movement
    enemy.velocity = Vector2.ZERO
    
    # Determine idle duration and behavior
    idle_duration = randf_range(min_idle_time, max_idle_time)
    should_wander = randf() < wander_chance

func exit() -> void:
    # Nothing special needed when exiting idle state
    pass

func process(delta: float) -> void:
    super.process(delta)
    
    # Check if we should transition to another state
    if enemy.target and enemy.can_see_target():
        change_state("chase")
        return
    
    # Check if idle time has elapsed
    if time_in_state >= idle_duration:
        if should_wander:
            change_state("wander")
        else:
            # Reset idle with new duration and behavior
            idle_duration = randf_range(min_idle_time, max_idle_time)
            should_wander = randf() < wander_chance
            time_in_state = 0

func physics_process(delta: float) -> void:
    # Apply friction to ensure the enemy stays still
    enemy.velocity = enemy.velocity.move_toward(Vector2.ZERO, enemy.friction * delta)
    enemy.move_and_slide() 