extends TextureRect
class_name EquipmentSlot

@onready var item_texture = $ItemTexture
@onready var highlight = $Highlight
@onready var slot_type_icon = $SlotTypeIcon

var slot_type: String = ""
var item_data = null

signal slot_pressed(slot_type)

func _ready():
	# Initialize the slot
	clear_item()
	highlight.visible = false
	
	# Set the slot appearance based on type
	setup_slot_type()

func setup_slot_type():
	match slot_type:
		"weapon":
			slot_type_icon.texture = load("res://assets/ui/weapon_slot_icon.png")
		"armor":
			slot_type_icon.texture = load("res://assets/ui/armor_slot_icon.png")
		"helmet":
			slot_type_icon.texture = load("res://assets/ui/helmet_slot_icon.png")
		"accessory":
			slot_type_icon.texture = load("res://assets/ui/accessory_slot_icon.png")
		_:
			slot_type_icon.texture = null

func set_slot_type(type: String):
	slot_type = type
	setup_slot_type()

func set_item(new_item_data):
	item_data = new_item_data
	item_texture.texture = load(item_data.icon_path)
	item_texture.visible = true
	slot_type_icon.visible = false

func clear_item():
	item_data = null
	item_texture.texture = null
	item_texture.visible = false
	slot_type_icon.visible = true

func set_highlighted(is_highlighted: bool):
	highlight.visible = is_highlighted

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			emit_signal("slot_pressed", slot_type)
			set_highlighted(true)

func _make_custom_tooltip(for_text):
	if item_data:
		var tooltip = load("res://scenes/ui/item_tooltip.tscn").instantiate()
		tooltip.set_item(item_data)
		return tooltip
	return null 