class_name EquipmentSystem
extends Resource

signal item_equipped(slot, item)
signal item_unequipped(slot, item)
signal equipment_changed

# Define equipment slots as constants
const SLOT_WEAPON = "weapon"
const SLOT_HELMET = "helmet"
const SLOT_ARMOR = "armor"
const SLOT_BOOTS = "boots"
const SLOT_ACCESSORY = "accessory"

# Dictionary of equipped items, indexed by slot
@export var equipped_items: Dictionary = {
    SLOT_WEAPON: null,
    SLOT_HELMET: null,
    SLOT_ARMOR: null,
    SLOT_BOOTS: null,
    SLOT_ACCESSORY: null
}

# Reference to the character's stats
var character_stats: CharacterStats
var inventory: Inventory

# Constructor
func _init(stats: CharacterStats = null, inv: Inventory = null):
    character_stats = stats
    inventory = inv

# Equip an item to the appropriate slot
func equip_item(item: EquipmentData) -> bool:
    if not item:
        return false
    
    # Get the slot this item belongs to
    var slot = item.get_equipment_slot()
    
    # Check if the slot is valid
    if not equipped_items.has(slot):
        return false
    
    # Check if character meets level requirements
    if character_stats and not item.can_equip(character_stats.level):
        return false
    
    # If there's an item already in that slot, unequip it first
    if equipped_items[slot]:
        unequip_item(slot)
    
    # Equip the new item
    equipped_items[slot] = item
    
    # Apply the item's stat bonuses
    if character_stats:
        _apply_equipment_bonuses()
    
    # Special handling for accessories
    if slot == SLOT_ACCESSORY and item is AccessoryData:
        if character_stats:
            item.on_equipped(character_stats)
    
    # Emit signals
    emit_signal("item_equipped", slot, item)
    emit_signal("equipment_changed")
    
    return true

# Unequip an item from a specific slot
func unequip_item(slot: String) -> EquipmentData:
    if not equipped_items.has(slot) or not equipped_items[slot]:
        return null
    
    var item = equipped_items[slot]
    
    # Special handling for accessories
    if slot == SLOT_ACCESSORY and item is AccessoryData and character_stats:
        item.on_unequipped(character_stats)
    
    # Remove the item from equipment
    equipped_items[slot] = null
    
    # Add back to inventory if possible
    if inventory and item:
        inventory.add_item(item)
    
    # Recalculate stats without this item
    if character_stats:
        _apply_equipment_bonuses()
    
    # Emit signals
    emit_signal("item_unequipped", slot, item)
    emit_signal("equipment_changed")
    
    return item

# Apply all equipment bonuses to character stats
func _apply_equipment_bonuses() -> void:
    if not character_stats:
        return
    
    # Reset equipment-based bonuses
    character_stats.reset_equipment_bonuses()
    
    # Apply bonuses from all equipped items
    for slot in equipped_items:
        var item = equipped_items[slot]
        if item:
            # Apply fixed stat bonuses
            var bonuses = item.get_stat_bonuses()
            for stat_name in bonuses:
                character_stats.apply_equipment_bonus(stat_name, bonuses[stat_name])
            
            # Apply percentage multipliers from accessories
            if slot == SLOT_ACCESSORY and item is AccessoryData:
                character_stats.apply_stat_multipliers(item.stat_multipliers)
            
            # Apply speed penalties from armor
            if (slot == SLOT_ARMOR or slot == SLOT_BOOTS) and item is ArmorData:
                character_stats.apply_equipment_bonus("move_speed", item.get_speed_penalty())

# Get equipped item in a specific slot
func get_equipped_item(slot: String) -> EquipmentData:
    if equipped_items.has(slot):
        return equipped_items[slot]
    return null

# Check if a slot has an item equipped
func has_item_equipped(slot: String) -> bool:
    return equipped_items.has(slot) and equipped_items[slot] != null

# Get total bonus for a specific stat from all equipment
func get_total_stat_bonus(stat_name: String) -> float:
    var total = 0.0
    for slot in equipped_items:
        var item = equipped_items[slot]
        if item:
            var bonuses = item.get_stat_bonuses()
            if bonuses.has(stat_name):
                total += bonuses[stat_name]
    return total

# Get specific information about equipped weapon
func get_weapon_data() -> WeaponData:
    var weapon = get_equipped_item(SLOT_WEAPON)
    if weapon and weapon is WeaponData:
        return weapon
    return null

# Calculate damage with equipped weapon
func calculate_weapon_damage(critical_chance: float = 0.0) -> int:
    var weapon = get_weapon_data()
    if weapon:
        # Check for critical hit
        var is_critical = randf() < critical_chance
        var critical_mult = 2.0 if is_critical else 1.0
        
        # Get damage with critical multiplier
        return weapon.calculate_damage(critical_mult)
    
    # No weapon equipped, use base damage
    return 5  # Default unarmed damage 