# MovementComponent.gd
class_name MovementComponent
extends Node

@export var move_speed: float = 100.0
signal moved(direction, delta)

func move(direction: Vector2, delta: float) -> void:
    # [MOVEMENT_LOGIC] e.g., move_and_slide
    emit_signal("moved", direction, delta) 