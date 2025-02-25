extends CanvasLayer
class_name SaveLoadMenu

signal closed

@onready var menu_container = $PanelContainer
@onready var save_slot_container = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/SaveSlotContainer
@onready var save_button = $PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer/SaveButton
@onready var load_button = $PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer/LoadButton
@onready var delete_button = $PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer/DeleteButton
@onready var close_button = $PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer/CloseButton

var save_slot_scene = preload("res://scenes/ui/save_slot.tscn")
var mode = "load" # "save" or "load"
var selected_slot = -1
var save_slots = []

func _ready():
	# Connect buttons
	save_button.connect("pressed", Callable(self, "_on_save_button_pressed"))
	load_button.connect("pressed", Callable(self, "_on_load_button_pressed"))
	delete_button.connect("pressed", Callable(self, "_on_delete_button_pressed"))
	close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))
	
	# Hide menu on start
	menu_container.visible = false
	
	# Hide by default when in-game
	visible = false

func show_menu(mode_override = null):
	if mode_override:
		mode = mode_override
	
	# Update UI based on mode
	update_mode_ui()
	
	# Refresh save slots
	refresh_save_slots()
	
	# Show menu
	menu_container.visible = true
	visible = true
	
	# Pause game while menu is open
	get_tree().paused = true

func hide_menu():
	menu_container.visible = false
	visible = false
	
	# Resume game
	get_tree().paused = false
	
	# Emit closed signal
	closed.emit()

func update_mode_ui():
	if mode == "save":
		save_button.disabled = false
		load_button.disabled = true
	else: # load mode
		save_button.disabled = true
		load_button.disabled = false

func refresh_save_slots():
	# Clear existing save slots
	for slot in save_slot_container.get_children():
		slot.queue_free()
	
	save_slots.clear()
	selected_slot = -1
	
	# Get save list from SaveSystem
	var save_system = get_node("/root/SaveSystem")
	var saves = save_system.get_save_list()
	
	# Create empty slots for all possible save slots
	for i in range(save_system.MAX_SAVE_SLOTS):
		var slot_data = null
		
		# Find matching save data if it exists
		for save in saves:
			if save.slot == i:
				slot_data = save
				break
		
		# Create UI slot
		var save_slot = save_slot_scene.instantiate()
		save_slot_container.add_child(save_slot)
		
		# Configure slot
		save_slot.slot_number = i
		
		if slot_data:
			# Existing save
			var date_str = slot_data.save_date if slot_data.save_date else "No date"
			var time_str = format_play_time(slot_data.play_time)
			var level_str = "Level " + str(slot_data.player_level)
			
			save_slot.set_details(
				"Slot " + str(i) + ": " + slot_data.player_name, 
				date_str, 
				level_str + " - " + time_str
			)
		else:
			# Empty slot
			save_slot.set_details(
				"Slot " + str(i) + ": Empty", 
				"", 
				""
			)
			save_slot.is_empty = true
		
		# Connect slot signal
		save_slot.connect("slot_selected", Callable(self, "_on_save_slot_selected"))
		
		# Store reference
		save_slots.append(save_slot)
	
	# Update button states
	update_button_states()

func _on_save_slot_selected(slot_number):
	# Update selection
	selected_slot = slot_number
	
	for i in range(save_slots.size()):
		save_slots[i].selected = (i == selected_slot)
	
	# Update button states
	update_button_states()

func update_button_states():
	# No selection
	if selected_slot == -1:
		save_button.disabled = true
		load_button.disabled = true
		delete_button.disabled = true
		return
	
	# Is empty slot
	var is_empty = save_slots[selected_slot].is_empty if selected_slot < save_slots.size() else true
	
	if mode == "save":
		save_button.disabled = false
		load_button.disabled = true
		delete_button.disabled = is_empty
	else: # load mode
		save_button.disabled = true
		load_button.disabled = is_empty
		delete_button.disabled = is_empty

func _on_save_button_pressed():
	if selected_slot == -1:
		return
	
	# Save game
	var save_system = get_node("/root/SaveSystem")
	var success = save_system.save_game(selected_slot)
	
	if success:
		# Show success message
		var notification = create_notification("Game saved successfully!")
		add_child(notification)
		
		# Refresh save slots
		refresh_save_slots()
	else:
		# Show error message
		var notification = create_notification("Failed to save game!")
		add_child(notification)

func _on_load_button_pressed():
	if selected_slot == -1:
		return
	
	# Load game
	var save_system = get_node("/root/SaveSystem")
	var success = save_system.load_game(selected_slot)
	
	if success:
		# Close menu
		hide_menu()
	else:
		# Show error message
		var notification = create_notification("Failed to load game!")
		add_child(notification)

func _on_delete_button_pressed():
	if selected_slot == -1:
		return
	
	# Show confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.title = "Confirm Delete"
	dialog.dialog_text = "Are you sure you want to delete this save? This cannot be undone."
	dialog.connect("confirmed", Callable(self, "_confirm_delete"))
	add_child(dialog)
	dialog.popup_centered()

func _confirm_delete():
	# Delete save
	var save_system = get_node("/root/SaveSystem")
	var success = save_system.delete_save(selected_slot)
	
	if success:
		# Show success message
		var notification = create_notification("Save deleted successfully!")
		add_child(notification)
		
		# Refresh save slots
		refresh_save_slots()
	else:
		# Show error message
		var notification = create_notification("Failed to delete save!")
		add_child(notification)

func _on_close_button_pressed():
	hide_menu()

func create_notification(message):
	var notification = Label.new()
	notification.text = message
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var panel = PanelContainer.new()
	panel.add_child(notification)
	panel.position = Vector2(get_viewport_rect().size.x / 2 - 100, get_viewport_rect().size.y - 100)
	panel.size = Vector2(200, 50)
	
	# Auto-destroy after delay
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.autostart = true
	timer.connect("timeout", Callable(panel, "queue_free"))
	panel.add_child(timer)
	
	return panel

func format_play_time(seconds):
	var hours = int(seconds / 3600)
	var minutes = int((seconds % 3600) / 60)
	
	if hours > 0:
		return str(hours) + "h " + str(minutes) + "m"
	else:
		return str(minutes) + "m" 