extends Control
class_name OptionsPanel

@onready var master_volume_slider = $TabContainer/Audio/VBoxContainer/MasterVolumeHBox/MasterVolumeSlider
@onready var music_volume_slider = $TabContainer/Audio/VBoxContainer/MusicVolumeHBox/MusicVolumeSlider
@onready var sfx_volume_slider = $TabContainer/Audio/VBoxContainer/SFXVolumeHBox/SFXVolumeSlider
@onready var fullscreen_check = $TabContainer/Video/VBoxContainer/FullscreenHBox/FullscreenCheck
@onready var vsync_check = $TabContainer/Video/VBoxContainer/VSyncHBox/VSyncCheck
@onready var resolution_option = $TabContainer/Video/VBoxContainer/ResolutionHBox/ResolutionOption
@onready var camera_sensitivity_slider = $TabContainer/Controls/VBoxContainer/SensitivityHBox/SensitivitySlider
@onready var back_button = $BackButton
@onready var apply_button = $ApplyButton

# Config file for saving settings
var config = ConfigFile.new()
var config_path = "user://settings.cfg"

# Available resolutions
var resolutions = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

func _ready():
	# Connect signals
	back_button.connect("pressed", Callable(self, "_on_back_button_pressed"))
	apply_button.connect("pressed", Callable(self, "_on_apply_button_pressed"))
	
	# Setup resolution options
	for res in resolutions:
		resolution_option.add_item(str(res.x) + "x" + str(res.y))
	
	# Load settings
	load_settings()

func load_settings():
	var error = config.load(config_path)
	
	if error != OK:
		# If no settings file exists, create default settings
		create_default_settings()
		return
	
	# Audio settings
	master_volume_slider.value = config.get_value("audio", "master_volume", 80)
	music_volume_slider.value = config.get_value("audio", "music_volume", 70)
	sfx_volume_slider.value = config.get_value("audio", "sfx_volume", 80)
	
	# Video settings
	fullscreen_check.button_pressed = config.get_value("video", "fullscreen", false)
	vsync_check.button_pressed = config.get_value("video", "vsync", true)
	
	var saved_resolution = config.get_value("video", "resolution", Vector2i(1280, 720))
	
	# Find resolution in our list
	for i in range(resolutions.size()):
		if resolutions[i] == saved_resolution:
			resolution_option.select(i)
			break
	
	# Controls
	camera_sensitivity_slider.value = config.get_value("controls", "camera_sensitivity", 0.5)
	
	# Apply loaded settings
	apply_settings()

func create_default_settings():
	# Audio
	config.set_value("audio", "master_volume", 80)
	config.set_value("audio", "music_volume", 70)
	config.set_value("audio", "sfx_volume", 80)
	
	# Video
	config.set_value("video", "fullscreen", false)
	config.set_value("video", "vsync", true)
	config.set_value("video", "resolution", Vector2i(1280, 720))
	
	# Controls
	config.set_value("controls", "camera_sensitivity", 0.5)
	
	# Save to file
	config.save(config_path)
	
	# Load into UI
	load_settings()

func save_settings():
	# Audio
	config.set_value("audio", "master_volume", master_volume_slider.value)
	config.set_value("audio", "music_volume", music_volume_slider.value)
	config.set_value("audio", "sfx_volume", sfx_volume_slider.value)
	
	# Video
	config.set_value("video", "fullscreen", fullscreen_check.button_pressed)
	config.set_value("video", "vsync", vsync_check.button_pressed)
	
	var selected_res = resolutions[resolution_option.selected]
	config.set_value("video", "resolution", selected_res)
	
	# Controls
	config.set_value("controls", "camera_sensitivity", camera_sensitivity_slider.value)
	
	# Save to file
	config.save(config_path)

func apply_settings():
	# Audio
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"), 
		linear_to_db(master_volume_slider.value / 100.0)
	)
	
	# Set bus volumes for Music and SFX if they exist
	var music_bus_idx = AudioServer.get_bus_index("Music")
	if music_bus_idx >= 0:
		AudioServer.set_bus_volume_db(
			music_bus_idx,
			linear_to_db(music_volume_slider.value / 100.0)
		)
	
	var sfx_bus_idx = AudioServer.get_bus_index("SFX")
	if sfx_bus_idx >= 0:
		AudioServer.set_bus_volume_db(
			sfx_bus_idx,
			linear_to_db(sfx_volume_slider.value / 100.0)
		)
	
	# Video
	get_window().mode = Window.MODE_FULLSCREEN if fullscreen_check.button_pressed else Window.MODE_WINDOWED
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_check.button_pressed else DisplayServer.VSYNC_DISABLED)
	
	var selected_res = resolutions[resolution_option.selected]
	get_window().size = selected_res
	
	# Center window
	var screen_size = DisplayServer.screen_get_size()
	var window_position = (screen_size - selected_res) / 2
	get_window().position = window_position
	
	# Controls - emit signal to update sensitivity
	EventBus.emit_signal("camera_sensitivity_changed", camera_sensitivity_slider.value)

func _on_back_button_pressed():
	# Hide options panel without saving
	visible = false

func _on_apply_button_pressed():
	# Save and apply settings
	save_settings()
	apply_settings() 