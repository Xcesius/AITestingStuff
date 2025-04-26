# ExperienceComponent.gd
class_name ExperienceComponent
extends Node

@export var current_exp: int = 0
@export var exp_to_next_level: int = 100
signal leveled_up(new_level)

func add_experience(amount: int) -> void:
    current_exp += amount
    while current_exp >= exp_to_next_level:
        current_exp -= exp_to_next_level
        # [LEVEL_UP_LOGIC]
        emit_signal("leveled_up", get("level") + 1) 