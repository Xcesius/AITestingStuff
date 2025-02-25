class_name AccessoryData
extends EquipmentData

enum AccessoryType {
    RING,
    AMULET,
    BELT,
    CHARM
}

@export_category("Accessory Properties")
@export var accessory_type: AccessoryType = AccessoryType.RING
@export var unique_effect: String = ""
@export var passive_skill: String = ""
@export var stat_multipliers: Dictionary = {}  # Percentage multipliers for various stats

func _init():
    super._init()
    equipment_type = EquipmentType.ACCESSORY

# Apply percentage-based stat bonuses
func apply_stat_multipliers(stats: Dictionary) -> Dictionary:
    var modified_stats = stats.duplicate()
    
    # Apply multipliers to existing stats
    for stat in stat_multipliers:
        if modified_stats.has(stat):
            modified_stats[stat] = modified_stats[stat] * (1.0 + stat_multipliers[stat])
    
    return modified_stats

# Get accessory type as string
func get_accessory_type_string() -> String:
    match accessory_type:
        AccessoryType.RING:
            return "Ring"
        AccessoryType.AMULET:
            return "Amulet"
        AccessoryType.BELT:
            return "Belt"
        AccessoryType.CHARM:
            return "Charm"
        _:
            return "Unknown"

# Get complete description for tooltip
func get_description() -> String:
    var desc = description
    if desc.is_empty():
        desc = get_accessory_type_string()
        if not unique_effect.is_empty():
            desc += " - " + unique_effect
    
    # Add passive skill information if available
    if not passive_skill.is_empty():
        desc += "\nPassive: " + passive_skill
    
    # Add stat bonuses
    var bonuses = get_stat_bonuses()
    for stat in bonuses:
        if bonuses[stat] != 0:
            desc += "\n+" + str(bonuses[stat]) + " " + stat.capitalize()
    
    # Add stat multipliers
    for stat in stat_multipliers:
        if stat_multipliers[stat] != 0:
            var percentage = int(stat_multipliers[stat] * 100)
            desc += "\n+" + str(percentage) + "% " + stat.capitalize()
    
    return desc

# Special method to handle unique effects when equipped
func on_equipped(character: Node) -> void:
    # This method would be implemented for specific items with unique effects
    pass

# Special method to handle unique effects when unequipped
func on_unequipped(character: Node) -> void:
    # This method would be implemented for specific items with unique effects
    pass 