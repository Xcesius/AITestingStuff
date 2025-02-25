extends Control
class_name PauseMenu

@onready var resume_button = $VBoxContainer/ResumeButton
@onready var options_button = $VBoxContainer/OptionsButton
@onready var main_menu_button = $VBoxContainer/MainMenuButton
@onready var exit_button = $VBoxContainer/ExitButton
@onready var options_panel = $OptionsPanel
@onready var confirmation_dialog = $ConfirmationDialog

var is_paused: bool = false

func _ready():
	# Hide the pause menu initially
	visible = false
	
	# Connect button signals
	resume_button.connect("pressed", Callable(self, "_on_resume_button_pressed"))
	options_button.connect("pressed", Callable(self, "_on_options_button_pressed"))
	main_menu_button.connect("pressed", Callable(self, "_on_main_menu_button_pressed"))
	exit_button.connect("pressed", Callable(self, "_on_exit_button_pressed"))
	
	# Hide panels
	options_panel.visible = false
	confirmation_dialog.visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if options_panel.visible:
			options_panel.visible = false
		elif confirmation_dialog.visible:
			confirmation_dialog.visible = false
		else:
			toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	visible = is_paused
	
	if is_paused:
		# Capture input when paused
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		# Return to game input mode
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_button_pressed():
	toggle_pause()

func _on_options_button_pressed():
	options_panel.visible = true

func _on_options_back_button_pressed():
	options_panel.visible = false

func _on_main_menu_button_pressed():
	# Show confirmation dialog
	confirmation_dialog.dialog_text = "Return to Main Menu? Any unsaved progress will be lost."
	confirmation_dialog.visible = true
	
func _on_exit_button_pressed():
	# Show confirmation dialog
	confirmation_dialog.dialog_text = "Exit Game? Any unsaved progress will be lost."
	confirmation_dialog.visible = true

func _on_confirmation_dialog_confirmed():
	# Check which action was confirmed
	if confirmation_dialog.dialog_text.begins_with("Return to Main Menu"):
		# Unpause and return to main menu
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	elif confirmation_dialog.dialog_text.begins_with("Exit Game"):
		# Quit the game
		get_tree().quit()

func _on_confirmation_dialog_canceled():
	confirmation_dialog.visible = false 