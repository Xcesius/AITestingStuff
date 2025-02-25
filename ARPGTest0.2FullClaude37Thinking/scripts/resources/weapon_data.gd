class_name WeaponData
extends EquipmentData

@export_category("Weapon Properties")
@export var base_damage: int = 10
@export var damage_range: float = 0.2  # Variation in damage (±20%)
@export var attack_speed: float = 1.0
@export var attack_range: float = 70.0
@export var knockback_force: float = 100.0

@export_category("Weapon Effects")
@export var weapon_effect_scene: PackedScene
@export var projectile_scene: PackedScene
@export var hit_effect_scene: PackedScene

# Weapon animation states
@export var attack_animation: String = "attack"
@export var charge_animation: String = "charge"
@export var combo_enabled: bool = false
@export var max_combo_chain: int = 3

func _init():
    super._init()
    equipment_type = EquipmentType.WEAPON
    weapon_type = WeaponType.SWORD
    
    # Ensure weapon effects field is populated
    if effect_description.is_empty():
        effect_description = "Standard weapon attack"

# Calculate actual damage with variation and critical hits
func calculate_damage(critical_mult: float = 1.0) -> int:
    var variation = randf_range(-damage_range, damage_range)
    var damage = base_damage * (1.0 + variation)
    
    # Apply critical multiplier if provided
    damage *= critical_mult
    
    return round(damage)

# Get attack cooldown time in seconds
func get_attack_cooldown() -> float:
    return 1.0 / (attack_speed * get_attack_speed_modifier())

# Get the combo animation name for the specified combo index
func get_combo_animation(combo_index: int) -> String:
    if not combo_enabled or combo_index <= 1:
        return attack_animation
    
    # Clamp to max combo chain
    var clamped_index = min(combo_index, max_combo_chain)
    return attack_animation + str(clamped_index)

# Determine if this weapon uses projectiles
func is_ranged_weapon() -> bool:
    return weapon_type == WeaponType.BOW or weapon_type == WeaponType.STAFF or weapon_type == WeaponType.WAND

# Get weapon tooltip description
func get_description() -> String:
    var desc = description
    if desc.is_empty():
        desc = weapon_type_to_string() + " - " + effect_description
    
    # Add damage and attack speed info
    desc += "\nDamage: " + str(base_damage)
    desc += "\nAttack Speed: " + str(attack_speed)
    
    # Add bonus stats if they exist
    var bonuses = get_stat_bonuses()
    for stat in bonuses:
        if bonuses[stat] != 0:
            desc += "\n+" + str(bonuses[stat]) + " " + stat.capitalize()
    
    return desc

# Convert weapon type enum to string
func weapon_type_to_string() -> String:
    match weapon_type:
        WeaponType.SWORD:
            return "Sword"
        WeaponType.AXE:
            return "Axe" 
        WeaponType.DAGGER:
            return "Dagger"
        WeaponType.BOW:
            return "Bow"
        WeaponType.STAFF:
            return "Staff"
        WeaponType.WAND:
            return "Wand"
        _:
            return "Unknown Weapon" 