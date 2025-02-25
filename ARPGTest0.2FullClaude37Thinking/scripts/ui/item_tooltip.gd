extends Control
class_name ItemTooltip

@onready var item_name_label = $VBoxContainer/ItemNameLabel
@onready var item_type_label = $VBoxContainer/ItemTypeLabel
@onready var item_description_label = $VBoxContainer/DescriptionLabel
@onready var item_stats_label = $VBoxContainer/StatsLabel

var item_data = null

func _ready():
	# Set the size to match content
	set_tooltip_size()

func set_item(new_item_data):
	item_data = new_item_data
	
	# Update the tooltip content
	item_name_label.text = item_data.item_name
	item_description_label.text = item_data.description
	
	# Set item type label
	var type_text = "Item"
	if item_data is WeaponData:
		type_text = "Weapon"
	elif item_data is ArmorData:
		type_text = "Armor"
	elif item_data is AccessoryData:
		type_text = "Accessory"
	elif item_data is ConsumableItem:
		type_text = "Consumable"
	
	item_type_label.text = type_text
	
	# Set item stats based on type
	var stats_text = ""
	
	if item_data is WeaponData:
		stats_text += "Damage: " + str(item_data.damage) + "\n"
		stats_text += "Attack Speed: " + str(item_data.attack_speed)
	elif item_data is ArmorData:
		stats_text += "Defense: " + str(item_data.defense)
	elif item_data is PotionData:
		stats_text += "Healing: " + str(item_data.heal_amount)
	
	item_stats_label.text = stats_text
	
	# Apply rarity color to item name
	match item_data.rarity:
		"common":
			item_name_label.add_theme_color_override("font_color", Color(1, 1, 1))  # White
		"uncommon":
			item_name_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Green
		"rare":
			item_name_label.add_theme_color_override("font_color", Color(0, 0.5, 1))  # Blue
		"epic":
			item_name_label.add_theme_color_override("font_color", Color(0.5, 0, 1))  # Purple
		"legendary":
			item_name_label.add_theme_color_override("font_color", Color(1, 0.5, 0))  # Orange
	
	set_tooltip_size()

func set_tooltip_size():
	# Wait for the next frame to properly calculate size
	await get_tree().process_frame
	
	# Set minimum size based on content
	var min_width = max(200, item_name_label.size.x + 20)
	var min_height = $VBoxContainer.size.y + 20
	size = Vector2(min_width, min_height) 