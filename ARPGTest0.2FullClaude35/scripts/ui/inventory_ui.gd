class_name InventoryUI
extends Control

@onready var grid_container: GridContainer = $GridContainer
@onready var item_info_panel: Panel = $ItemInfoPanel
@onready var item_name_label: Label = $ItemInfoPanel/ItemName
@onready var item_description_label: Label = $ItemInfoPanel/ItemDescription
@onready var use_button: Button = $ItemInfoPanel/UseButton

var inventory: Inventory
var selected_slot: int = -1
var slot_scene = preload("res://scenes/ui/inventory_slot.tscn")

func _ready() -> void:
    item_info_panel.hide()
    
    # Wait a frame to find player and inventory
    await get_tree().process_frame
    var player = get_tree().get_first_node_in_group("player")
    if player:
        inventory = player.get_node("Inventory")
        if inventory:
            inventory.item_added.connect(_on_inventory_changed)
            inventory.item_removed.connect(_on_inventory_changed)
            inventory.inventory_changed.connect(_on_inventory_changed)
            _setup_inventory_slots()

func _setup_inventory_slots() -> void:
    # Clear existing slots
    for child in grid_container.get_children():
        child.queue_free()
    
    # Create new slots
    for i in range(inventory.size):
        var slot = slot_scene.instantiate()
        grid_container.add_child(slot)
        slot.slot_index = i
        slot.pressed.connect(_on_slot_pressed.bind(i))
        _update_slot(slot, i)

func _update_slot(slot: InventorySlot, index: int) -> void:
    var item = inventory.get_item(index)
    var quantity = inventory.get_quantity(index)
    
    slot.set_item(item)
    slot.set_quantity(quantity)

func _on_inventory_changed(_item = null, _slot = null) -> void:
    for i in range(inventory.size):
        var slot = grid_container.get_child(i)
        _update_slot(slot, i)

func _on_slot_pressed(index: int) -> void:
    selected_slot = index
    var item = inventory.get_item(index)
    
    if item:
        item_name_label.text = item.name
        item_description_label.text = item.description
        use_button.visible = item.type == ItemData.ItemType.CONSUMABLE
        item_info_panel.show()
    else:
        item_info_panel.hide()

func _on_use_button_pressed() -> void:
    if selected_slot >= 0:
        var player = get_tree().get_first_node_in_group("player")
        if player and inventory.use_item(selected_slot, player):
            if not inventory.get_item(selected_slot):
                item_info_panel.hide()
                selected_slot = -1 