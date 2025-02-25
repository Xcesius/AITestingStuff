class_name PlayerController
extends CharacterBody2D

@export var stats: CharacterStats
@export var acceleration: float = 2000.0
@export var friction: float = 1000.0

@onready var state_machine: StateMachine = $StateMachine
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

var input_vector: Vector2 = Vector2.ZERO

func _ready() -> void:
    if not stats:
        stats = CharacterStats.new()

func _physics_process(delta: float) -> void:
    handle_input()
    apply_movement(delta)
    move_and_slide()
    update_animation()

func handle_input() -> void:
    input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    input_vector = input_vector.normalized()

func apply_movement(delta: float) -> void:
    if input_vector != Vector2.ZERO:
        velocity += input_vector * acceleration * delta
        velocity = velocity.limit_length(stats.move_speed)
    else:
        var friction_vector = velocity.normalized() * friction * delta
        if friction_vector.length() > velocity.length():
            velocity = Vector2.ZERO
        else:
            velocity -= friction_vector

func update_animation() -> void:
    if input_vector != Vector2.ZERO:
        if abs(input_vector.x) > abs(input_vector.y):
            sprite.flip_h = input_vector.x < 0
            animation_player.play("walk_side")
        else:
            animation_player.play("walk_" + ("up" if input_vector.y < 0 else "down"))
    else:
        animation_player.play("idle") 