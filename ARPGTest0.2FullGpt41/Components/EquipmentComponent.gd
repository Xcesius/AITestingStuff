# EquipmentComponent.gd
class_name EquipmentComponent
extends Node

var equipped_items: Dictionary = {} # slot_name -> item_data
signal equipped(item, slot)
signal unequipped(item, slot)

func equip(item, slot: String) -> void:
    equipped_items[slot] = item
    # [EQUIPMENT_LOGIC]
    emit_signal("equipped", item, slot)

func unequip(slot: String) -> void:
    var item = equipped_items.get(slot, null)
    if item:
        equipped_items.erase(slot)
        # [UNEQUIP_LOGIC]
        emit_signal("unequipped", item, slot) 