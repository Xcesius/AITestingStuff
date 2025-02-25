class_name InventorySlot
extends Button

@onready var item_icon: TextureRect = $ItemIcon
@onready var quantity_label: Label = $QuantityLabel

var slot_index: int = 0

func _ready() -> void:
    item_icon.hide()
    quantity_label.hide()

func set_item(item: ItemData) -> void:
    if item and item.icon:
        item_icon.texture = item.icon
        item_icon.show()
    else:
        item_icon.hide()
        quantity_label.hide()

func set_quantity(amount: int) -> void:
    if amount > 1:
        quantity_label.text = str(amount)
        quantity_label.show()
    else:
        quantity_label.hide()

func get_drag_data(_position: Vector2) -> Variant:
    if not item_icon.visible:
        return null
    
    var preview = TextureRect.new()
    preview.texture = item_icon.texture
    preview.expand_mode = TextureRect.EXPAND_KEEP_ASPECT
    preview.custom_minimum_size = Vector2(32, 32)
    
    set_drag_preview(preview)
    return {"source_slot": slot_index}

func can_drop_data(_position: Vector2, data: Variant) -> bool:
    return data is Dictionary and data.has("source_slot")

func drop_data(_position: Vector2, data: Variant) -> void:
    if not data is Dictionary or not data.has("source_slot"):
        return
    
    var source_slot = data["source_slot"]
    if source_slot == slot_index:
        return
    
    # Swap items is handled by the inventory system
    var inventory = get_tree().get_first_node_in_group("player").get_node("Inventory")
    if inventory:
        inventory.swap_items(source_slot, slot_index) 