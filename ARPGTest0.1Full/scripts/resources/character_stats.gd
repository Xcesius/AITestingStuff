extends Resource
class_name CharacterStats

@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var attack: float = 10.0
@export var defense: float = 5.0
@export var speed: float = 100.0
@export var attack_speed: float = 1.0
@export var attack_range: float = 32.0

signal health_changed(new_health: float, max_health: float)
signal character_died

func take_damage(damage: float) -> void:
    var actual_damage = max(damage - defense, 1)
    current_health = max(current_health - actual_damage, 0)
    health_changed.emit(current_health, max_health)
    
    if current_health <= 0:
        character_died.emit()

func heal(amount: float) -> void:
    current_health = min(current_health + amount, max_health)
    health_changed.emit(current_health, max_health)

func is_alive() -> bool:
    return current_health > 0 