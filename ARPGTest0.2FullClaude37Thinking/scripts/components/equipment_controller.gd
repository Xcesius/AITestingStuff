class_name EquipmentController
extends Node

signal equipment_changed

# Equipment system resource
@export var equipment_system: EquipmentSystem

# Reference to the character's inventory and stats
var inventory: Inventory
var character_stats: CharacterStats

# Setup equipment system
func initialize(inv: Inventory, stats: CharacterStats) -> void:
    inventory = inv
    character_stats = stats
    
    # Create equipment system if not already assigned
    if not equipment_system:
        equipment_system = EquipmentSystem.new(stats, inv)
    else:
        equipment_system.character_stats = stats
        equipment_system.inventory = inv
    
    # Connect signals
    equipment_system.equipment_changed.connect(_on_equipment_changed)
    equipment_system.item_equipped.connect(_on_item_equipped)
    equipment_system.item_unequipped.connect(_on_item_unequipped)

# Equip an item from inventory
func equip_item_from_inventory(item: EquipmentData) -> bool:
    if not item or not equipment_system:
        return false
    
    # Check if in inventory
    if not inventory.has_item(item):
        return false
    
    # Remove from inventory and equip
    inventory.remove_item(item)
    return equipment_system.equip_item(item)

# Unequip an item from a specific slot
func unequip_item(slot: String) -> bool:
    if not equipment_system:
        return false
    
    var item = equipment_system.unequip_item(slot)
    return item != null

# Check if a slot has an item equipped
func has_item_equipped(slot: String) -> bool:
    if not equipment_system:
        return false
    
    return equipment_system.has_item_equipped(slot)

# Get equipped item in a specific slot
func get_equipped_item(slot: String) -> EquipmentData:
    if not equipment_system:
        return null
    
    return equipment_system.get_equipped_item(slot)

# Get all equipped items as a dictionary
func get_all_equipment() -> Dictionary:
    if not equipment_system:
        return {}
    
    return equipment_system.equipped_items

# Check if a specific item is equipped
func is_item_equipped(item: EquipmentData) -> bool:
    if not equipment_system or not item:
        return false
    
    for slot in equipment_system.equipped_items:
        if equipment_system.equipped_items[slot] == item:
            return true
    
    return false

# Calculate weapon damage with equipped weapon
func calculate_weapon_damage() -> int:
    if not equipment_system:
        return 5  # Default damage
    
    # Pass character's critical chance if available
    var crit_chance = 0.05  # Default 5% critical chance
    if character_stats:
        # Check if character has critical chance stat (could be added later)
        if character_stats.get("critical_chance"):
            crit_chance = character_stats.critical_chance
    
    return equipment_system.calculate_weapon_damage(crit_chance)

# Signal handlers
func _on_equipment_changed() -> void:
    emit_signal("equipment_changed")

func _on_item_equipped(slot: String, item: EquipmentData) -> void:
    # Additional logic for when an item is equipped
    # For example, change character appearance based on equipment
    pass

func _on_item_unequipped(slot: String, item: EquipmentData) -> void:
    # Additional logic for when an item is unequipped
    pass