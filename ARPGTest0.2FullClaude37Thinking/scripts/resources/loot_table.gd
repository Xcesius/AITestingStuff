class_name LootTable
extends Resource

signal loot_generated(items)

# Inner class to define a loot entry
class LootEntry:
    var item_id: String
    var weight: int
    var min_count: int
    var max_count: int
    
    func _init(p_item_id: String, p_weight: int = 10, p_min_count: int = 1, p_max_count: int = 1) -> void:
        item_id = p_item_id
        weight = p_weight
        min_count = p_min_count
        max_count = p_max_count

# Table properties
@export var table_id: String = "loot_table_001"
@export var guaranteed_drops: Array[String] = []
@export var drop_chance: float = 1.0  # 0-1 chance of any drop happening
@export var min_drops: int = 0
@export var max_drops: int = 3
@export var level_bonus: float = 0.0  # Additional drops based on level

# Store entries in a private variable
var _entries: Array[LootEntry] = []
var _total_weight: int = 0

func _init(p_table_id: String = "loot_table_001") -> void:
    table_id = p_table_id

# Add a loot entry to the table
func add_entry(item_id: String, weight: int = 10, min_count: int = 1, max_count: int = 1) -> void:
    var entry = LootEntry.new(item_id, weight, min_count, max_count)
    _entries.append(entry)
    _total_weight += weight

# Remove an entry from the table
func remove_entry(item_id: String) -> bool:
    for i in range(_entries.size()):
        if _entries[i].item_id == item_id:
            _total_weight -= _entries[i].weight
            _entries.remove_at(i)
            return true
    return false

# Get all items in this loot table
func get_all_items() -> Array[String]:
    var items: Array[String] = []
    for entry in _entries:
        items.append(entry.item_id)
    return items

# Roll for loot based on table configuration
func roll_loot(level: int = 1) -> Array:
    var result = []
    
    # Add guaranteed drops first
    for item_id in guaranteed_drops:
        result.append({"item_id": item_id, "count": 1})
    
    # Check if we get any random drops
    if randf() > drop_chance:
        return result
    
    # Calculate number of drops
    var level_modifier = level * level_bonus
    var num_drops = randi_range(min_drops, max_drops) + int(level_modifier)
    
    # Roll for each drop
    for i in range(num_drops):
        if _total_weight > 0 and _entries.size() > 0:
            var drop = _roll_single_drop()
            if drop:
                result.append(drop)
    
    emit_signal("loot_generated", result)
    return result

# Roll for a single item drop
func _roll_single_drop() -> Dictionary:
    if _total_weight <= 0 or _entries.size() <= 0:
        return {}
    
    var roll = randi_range(1, _total_weight)
    var current_weight = 0
    
    for entry in _entries:
        current_weight += entry.weight
        if roll <= current_weight:
            var count = randi_range(entry.min_count, entry.max_count)
            return {"item_id": entry.item_id, "count": count}
    
    return {}

# Create a loot table with common preset configurations
static func create_common_table(table_id: String, tier: int = 1) -> LootTable:
    var table = LootTable.new(table_id)
    
    # Configure based on tier
    match tier:
        1: # Tier 1 (Common enemies)
            table.drop_chance = 0.7
            table.min_drops = 0
            table.max_drops = 1
            table.add_entry("gold_coin", 100, 1, 5)
            table.add_entry("health_potion_small", 20)
            table.add_entry("arrow", 30, 3, 8)
        2: # Tier 2 (Uncommon enemies)
            table.drop_chance = 0.8
            table.min_drops = 1
            table.max_drops = 2
            table.add_entry("gold_coin", 100, 5, 15)
            table.add_entry("health_potion_small", 30)
            table.add_entry("mana_potion_small", 30)
            table.add_entry("leather", 40, 1, 3)
        3: # Tier 3 (Elite enemies)
            table.drop_chance = 0.9
            table.min_drops = 1
            table.max_drops = 3
            table.add_entry("gold_coin", 100, 15, 30)
            table.add_entry("health_potion_medium", 40)
            table.add_entry("mana_potion_medium", 40)
            table.add_entry("iron_ingot", 30, 1, 2)
            table.add_entry("rare_gem", 10)
        4: # Tier 4 (Boss enemies)
            table.drop_chance = 1.0
            table.min_drops = 3
            table.max_drops = 5
            table.guaranteed_drops = ["unique_boss_item"]
            table.add_entry("gold_coin", 100, 50, 100)
            table.add_entry("health_potion_large", 50)
            table.add_entry("mana_potion_large", 50)
            table.add_entry("rare_gem", 30, 1, 3)
            table.add_entry("ancient_artifact", 15)
    
    return table 