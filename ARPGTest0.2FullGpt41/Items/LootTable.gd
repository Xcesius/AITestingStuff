# LootTable.gd
extends Resource
class_name LootTable

@export var items: Array[Dictionary] = [] # [{item: Resource, weight: int}, ...]

func get_random_loot():
    # Weighted random selection logic
    # [LOOT_SELECTION_LOGIC]
    return null 