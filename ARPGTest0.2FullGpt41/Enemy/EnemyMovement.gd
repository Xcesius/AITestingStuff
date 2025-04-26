# EnemyMovement.gd
extends CharacterBody2D

@export var stats: Resource # [PATH_TO_ENEMY_STATS_RESOURCE]
@onready var player = null

enum State { IDLE, CHASING, ATTACKING, RETREATING, DEAD }
var state = State.IDLE

signal state_changed(new_state)

func _ready():
    player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
    match state:
        State.IDLE:
            if _can_see_player():
                state = State.CHASING
                emit_signal("state_changed", state)
        State.CHASING:
            _chase_player()
        State.ATTACKING:
            # [ENEMY_ATTACK_LOGIC]
            pass
        State.RETREATING:
            # [ENEMY_RETREAT_LOGIC]
            pass
        State.DEAD:
            velocity = Vector2.ZERO

func _can_see_player():
    return player and global_position.distance_to(player.global_position) < [ENEMY_DETECTION_RANGE]

func _chase_player():
    if player:
        var direction = (player.global_position - global_position).normalized()
        velocity = direction * stats.move_speed
        move_and_slide() 