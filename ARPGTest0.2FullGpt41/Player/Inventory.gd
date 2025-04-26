# Inventory.gd
extends Node

var items = []
const MAX_SLOTS = [INVENTORY_SLOTS_COUNT]

func pickup_item(item_data):
    if items.size() < MAX_SLOTS:
        items.append(item_data)
        # [ITEM_PICKUP_LOGIC]
        return true
    return false

func remove_item(item_data):
    if item_data in items:
        items.erase(item_data)
        # [ITEM_REMOVE_LOGIC]
        return true
    return false

func get_items():
    return items 