extends CanvasLayer
class_name DialogueManager

signal dialogue_started(npc_id)
signal dialogue_option_selected(option_index)
signal dialogue_ended(npc_id)

@onready var dialogue_panel = $DialoguePanel
@onready var npc_name_label = $DialoguePanel/MarginContainer/VBoxContainer/NPCNameLabel
@onready var dialogue_text = $DialoguePanel/MarginContainer/VBoxContainer/DialogueText
@onready var options_container = $DialoguePanel/MarginContainer/VBoxContainer/OptionsContainer
@onready var continue_button = $DialoguePanel/MarginContainer/VBoxContainer/ContinueButton
@onready var portrait_texture = $DialoguePanel/MarginContainer/HBoxContainer/PortraitTexture

# Current dialogue state
var current_dialogue: Array = []
var current_dialogue_index: int = 0
var current_npc = null
var typing_speed: float = 0.03
var is_typing: bool = false
var skip_typing: bool = false
var dialogue_history: Array = []

# Option button scene
var option_button_scene = preload("res://scenes/ui/dialogue_option_button.tscn")

func _ready():
	# Connect signals
	continue_button.connect("pressed", Callable(self, "_on_continue_button_pressed"))
	
	# Hide panel by default
	dialogue_panel.visible = false

func _input(event):
	if dialogue_panel.visible and event.is_action_pressed("ui_accept"):
		if is_typing:
			# Skip typing animation
			skip_typing = true
		else:
			_on_continue_button_pressed()

func start_dialogue(dialogue_data: Array, npc):
	# Store reference to NPC
	current_npc = npc
	
	# Setup dialogue data
	current_dialogue = dialogue_data
	current_dialogue_index = 0
	dialogue_history.clear()
	
	# Show dialogue panel
	dialogue_panel.visible = true
	
	# Display first dialogue entry
	display_dialogue_entry()
	
	# Emit signal
	dialogue_started.emit(npc.npc_id)
	
	# Pause game while in dialogue
	get_tree().paused = true

func display_dialogue_entry():
	if current_dialogue_index >= current_dialogue.size():
		end_dialogue()
		return
	
	# Get current dialogue entry
	var entry = current_dialogue[current_dialogue_index]
	
	# Set NPC name
	if entry.has("speaker"):
		npc_name_label.text = entry.speaker
	else:
		npc_name_label.text = current_npc.npc_name
	
	# Set dialogue text
	dialogue_text.text = ""
	
	# Set portrait if available
	if entry.has("portrait") and entry.portrait != "":
		var portrait = load(entry.portrait)
		if portrait:
			portrait_texture.texture = portrait
			portrait_texture.visible = true
	else:
		portrait_texture.visible = false
	
	# Clear options
	for child in options_container.get_children():
		child.queue_free()
	
	# Show options or continue button
	if entry.has("options") and entry.options.size() > 0:
		continue_button.visible = false
		
		# Start typing animation
		type_dialogue_text(entry.text)
		
		# Only show options after typing is done
		await get_tree().create_timer(0.5).timeout
		
		# Create option buttons
		for i in range(entry.options.size()):
			var option = entry.options[i]
			var button = option_button_scene.instantiate()
			options_container.add_child(button)
			
			button.text = option.text
			button.option_index = i
			button.connect("option_selected", Callable(self, "_on_option_selected"))
	else:
		options_container.visible = false
		continue_button.visible = true
		
		# Start typing animation
		type_dialogue_text(entry.text)
	
	# Add to history
	dialogue_history.append(entry)

func type_dialogue_text(text: String):
	is_typing = true
	skip_typing = false
	
	# Disable interactions while typing
	continue_button.disabled = true
	options_container.visible = false
	
	for i in range(text.length()):
		if skip_typing:
			dialogue_text.text = text
			break
			
		dialogue_text.text = text.substr(0, i+1)
		
		# Wait for typing speed
		var timer = get_tree().create_timer(typing_speed)
		await timer.timeout
	
	# Enable interactions after typing
	continue_button.disabled = false
	options_container.visible = true
	is_typing = false

func _on_continue_button_pressed():
	if is_typing:
		skip_typing = true
		return
	
	var entry = current_dialogue[current_dialogue_index]
	
	# Handle "next" property to jump to specific entries
	if entry.has("next") and entry.next is int:
		current_dialogue_index = entry.next
	else:
		# Move to next dialogue entry
		current_dialogue_index += 1
	
	# Display next entry
	display_dialogue_entry()

func _on_option_selected(option_index):
	var entry = current_dialogue[current_dialogue_index]
	var option = entry.options[option_index]
	
	# Emit signal
	dialogue_option_selected.emit(option_index)
	
	# Check for custom actions
	if option.has("action"):
		execute_action(option.action)
	
	# Jump to next dialogue entry
	if option.has("next") and option.next is int:
		current_dialogue_index = option.next
	else:
		current_dialogue_index += 1
	
	# Display next entry
	display_dialogue_entry()

func execute_action(action: String):
	match action:
		"start_quest":
			if current_npc.is_quest_giver:
				var quest_id = current_npc.get_first_available_quest()
				if quest_id != "":
					var quest_manager = get_node_or_null("/root/QuestManager")
					if quest_manager:
						quest_manager.start_quest(quest_id)
						current_npc.update_quest_status()
		
		"complete_quest":
			if current_npc.is_quest_giver:
				var quest_id = current_npc.get_active_quest()
				if quest_id != "":
					current_npc.complete_active_quest(quest_id)
		
		"open_shop":
			if current_npc.is_vendor:
				end_dialogue()
				
				var vendor_UI = get_node_or_null("/root/VendorUI")
				if vendor_UI:
					vendor_UI.show_vendor_items(current_npc, current_npc.vendor_items)
		
		_:
			# Call custom action on NPC if it exists
			if current_npc.has_method(action):
				current_npc.call(action)

func end_dialogue():
	# Hide dialogue panel
	dialogue_panel.visible = false
	
	# Clear state
	if current_npc:
		current_npc.end_interaction()
		
	# Emit signal
	if current_npc:
		dialogue_ended.emit(current_npc.npc_id)
	
	current_npc = null
	
	# Unpause game
	get_tree().paused = false 