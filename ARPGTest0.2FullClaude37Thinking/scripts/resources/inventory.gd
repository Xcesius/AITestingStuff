class_name Inventory
extends Resource

signal item_added(item_data, slot)
signal item_removed(item_data, slot)
signal item_used(item_data, slot)
signal inventory_changed

class InventorySlot:
    var item_data: ItemData
    var quantity: int
    
    func _init(p_item_data: ItemData = null, p_quantity: int = 0) -> void:
        item_data = p_item_data
        quantity = p_quantity
    
    func can_stack_with(other_item: ItemData) -> bool:
        if item_data == null or other_item == null:
            return false
        
        return item_data.id == other_item.id and quantity < item_data.stack_size

@export var slots_count: int = 20
var slots: Array[InventorySlot] = []

func _init(p_slots_count: int = 20) -> void:
    slots_count = p_slots_count
    _initialize_slots()

func _initialize_slots() -> void:
    slots.clear()
    for i in range(slots_count):
        slots.append(InventorySlot.new())

func add_item(item_data: ItemData, quantity: int = 1) -> bool:
    if item_data == null:
        return false
    
    # First try to stack with existing items
    if item_data.stack_size > 1:
        for i in range(slots.size()):
            var slot = slots[i]
            if slot.item_data and slot.can_stack_with(item_data) and slot.quantity < item_data.stack_size:
                var available_space = item_data.stack_size - slot.quantity
                var amount_to_add = min(quantity, available_space)
                
                slot.quantity += amount_to_add
                quantity -= amount_to_add
                
                emit_signal("item_added", item_data, i)
                emit_signal("inventory_changed")
                
                if quantity <= 0:
                    return true
    
    # If we still have items to add, find empty slots
    for i in range(slots.size()):
        var slot = slots[i]
        if slot.item_data == null:
            var amount_to_add = min(quantity, item_data.stack_size)
            slot.item_data = item_data
            slot.quantity = amount_to_add
            quantity -= amount_to_add
            
            emit_signal("item_added", item_data, i)
            emit_signal("inventory_changed")
            
            if quantity <= 0:
                return true
    
    # If we get here, we couldn't add all items
    return quantity <= 0

func remove_item(slot_index: int, quantity: int = 1) -> bool:
    if slot_index < 0 or slot_index >= slots.size():
        return false
    
    var slot = slots[slot_index]
    if slot.item_data == null or slot.quantity < quantity:
        return false
    
    var item_data = slot.item_data
    slot.quantity -= quantity
    
    if slot.quantity <= 0:
        slot.item_data = null
        slot.quantity = 0
    
    emit_signal("item_removed", item_data, slot_index)
    emit_signal("inventory_changed")
    
    return true

func get_item(slot_index: int) -> InventorySlot:
    if slot_index < 0 or slot_index >= slots.size():
        return null
    
    return slots[slot_index]

func use_item(slot_index: int, target = null) -> bool:
    if slot_index < 0 or slot_index >= slots.size():
        return false
    
    var slot = slots[slot_index]
    if slot.item_data == null or slot.quantity <= 0:
        return false
    
    var used = false
    if target:
        used = slot.item_data.use(target)
    else:
        used = slot.item_data.use(null)
    
    if used:
        emit_signal("item_used", slot.item_data, slot_index)
        
        # Remove one item after use (for consumables)
        if slot.item_data.item_type == ItemData.ItemType.CONSUMABLE:
            remove_item(slot_index, 1)
        
        emit_signal("inventory_changed")
    
    return used

func has_item(item_id: String, quantity: int = 1) -> bool:
    var count = 0
    
    for slot in slots:
        if slot.item_data and slot.item_data.id == item_id:
            count += slot.quantity
            if count >= quantity:
                return true
    
    return false

func get_item_count(item_id: String) -> int:
    var count = 0
    
    for slot in slots:
        if slot.item_data and slot.item_data.id == item_id:
            count += slot.quantity
    
    return count

func clear() -> void:
    for i in range(slots.size()):
        var slot = slots[i]
        if slot.item_data != null:
            var old_item = slot.item_data
            slot.item_data = null
            slot.quantity = 0
            emit_signal("item_removed", old_item, i)
    
    emit_signal("inventory_changed") 