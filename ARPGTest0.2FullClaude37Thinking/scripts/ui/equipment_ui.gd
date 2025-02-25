extends Control
class_name EquipmentUI

@onready var weapon_slot = $EquipmentSlots/WeaponSlot
@onready var armor_slot = $EquipmentSlots/ArmorSlot
@onready var helmet_slot = $EquipmentSlots/HelmetSlot
@onready var accessory_slot = $EquipmentSlots/AccessorySlot
@onready var item_info_panel = $ItemInfoPanel
@onready var item_name_label = $ItemInfoPanel/ItemNameLabel
@onready var item_description_label = $ItemInfoPanel/ItemDescriptionLabel
@onready var item_stats_label = $ItemInfoPanel/ItemStatsLabel
@onready var unequip_button = $ItemInfoPanel/UnequipButton

var equipment_system: EquipmentSystem
var inventory: Inventory
var selected_slot: String = ""

func initialize(player_equipment: EquipmentSystem, player_inventory: Inventory):
	equipment_system = player_equipment
	inventory = player_inventory
	
	# Connect signals
	equipment_system.connect("item_equipped", Callable(self, "_on_item_equipped"))
	equipment_system.connect("item_unequipped", Callable(self, "_on_item_unequipped"))
	
	# Initialize slots
	refresh_equipment_display()
	hide_item_info()

func _on_item_equipped(slot_name: String, item_data):
	refresh_equipment_display()

func _on_item_unequipped(slot_name: String):
	refresh_equipment_display()
	
	if selected_slot == slot_name:
		hide_item_info()

func refresh_equipment_display():
	# Update weapon slot
	var weapon = equipment_system.get_equipped_item("weapon")
	if weapon:
		weapon_slot.set_item(weapon)
	else:
		weapon_slot.clear_item()
	
	# Update armor slot
	var armor = equipment_system.get_equipped_item("armor")
	if armor:
		armor_slot.set_item(armor)
	else:
		armor_slot.clear_item()
	
	# Update helmet slot
	var helmet = equipment_system.get_equipped_item("helmet")
	if helmet:
		helmet_slot.set_item(helmet)
	else:
		helmet_slot.clear_item()
	
	# Update accessory slot
	var accessory = equipment_system.get_equipped_item("accessory")
	if accessory:
		accessory_slot.set_item(accessory)
	else:
		accessory_slot.clear_item()

func _on_equipment_slot_clicked(slot_name: String):
	selected_slot = slot_name
	var item = equipment_system.get_equipped_item(slot_name)
	
	if item:
		show_item_info(slot_name, item)
	else:
		hide_item_info()

func show_item_info(slot_name: String, item):
	if not item:
		hide_item_info()
		return
	
	item_info_panel.visible = true
	item_name_label.text = item.item_name
	item_description_label.text = item.description
	
	# Display item stats based on type
	var stats_text = ""
	
	if item is WeaponData:
		stats_text += "Damage: " + str(item.damage) + "\n"
		stats_text += "Attack Speed: " + str(item.attack_speed)
	elif item is ArmorData:
		stats_text += "Defense: " + str(item.defense)
	elif item is AccessoryData:
		stats_text += item.get_stats_text()
	
	item_stats_label.text = stats_text
	unequip_button.visible = true

func hide_item_info():
	item_info_panel.visible = false
	selected_slot = ""

func _on_unequip_button_pressed():
	if selected_slot != "":
		equipment_system.unequip_item(selected_slot)
		hide_item_info()

func _input(event):
	if event.is_action_pressed("equipment_toggle"):
		toggle_visibility()

func toggle_visibility():
	visible = !visible
	get_tree().paused = visible

# Connect these to equipment slots in the scene
func _on_weapon_slot_pressed():
	_on_equipment_slot_clicked("weapon")

func _on_armor_slot_pressed():
	_on_equipment_slot_clicked("armor")

func _on_helmet_slot_pressed():
	_on_equipment_slot_clicked("helmet")

func _on_accessory_slot_pressed():
	_on_equipment_slot_clicked("accessory") 