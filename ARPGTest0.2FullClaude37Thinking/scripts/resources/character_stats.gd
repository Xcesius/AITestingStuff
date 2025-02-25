class_name CharacterStats
extends Resource

signal health_changed(current, maximum)
signal health_depleted
signal experience_gained(amount, current, required)
signal level_up(new_level)
signal stats_changed

@export var max_health: int = 100
@export var current_health: int = max_health
@export var attack_damage: int = 10
@export var defense: int = 1
@export var move_speed: float = 1.0
@export var attack_speed: float = 1.0
@export var level: int = 1
@export var experience: int = 0
@export var next_level_exp: int = 100

# Stats modifiers (from temporary buffs)
var health_modifier: int = 0
var damage_modifier: int = 0
var defense_modifier: int = 0
var speed_modifier: float = 0.0
var attack_speed_modifier: float = 0.0

# Equipment-based stat bonuses (permanent until unequipped)
var equipment_health_bonus: int = 0
var equipment_damage_bonus: int = 0
var equipment_defense_bonus: int = 0
var equipment_speed_bonus: float = 0.0
var equipment_attack_speed_bonus: float = 0.0

# Dictionary for storing percentage-based stat modifiers (from accessories)
var stat_percentage_modifiers: Dictionary = {
    "max_health": 1.0,
    "attack_damage": 1.0,
    "defense": 1.0,
    "move_speed": 1.0,
    "attack_speed": 1.0
}

func _init(p_max_health: int = 100, p_attack: int = 10, p_defense: int = 1, 
          p_move_speed: float = 1.0, p_attack_speed: float = 1.0) -> void:
    max_health = p_max_health
    current_health = max_health
    attack_damage = p_attack
    defense = p_defense
    move_speed = p_move_speed
    attack_speed = p_attack_speed

func take_damage(amount: int) -> int:
    var actual_damage = max(amount - get_total_defense(), 1)
    current_health = max(current_health - actual_damage, 0)
    
    emit_signal("health_changed", current_health, get_total_max_health())
    
    if current_health <= 0:
        emit_signal("health_depleted")
    
    return actual_damage
    
func heal(amount: int) -> void:
    current_health = min(current_health + amount, get_total_max_health())
    emit_signal("health_changed", current_health, get_total_max_health())
    
func is_alive() -> bool:
    return current_health > 0
    
func add_experience(amount: int) -> bool:
    experience += amount
    emit_signal("experience_gained", amount, experience, next_level_exp)
    
    if experience >= next_level_exp:
        level_up()
        return true
    return false
    
func level_up() -> void:
    level += 1
    experience -= next_level_exp
    next_level_exp = int(next_level_exp * 1.5)
    
    # Increase stats with level up
    max_health += 5
    current_health = get_total_max_health()  # Full heal on level up
    attack_damage += 2
    defense += 1
    
    emit_signal("level_up", level)
    emit_signal("health_changed", current_health, get_total_max_health())
    emit_signal("stats_changed")

# Stat calculation methods that include modifiers and equipment bonuses
func get_total_max_health() -> int:
    return int((max_health + health_modifier + equipment_health_bonus) * stat_percentage_modifiers["max_health"])
    
func get_total_attack() -> int:
    return int((attack_damage + damage_modifier + equipment_damage_bonus) * stat_percentage_modifiers["attack_damage"])
    
func get_total_defense() -> int:
    return int((defense + defense_modifier + equipment_defense_bonus) * stat_percentage_modifiers["defense"])
    
func get_total_move_speed() -> float:
    return (move_speed + speed_modifier + equipment_speed_bonus) * stat_percentage_modifiers["move_speed"]
    
func get_total_attack_speed() -> float:
    return (attack_speed + attack_speed_modifier + equipment_attack_speed_bonus) * stat_percentage_modifiers["attack_speed"]

# Apply a temporary stat modifier (e.g., from buffs)
func apply_stat_modifier(stat_type: String, value: float, duration: float = 0.0) -> void:
    match stat_type:
        "health":
            health_modifier += int(value)
            # Adjust current health if max health increased
            if value > 0:
                current_health += int(value)
            emit_signal("health_changed", current_health, get_total_max_health())
        "damage":
            damage_modifier += int(value)
        "defense":
            defense_modifier += int(value)
        "speed":
            speed_modifier += value
        "attack_speed":
            attack_speed_modifier += value
    
    emit_signal("stats_changed")
    
    # If duration specified, schedule removal of the modifier
    if duration > 0:
        var timer = (Engine.get_main_loop() as SceneTree).create_timer(duration)
        timer.timeout.connect(func(): remove_stat_modifier(stat_type, value))

# Remove a temporary stat modifier
func remove_stat_modifier(stat_type: String, value: float) -> void:
    match stat_type:
        "health":
            health_modifier -= int(value)
            # Ensure current health doesn't exceed new max
            current_health = min(current_health, get_total_max_health())
            emit_signal("health_changed", current_health, get_total_max_health())
        "damage":
            damage_modifier -= int(value)
        "defense":
            defense_modifier -= int(value)
        "speed":
            speed_modifier -= value
        "attack_speed":
            attack_speed_modifier -= value
    
    emit_signal("stats_changed")

# Apply equipment bonuses
func apply_equipment_bonus(stat_type: String, value: float) -> void:
    match stat_type:
        "max_health":
            equipment_health_bonus += int(value)
            # Adjust current health if max health increased
            if value > 0:
                current_health += int(value)
            emit_signal("health_changed", current_health, get_total_max_health())
        "attack_damage":
            equipment_damage_bonus += int(value)
        "defense":
            equipment_defense_bonus += int(value)
        "move_speed":
            equipment_speed_bonus += value
        "attack_speed":
            equipment_attack_speed_bonus += value
    
    emit_signal("stats_changed")

# Apply percentage-based stat multipliers (from accessories)
func apply_stat_multipliers(multipliers: Dictionary) -> void:
    for stat_name in multipliers:
        if stat_percentage_modifiers.has(stat_name):
            stat_percentage_modifiers[stat_name] *= (1.0 + multipliers[stat_name])
    
    # Update health display if max health was affected
    if multipliers.has("max_health"):
        emit_signal("health_changed", current_health, get_total_max_health())
    
    emit_signal("stats_changed")

# Reset all equipment-based stat bonuses (called when recalculating equipment)
func reset_equipment_bonuses() -> void:
    equipment_health_bonus = 0
    equipment_damage_bonus = 0
    equipment_defense_bonus = 0
    equipment_speed_bonus = 0.0
    equipment_attack_speed_bonus = 0.0
    
    # Reset percentage modifiers
    stat_percentage_modifiers = {
        "max_health": 1.0,
        "attack_damage": 1.0,
        "defense": 1.0,
        "move_speed": 1.0,
        "attack_speed": 1.0
    }
    
    # Update health display
    emit_signal("health_changed", current_health, get_total_max_health())
    emit_signal("stats_changed")

# Get a stat value by name (used by UI and other systems)
func get_stat_value(stat_name: String) -> float:
    match stat_name:
        "max_health": return get_total_max_health()
        "current_health": return current_health
        "attack_damage": return get_total_attack()
        "defense": return get_total_defense()
        "move_speed": return get_total_move_speed()
        "attack_speed": return get_total_attack_speed()
        "level": return level
        "experience": return experience
        "next_level_exp": return next_level_exp
    return 0.0