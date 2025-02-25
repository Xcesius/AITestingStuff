class_name ArmorData
extends EquipmentData

enum ArmorWeight {
    LIGHT,
    MEDIUM,
    HEAVY
}

@export_category("Armor Properties")
@export var armor_weight: ArmorWeight = ArmorWeight.MEDIUM
@export var damage_reduction: float = 0.0  # Percentage of damage reduced (0.0 to 1.0)
@export var elemental_resistance: Dictionary = {}  # Resistances to different damage types

func _init():
    super._init()
    
    # Set default equipment type based on the calling class
    var class_name = get_script().resource_path.get_file().get_basename()
    if class_name == "armor_data":
        equipment_type = EquipmentType.ARMOR
    elif class_name == "helmet_data":
        equipment_type = EquipmentType.HELMET
    elif class_name == "boots_data":
        equipment_type = EquipmentType.BOOTS

# Get movement speed penalty based on armor weight
func get_speed_penalty() -> float:
    match armor_weight:
        ArmorWeight.LIGHT:
            return 0.0  # No penalty
        ArmorWeight.MEDIUM:
            return -0.05  # 5% speed reduction
        ArmorWeight.HEAVY:
            return -0.15  # 15% speed reduction
        _:
            return 0.0

# Calculate final damage reduction including all factors
func calculate_damage_reduction(damage_type: String = "physical") -> float:
    var base_reduction = damage_reduction
    
    # Add elemental resistance if applicable
    if elemental_resistance.has(damage_type):
        base_reduction += elemental_resistance[damage_type]
    
    # Ensure reduction is within bounds (0-80%)
    return clamp(base_reduction, 0.0, 0.8)

# Get armor type as string
func get_armor_weight_string() -> String:
    match armor_weight:
        ArmorWeight.LIGHT:
            return "Light"
        ArmorWeight.MEDIUM:
            return "Medium"
        ArmorWeight.HEAVY:
            return "Heavy"
        _:
            return "Unknown"

# Get equipment slot name
func get_slot_name() -> String:
    match equipment_type:
        EquipmentType.HELMET:
            return "Helmet"
        EquipmentType.ARMOR:
            return "Armor"
        EquipmentType.BOOTS:
            return "Boots"
        _:
            return "Unknown"

# Get complete description for tooltip
func get_description() -> String:
    var desc = description
    if desc.is_empty():
        desc = get_slot_name() + " - " + get_armor_weight_string()
    
    # Add defense info
    desc += "\nDefense: " + str(defense_bonus)
    
    # Add damage reduction info
    if damage_reduction > 0:
        desc += "\nDamage Reduction: " + str(int(damage_reduction * 100)) + "%"
    
    # Add elemental resistances if any
    if not elemental_resistance.is_empty():
        desc += "\nResistances:"
        for element in elemental_resistance:
            desc += "\n  " + element.capitalize() + ": " + str(int(elemental_resistance[element] * 100)) + "%"
    
    # Add bonus stats if they exist
    var bonuses = get_stat_bonuses()
    for stat in bonuses:
        if bonuses[stat] != 0 and stat != "defense":  # Defense already shown above
            desc += "\n+" + str(bonuses[stat]) + " " + stat.capitalize()
    
    # Add speed penalty if applicable
    var speed_penalty = get_speed_penalty()
    if speed_penalty < 0:
        desc += "\nSpeed Penalty: " + str(int(speed_penalty * 100)) + "%"
    
    return desc 