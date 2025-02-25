class_name EquipmentData
extends ItemData

enum EquipmentType {
    WEAPON,
    HELMET,
    ARMOR,
    BOOTS,
    ACCESSORY
}

enum WeaponType {
    SWORD,
    AXE,
    DAGGER,
    BOW,
    STAFF,
    WAND
}

@export_category("Equipment Properties")
@export var equipment_type: EquipmentType
@export var weapon_type: WeaponType
@export var level_requirement: int = 1
@export var two_handed: bool = false

@export_category("Stat Bonuses")
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var health_bonus: int = 0
@export var speed_bonus: float = 0.0
@export var critical_chance_bonus: float = 0.0
@export var critical_damage_bonus: float = 0.0

@export_category("Special Effects")
@export var has_special_effect: bool = false
@export var effect_description: String = ""
@export var effect_trigger_chance: float = 0.0

# Dictionary of stat modifiers for more flexible stats
var stat_modifiers: Dictionary = {}

# Returns a dictionary of all bonuses this equipment provides
func get_stat_bonuses() -> Dictionary:
    var bonuses = {
        "attack": attack_bonus,
        "defense": defense_bonus,
        "max_health": health_bonus,
        "move_speed": speed_bonus,
        "critical_chance": critical_chance_bonus,
        "critical_damage": critical_damage_bonus
    }
    
    # Add any additional modifiers from the stat_modifiers dictionary
    for stat in stat_modifiers:
        if bonuses.has(stat):
            bonuses[stat] += stat_modifiers[stat]
        else:
            bonuses[stat] = stat_modifiers[stat]
    
    return bonuses

# Overrides from ItemData
func _init():
    item_type = ItemType.EQUIPMENT
    stackable = false
    
# Get the equipment slot this item belongs to
func get_equipment_slot() -> String:
    match equipment_type:
        EquipmentType.WEAPON:
            return "weapon"
        EquipmentType.HELMET:
            return "helmet"
        EquipmentType.ARMOR:
            return "armor"
        EquipmentType.BOOTS:
            return "boots"
        EquipmentType.ACCESSORY:
            return "accessory"
        _:
            return "none"

# For weapons, get attack speed modifier based on weapon type
func get_attack_speed_modifier() -> float:
    match weapon_type:
        WeaponType.DAGGER:
            return 1.3  # Daggers are fast
        WeaponType.BOW:
            return 0.8  # Bows are slower
        WeaponType.AXE:
            return 0.7  # Axes are slower
        WeaponType.SWORD:
            return 1.0  # Swords are average
        WeaponType.STAFF, WeaponType.WAND:
            return 0.9  # Magic weapons are slightly slower
        _:
            return 1.0

# Check if player meets level requirements
func can_equip(player_level: int) -> bool:
    return player_level >= level_requirement

# Get weapon range based on type
func get_weapon_range() -> float:
    match weapon_type:
        WeaponType.BOW:
            return 200.0  # Bows have long range
        WeaponType.STAFF, WeaponType.WAND:
            return 150.0  # Magic weapons have medium-long range
        WeaponType.SWORD, WeaponType.AXE:
            return 70.0   # Melee weapons have short range
        WeaponType.DAGGER:
            return 50.0   # Daggers have very short range
        _:
            return 70.0 