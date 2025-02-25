extends PanelContainer
class_name SaveSlot

signal slot_selected(slot_number)

@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var date_label = $MarginContainer/VBoxContainer/DateLabel
@onready var details_label = $MarginContainer/VBoxContainer/DetailsLabel

var slot_number: int = 0
var is_empty: bool = false
var selected: bool = false:
	set(value):
		selected = value
		update_appearance()

func _ready():
	# Connect signals
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Initial appearance
	update_appearance()

func set_details(title: String, date: String, details: String):
	title_label.text = title
	date_label.text = date
	details_label.text = details
	
	# Update visibility based on if slot is empty
	date_label.visible = !is_empty
	details_label.visible = !is_empty

func update_appearance():
	if selected:
		# Selected appearance
		add_theme_color_override("panel_bg_color", Color(0.2, 0.4, 0.8, 0.7))
	else:
		# Normal appearance
		remove_theme_color_override("panel_bg_color")

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("slot_selected", slot_number)

func _on_mouse_entered():
	if !selected:
		# Hover appearance
		add_theme_color_override("panel_bg_color", Color(0.2, 0.2, 0.3, 0.5))

func _on_mouse_exited():
	if !selected:
		# Normal appearance
		remove_theme_color_override("panel_bg_color") 