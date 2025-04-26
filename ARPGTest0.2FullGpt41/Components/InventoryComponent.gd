# InventoryComponent.gd
extends Node

@export var max_slots: int = 16
var items: Array = []

signal item_added(item)
signal item_removed(item)

func pickup_item(item_data):
    if items.size() < max_slots:
        items.append(item_data)
        emit_signal("item_added", item_data)
        return true
    return false

func remove_item(item_data):
    if item_data in items:
        items.erase(item_data)
        emit_signal("item_removed", item_data)
        return true
    return false

func get_items():
    return items 