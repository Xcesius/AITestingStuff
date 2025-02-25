extends Control
class_name InventoryUI

@onready var item_grid = $ItemGrid
@onready var item_info_panel = $ItemInfoPanel
@onready var item_name_label = $ItemInfoPanel/ItemNameLabel
@onready var item_description_label = $ItemInfoPanel/ItemDescriptionLabel
@onready var item_stats_label = $ItemInfoPanel/ItemStatsLabel
@onready var use_button = $ItemInfoPanel/UseButton
@onready var equip_button = $ItemInfoPanel/EquipButton
@onready var drop_button = $ItemInfoPanel/DropButton

var inventory: Inventory
var inventory_slot_scene = preload("res://scenes/ui/inventory_slot.tscn")
var selected_slot_index: int = -1
var equipment_system: EquipmentSystem

# Connect to player inventory
func initialize(player_inventory: Inventory, player_equipment: EquipmentSystem):
	inventory = player_inventory
	equipment_system = player_equipment
	
	# Connect signals
	inventory.connect("item_added", Callable(self, "_on_item_added"))
	inventory.connect("item_removed", Callable(self, "_on_item_removed"))
	inventory.connect("item_updated", Callable(self, "_on_item_updated"))
	
	# Setup UI
	refresh_inventory()
	hide_item_info()

func _on_item_added(item_index: int):
	refresh_inventory()

func _on_item_removed(item_index: int):
	refresh_inventory()
	
	if selected_slot_index == item_index:
		hide_item_info()
		selected_slot_index = -1

func _on_item_updated(item_index: int):
	refresh_inventory()
	
	if selected_slot_index == item_index:
		show_item_info(item_index)

func refresh_inventory():
	# Clear existing slots
	for child in item_grid.get_children():
		child.queue_free()
	
	# Create new slots based on inventory
	for i in range(inventory.get_size()):
		var slot = inventory_slot_scene.instantiate()
		item_grid.add_child(slot)
		
		var item_data = inventory.get_item(i)
		slot.set_slot_index(i)
		
		if item_data:
			slot.set_item(item_data)
		else:
			slot.clear_item()
			
		# Connect slot signals
		slot.connect("slot_clicked", Callable(self, "_on_slot_clicked"))

func _on_slot_clicked(slot_index: int):
	selected_slot_index = slot_index
	var item = inventory.get_item(slot_index)
	
	if item:
		show_item_info(slot_index)
	else:
		hide_item_info()

func show_item_info(slot_index: int):
	var item = inventory.get_item(slot_index)
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
	elif item is PotionData:
		stats_text += "Healing: " + str(item.heal_amount)
	
	item_stats_label.text = stats_text
	
	# Configure buttons based on item type
	use_button.visible = item is ConsumableItem
	equip_button.visible = item is EquipmentData
	drop_button.visible = true
	
	# Update equip button text if item is already equipped
	if item is EquipmentData and equipment_system:
		var is_equipped = equipment_system.is_item_equipped(item)
		equip_button.text = "Unequip" if is_equipped else "Equip"

func hide_item_info():
	item_info_panel.visible = false
	selected_slot_index = -1

func _on_use_button_pressed():
	if selected_slot_index >= 0:
		var item = inventory.get_item(selected_slot_index)
		if item is ConsumableItem:
			# Implement use item logic
			inventory.use_item(selected_slot_index)

func _on_equip_button_pressed():
	if selected_slot_index >= 0:
		var item = inventory.get_item(selected_slot_index)
		if item is EquipmentData:
			if equipment_system.is_item_equipped(item):
				equipment_system.unequip_item(item.equipment_slot)
			else:
				equipment_system.equip_item(selected_slot_index, item)
			show_item_info(selected_slot_index) # Refresh info panel

func _on_drop_button_pressed():
	if selected_slot_index >= 0:
		inventory.drop_item(selected_slot_index)
		hide_item_info()

func _input(event):
	if event.is_action_pressed("inventory_toggle"):
		toggle_visibility()

func toggle_visibility():
	visible = !visible
	get_tree().paused = visible 