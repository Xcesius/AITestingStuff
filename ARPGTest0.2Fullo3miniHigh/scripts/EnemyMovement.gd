# EnemyMovement.gd
extends CharacterBody2D

enum { STATE_IDLE, STATE_CHASE, STATE_ATTACK }
var current_state = STATE_IDLE
var target = null  # Typically, set to the player node at runtime

func _ready():
    # Optionally, initialize NavigationAgent2D for advanced pathfinding.
    pass

func _physics_process(delta):
    update_state()
    match current_state:
        STATE_IDLE: _idle_behavior(delta)
        STATE_CHASE: _chase_behavior(delta)
        STATE_ATTACK: _attack_behavior(delta)

func update_state():
    # Update state based on conditions such as distance to player
    if target and position.distance_to(target.position) < [ENEMY_ATTACK_RANGE]:
        current_state = STATE_ATTACK
    elif target:
        current_state = STATE_CHASE
    else:
        current_state = STATE_IDLE

func _idle_behavior(delta):
    # Idle behavior, e.g., play idle animation
    $AnimatedSprite2D.play("idle")  # Replace with the proper animation name

func _chase_behavior(delta):
    $AnimatedSprite2D.play("walk")  # Replace with the proper animation name
    var direction = (target.position - position).normalized()
    move_and_slide(direction * [ENEMY_MOVE_SPEED])

func _attack_behavior(delta):
    $AnimatedSprite2D.play("[ENEMY_ATTACK_ANIMATION_NAME]")
    # Insert attack logic, cooldowns, etc. 