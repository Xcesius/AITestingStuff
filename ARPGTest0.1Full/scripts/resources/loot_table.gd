extends Resource
class_name LootTable

class LootEntry:
    var item: ItemData
    var weight: float
    var min_count: int
    var max_count: int
    
    func _init(p_item: ItemData, p_weight: float = 1.0, p_min: int = 1, p_max: int = 1) -> void:
        item = p_item
        weight = p_weight
        min_count = p_min
        max_count = p_max

@export var entries: Array[LootEntry] = []
var total_weight: float = 0.0

func _init() -> void:
    randomize()

func add_entry(item: ItemData, weight: float = 1.0, min_count: int = 1, max_count: int = 1) -> void:
    var entry = LootEntry.new(item, weight, min_count, max_count)
    entries.append(entry)
    total_weight += weight

func roll_loot() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if total_weight <= 0:
        return result
        
    var roll = randf() * total_weight
    var current_weight = 0.0
    
    for entry in entries:
        current_weight += entry.weight
        if roll <= current_weight:
            var count = randi_range(entry.min_count, entry.max_count)
            result.append({
                "item": entry.item,
                "count": count
            })
            break
            
    return result 