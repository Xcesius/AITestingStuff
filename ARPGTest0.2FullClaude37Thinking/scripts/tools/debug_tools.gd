extends Control
class_name DebugTools

@onready var tab_container = $TabContainer
@onready var close_button = $CloseButton

func _ready():
	# Connect close button
	close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))
	
	# Hide on start
	visible = false

func _input(event):
	if event.is_action_pressed("debug_tools_toggle"):
		toggle_visibility()

func toggle_visibility():
	visible = !visible
	
	if visible:
		# Pause game while tools are open
		get_tree().paused = true
		
		# Set input as handled to prevent other systems from receiving this input
		get_viewport().set_input_as_handled()
	else:
		# Resume game when closed
		get_tree().paused = false

func _on_close_button_pressed():
	toggle_visibility()

# Function to open a specific tool tab by name
func open_tool(tool_name: String):
	for i in range(tab_container.get_tab_count()):
		if tab_container.get_tab_title(i).to_lower() == tool_name.to_lower():
			tab_container.current_tab = i
			toggle_visibility()
			return
	
	print("Debug tool not found: " + tool_name) 