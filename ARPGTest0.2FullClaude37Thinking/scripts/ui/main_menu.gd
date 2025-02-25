extends Control
class_name MainMenu

@onready var start_button = $VBoxContainer/StartButton
@onready var options_button = $VBoxContainer/OptionsButton
@onready var exit_button = $VBoxContainer/ExitButton
@onready var options_panel = $OptionsPanel
@onready var credit_panel = $CreditsPanel
@onready var version_label = $VersionLabel
@onready var animation_player = $AnimationPlayer

const GAME_VERSION = "v0.1"

func _ready():
	# Set version label
	version_label.text = "ARPG Prototype " + GAME_VERSION
	
	# Connect button signals
	start_button.connect("pressed", Callable(self, "_on_start_button_pressed"))
	options_button.connect("pressed", Callable(self, "_on_options_button_pressed"))
	exit_button.connect("pressed", Callable(self, "_on_exit_button_pressed"))
	
	# Hide panels
	options_panel.visible = false
	credit_panel.visible = false
	
	# Play intro animation
	animation_player.play("intro")

func _on_start_button_pressed():
	# Start game animation
	animation_player.play("transition_out")
	await animation_player.animation_finished
	
	# Change to game scene
	get_tree().change_scene_to_file("res://scenes/levels/world.tscn")

func _on_options_button_pressed():
	options_panel.visible = true
	
func _on_options_back_button_pressed():
	options_panel.visible = false

func _on_exit_button_pressed():
	# Play exit animation
	animation_player.play("fade_out")
	await animation_player.animation_finished
	
	# Quit the game
	get_tree().quit()

func _on_credits_button_pressed():
	credit_panel.visible = true
	
func _on_credits_back_button_pressed():
	credit_panel.visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		# If escape is pressed and options or credits are visible, close them
		if options_panel.visible:
			options_panel.visible = false
		elif credit_panel.visible:
			credit_panel.visible = false 