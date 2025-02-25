extends TextureRect
class_name InventorySlot

@onready var item_texture = $ItemTexture
@onready var quantity_label = $QuantityLabel
@onready var highlight = $Highlight

var slot_index: int = -1
var item_data = null

signal slot_clicked(slot_index)

func _ready():
	# Initialize the slot
	clear_item()
	highlight.visible = false

func set_slot_index(index: int):
	slot_index = index

func set_item(new_item_data):
	item_data = new_item_data
	item_texture.texture = load(item_data.icon_path)
	item_texture.visible = true
	
	# Show quantity for stackable items
	if item_data.is_stackable and item_data.quantity > 1:
		quantity_label.text = str(item_data.quantity)
		quantity_label.visible = true
	else:
		quantity_label.visible = false

func clear_item():
	item_data = null
	item_texture.texture = null
	item_texture.visible = false
	quantity_label.visible = false

func set_highlighted(is_highlighted: bool):
	highlight.visible = is_highlighted

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			emit_signal("slot_clicked", slot_index)
			set_highlighted(true)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if item_data and item_data is ConsumableItem:
				# Quick use item with right click
				emit_signal("slot_right_clicked", slot_index)

func _make_custom_tooltip(for_text):
	if item_data:
		var tooltip = load("res://scenes/ui/item_tooltip.tscn").instantiate()
		tooltip.set_item(item_data)
		return tooltip
	return null 