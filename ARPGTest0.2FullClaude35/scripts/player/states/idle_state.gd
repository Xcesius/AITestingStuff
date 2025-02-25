class_name PlayerIdleState
extends State

@onready var player: PlayerController = owner as PlayerController

func enter() -> void:
    player.animation_player.play("idle")

func update(_delta: float) -> void:
    if player.input_vector != Vector2.ZERO:
        get_parent().transition_to("move")
    
    if Input.is_action_just_pressed("attack"):
        get_parent().transition_to("attack") 