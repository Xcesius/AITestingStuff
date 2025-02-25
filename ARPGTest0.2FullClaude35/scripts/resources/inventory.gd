class_name Inventory
extends Resource

signal item_added(item: ItemData, slot: int)
signal item_removed(item: ItemData, slot: int)
signal item_used(item: ItemData, slot: int)
signal inventory_changed

class InventorySlot:
    var item: ItemData
    var quantity: int = 0
    
    func empty() -> bool:
        return item == null or quantity <= 0

@export var size: int = 20
var slots: Array[InventorySlot]

func _init() -> void:
    slots.resize(size)
    for i in range(size):
        slots[i] = InventorySlot.new()

func add_item(item: ItemData, amount: int = 1) -> bool:
    if item.stackable:
        # Try to stack with existing items
        for slot in slots:
            if slot.item and slot.item.can_stack_with(item) and slot.quantity < slot.item.max_stack_size:
                var space = slot.item.max_stack_size - slot.quantity
                var add_amount = min(amount, space)
                slot.quantity += add_amount
                amount -= add_amount
                emit_signal("inventory_changed")
                if amount <= 0:
                    return true
    
    # Find empty slots for remaining items
    for i in range(slots.size()):
        var slot = slots[i]
        if slot.empty():
            slot.item = item
            slot.quantity = min(amount, item.max_stack_size)
            amount -= slot.quantity
            emit_signal("item_added", item, i)
            emit_signal("inventory_changed")
            if amount <= 0:
                return true
    
    return amount <= 0  # Return true if all items were added

func remove_item(slot_index: int, amount: int = 1) -> bool:
    if slot_index < 0 or slot_index >= slots.size():
        return false
    
    var slot = slots[slot_index]
    if slot.empty():
        return false
    
    slot.quantity -= amount
    var item = slot.item
    
    if slot.quantity <= 0:
        slot.item = null
        slot.quantity = 0
    
    emit_signal("item_removed", item, slot_index)
    emit_signal("inventory_changed")
    return true

func use_item(slot_index: int, target: Node) -> bool:
    if slot_index < 0 or slot_index >= slots.size():
        return false
    
    var slot = slots[slot_index]
    if slot.empty():
        return false
    
    var item = slot.item
    item.apply_effect(target)
    
    emit_signal("item_used", item, slot_index)
    
    if item.type == ItemData.ItemType.CONSUMABLE:
        remove_item(slot_index)
    
    return true

func get_item(slot_index: int) -> ItemData:
    if slot_index < 0 or slot_index >= slots.size():
        return null
    return slots[slot_index].item

func get_quantity(slot_index: int) -> int:
    if slot_index < 0 or slot_index >= slots.size():
        return 0
    return slots[slot_index].quantity

func has_item(item_id: String, amount: int = 1) -> bool:
    var found = 0
    for slot in slots:
        if not slot.empty() and slot.item.id == item_id:
            found += slot.quantity
            if found >= amount:
                return true
    return false

func swap_items(from_index: int, to_index: int) -> bool:
    if from_index < 0 or from_index >= slots.size() or to_index < 0 or to_index >= slots.size():
        return false
    
    var from_slot = slots[from_index]
    var to_slot = slots[to_index]
    
    # If both slots have stackable items of the same type
    if from_slot.item and to_slot.item and from_slot.item.can_stack_with(to_slot.item):
        var space = to_slot.item.max_stack_size - to_slot.quantity
        var transfer_amount = min(from_slot.quantity, space)
        
        if transfer_amount > 0:
            to_slot.quantity += transfer_amount
            from_slot.quantity -= transfer_amount
            
            if from_slot.quantity <= 0:
                from_slot.item = null
                from_slot.quantity = 0
            
            emit_signal("inventory_changed")
            return true
    
    # Regular swap
    var temp_item = from_slot.item
    var temp_quantity = from_slot.quantity
    
    from_slot.item = to_slot.item
    from_slot.quantity = to_slot.quantity
    
    to_slot.item = temp_item
    to_slot.quantity = temp_quantity
    
    emit_signal("inventory_changed")
    return true 