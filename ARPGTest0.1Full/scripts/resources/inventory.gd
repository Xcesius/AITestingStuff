extends Resource
class_name Inventory

signal item_added(item: ItemData, slot: int)
signal item_removed(item: ItemData, slot: int)
signal item_used(item: ItemData, slot: int)
signal inventory_changed

class InventorySlot:
    var item: ItemData
    var count: int
    
    func _init(p_item: ItemData = null, p_count: int = 0) -> void:
        item = p_item
        count = p_count

@export var size: int = 20
var slots: Array[InventorySlot] = []

func _init() -> void:
    for i in range(size):
        slots.append(InventorySlot.new())

func add_item(item: ItemData, amount: int = 1) -> bool:
    if item == null:
        return false
        
    # Try to stack with existing items
    if item.stackable:
        for i in range(slots.size()):
            var slot = slots[i]
            if slot.item and slot.item.can_stack_with(item) and slot.count < slot.item.max_stack:
                var space = slot.item.max_stack - slot.count
                var add_amount = min(amount, space)
                slot.count += add_amount
                amount -= add_amount
                item_added.emit(item, i)
                if amount <= 0:
                    inventory_changed.emit()
                    return true
    
    # Find empty slots for remaining items
    for i in range(slots.size()):
        var slot = slots[i]
        if slot.item == null:
            slot.item = item
            slot.count = min(amount, item.max_stack)
            amount -= slot.count
            item_added.emit(item, i)
            if amount <= 0:
                inventory_changed.emit()
                return true
    
    inventory_changed.emit()
    return amount <= 0

func remove_item(slot_index: int, amount: int = 1) -> bool:
    if slot_index < 0 or slot_index >= slots.size():
        return false
        
    var slot = slots[slot_index]
    if slot.item == null or slot.count < amount:
        return false
        
    slot.count -= amount
    item_removed.emit(slot.item, slot_index)
    
    if slot.count <= 0:
        slot.item = null
        slot.count = 0
        
    inventory_changed.emit()
    return true

func use_item(slot_index: int, character_stats: CharacterStats) -> bool:
    if slot_index < 0 or slot_index >= slots.size():
        return false
        
    var slot = slots[slot_index]
    if slot.item == null:
        return false
        
    if slot.item.item_type == ItemData.ItemType.CONSUMABLE:
        slot.item.apply_effects(character_stats)
        remove_item(slot_index)
        item_used.emit(slot.item, slot_index)
        return true
        
    return false

func get_item(slot_index: int) -> ItemData:
    if slot_index < 0 or slot_index >= slots.size():
        return null
    return slots[slot_index].item

func get_item_count(slot_index: int) -> int:
    if slot_index < 0 or slot_index >= slots.size():
        return 0
    return slots[slot_index].count 