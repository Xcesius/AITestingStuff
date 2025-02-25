class_name PlayerMoveState
extends State

@onready var player: PlayerController = owner as PlayerController

func enter() -> void:
    if abs(player.input_vector.x) > abs(player.input_vector.y):
        player.animation_player.play("walk_side")
        player.sprite.flip_h = player.input_vector.x < 0
    else:
        player.animation_player.play("walk_" + ("up" if player.input_vector.y < 0 else "down"))

func update(_delta: float) -> void:
    if player.input_vector == Vector2.ZERO:
        get_parent().transition_to("idle")
    
    if Input.is_action_just_pressed("attack"):
        get_parent().transition_to("attack")

func physics_update(_delta: float) -> void:
    if abs(player.input_vector.x) > abs(player.input_vector.y):
        player.sprite.flip_h = player.input_vector.x < 0
        player.animation_player.play("walk_side")
    else:
        player.animation_player.play("walk_" + ("up" if player.input_vector.y < 0 else "down")) 