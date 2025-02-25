class_name CharacterStats
extends Resource

signal health_changed(new_health: float, max_health: float)
signal died

@export var max_health: float = 100.0
@export var attack_damage: float = 10.0
@export var defense: float = 5.0
@export var move_speed: float = 300.0
@export var attack_speed: float = 1.0
@export var attack_range: float = 50.0

var current_health: float:
    set(value):
        current_health = clamp(value, 0, max_health)
        emit_signal("health_changed", current_health, max_health)
        if current_health <= 0:
            emit_signal("died")
    get:
        return current_health

func _init() -> void:
    current_health = max_health

func take_damage(amount: float) -> void:
    var actual_damage = max(0, amount - defense)
    current_health -= actual_damage

func heal(amount: float) -> void:
    current_health += amount

func is_alive() -> bool:
    return current_health > 0 