extends Control
class_name MapPreviewTool

# Node references
@onready var parameter_container = $ParametersPanel/ScrollContainer/VBoxContainer
@onready var preview_container = $PreviewPanel/ViewportContainer
@onready var generate_button = $ControlsPanel/GenerateButton
@onready var save_button = $ControlsPanel/SaveButton
@onready var reset_button = $ControlsPanel/ResetButton
@onready var status_label = $ControlsPanel/StatusLabel
@onready var tiles_count_label = $StatsPanel/VBoxContainer/TilesCountLabel
@onready var rooms_count_label = $StatsPanel/VBoxContainer/RoomsCountLabel
@onready var generation_time_label = $StatsPanel/VBoxContainer/GenerationTimeLabel
@onready var viewport = $PreviewPanel/ViewportContainer/SubViewport
@onready var camera = $PreviewPanel/ViewportContainer/SubViewport/Camera2D

# Map generator reference
var map_generator = null

# Default parameters
var parameters = {
	"width": 80,
	"height": 60,
	"min_room_size": 6,
	"max_room_size": 15,
	"min_rooms": 8,
	"max_rooms": 15,
	"corridor_width": 2,
	"room_spread": 1.5,
	"enemy_density": 0.1,
	"treasure_density": 0.05,
	"use_random_seed": true,
	"custom_seed": "",
	"place_decorations": true,
	"place_enemies": true,
	"place_treasures": true
}

var parameter_controls = {}
var current_map_data = null
var generation_time = 0.0

signal map_generated(map_data)

func _ready():
	# Setup UI events
	generate_button.connect("pressed", Callable(self, "_on_generate_button_pressed"))
	save_button.connect("pressed", Callable(self, "_on_save_button_pressed"))
	reset_button.connect("pressed", Callable(self, "_on_reset_button_pressed"))
	
	# Initialize viewport and camera
	if viewport and camera:
		camera.position = Vector2(viewport.size) / 2
	
	# Generate parameter controls
	_create_parameter_controls()
	
	# Load map generator
	_load_map_generator()
	
	# Initialize with default settings
	reset_to_defaults()

func _load_map_generator():
	# Try to load map generator from the first level scene
	var generator_path = "res://scenes/levels/world.tscn"
	var scene = ResourceLoader.load(generator_path, "", ResourceLoader.CACHE_MODE_REUSE)
	
	if scene:
		var instance = scene.instantiate()
		var generators = instance.get_node_or_null("MapGenerator")
		
		if generators:
			map_generator = generators.duplicate()
			add_child(map_generator)
			status_label.text = "Map generator loaded"
		else:
			status_label.text = "Error: No MapGenerator node found"
			
		instance.queue_free()
	else:
		status_label.text = "Error: Could not load world scene"

func _create_parameter_controls():
	# Create controls for each parameter
	_add_int_parameter("width", "Width", 20, 200, 1)
	_add_int_parameter("height", "Height", 20, 150, 1)
	_add_int_parameter("min_room_size", "Min Room Size", 3, 20, 1)
	_add_int_parameter("max_room_size", "Max Room Size", 5, 30, 1)
	_add_int_parameter("min_rooms", "Min Rooms", 1, 50, 1)
	_add_int_parameter("max_rooms", "Max Rooms", 5, 100, 1)
	_add_int_parameter("corridor_width", "Corridor Width", 1, 5, 1)
	_add_float_parameter("room_spread", "Room Spread", 1.0, 3.0, 0.1)
	_add_float_parameter("enemy_density", "Enemy Density", 0, 0.5, 0.01)
	_add_float_parameter("treasure_density", "Treasure Density", 0, 0.3, 0.01)
	_add_bool_parameter("use_random_seed", "Use Random Seed")
	_add_string_parameter("custom_seed", "Custom Seed")
	_add_bool_parameter("place_decorations", "Place Decorations")
	_add_bool_parameter("place_enemies", "Place Enemies")
	_add_bool_parameter("place_treasures", "Place Treasures")

func _add_int_parameter(param_name, display_name, min_val, max_val, step):
	var container = HBoxContainer.new()
	var label = Label.new()
	var slider = HSlider.new()
	var value_label = Label.new()
	
	label.text = display_name + ":"
	label.custom_minimum_size.x = 150
	
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step
	slider.value = parameters[param_name]
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	value_label.text = str(parameters[param_name])
	value_label.custom_minimum_size.x = 50
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	container.add_child(label)
	container.add_child(slider)
	container.add_child(value_label)
	parameter_container.add_child(container)
	
	# Connect signal and store reference
	slider.connect("value_changed", Callable(self, "_on_parameter_changed").bind(param_name, value_label))
	parameter_controls[param_name] = slider

func _add_float_parameter(param_name, display_name, min_val, max_val, step):
	var container = HBoxContainer.new()
	var label = Label.new()
	var slider = HSlider.new()
	var value_label = Label.new()
	
	label.text = display_name + ":"
	label.custom_minimum_size.x = 150
	
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step
	slider.value = parameters[param_name]
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	value_label.text = str(parameters[param_name])
	value_label.custom_minimum_size.x = 50
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	container.add_child(label)
	container.add_child(slider)
	container.add_child(value_label)
	parameter_container.add_child(container)
	
	# Connect signal and store reference
	slider.connect("value_changed", Callable(self, "_on_parameter_changed").bind(param_name, value_label))
	parameter_controls[param_name] = slider

func _add_bool_parameter(param_name, display_name):
	var container = HBoxContainer.new()
	var label = Label.new()
	var checkbox = CheckBox.new()
	
	label.text = display_name + ":"
	label.custom_minimum_size.x = 150
	
	checkbox.button_pressed = parameters[param_name]
	checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	container.add_child(label)
	container.add_child(checkbox)
	parameter_container.add_child(container)
	
	# Connect signal and store reference
	checkbox.connect("toggled", Callable(self, "_on_bool_parameter_changed").bind(param_name))
	parameter_controls[param_name] = checkbox

func _add_string_parameter(param_name, display_name):
	var container = HBoxContainer.new()
	var label = Label.new()
	var line_edit = LineEdit.new()
	
	label.text = display_name + ":"
	label.custom_minimum_size.x = 150
	
	line_edit.text = parameters[param_name]
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.editable = !parameters["use_random_seed"]
	
	container.add_child(label)
	container.add_child(line_edit)
	parameter_container.add_child(container)
	
	# Connect signal and store reference
	line_edit.connect("text_changed", Callable(self, "_on_string_parameter_changed").bind(param_name))
	parameter_controls[param_name] = line_edit

func _on_parameter_changed(value, param_name, value_label):
	parameters[param_name] = value
	value_label.text = str(value)
	
	# Handle special cases
	if param_name == "min_room_size" and parameters["max_room_size"] < value:
		parameters["max_room_size"] = value
		parameter_controls["max_room_size"].value = value
	
	if param_name == "max_room_size" and parameters["min_room_size"] > value:
		parameters["min_room_size"] = value
		parameter_controls["min_room_size"].value = value
	
	if param_name == "min_rooms" and parameters["max_rooms"] < value:
		parameters["max_rooms"] = value
		parameter_controls["max_rooms"].value = value
	
	if param_name == "max_rooms" and parameters["min_rooms"] > value:
		parameters["min_rooms"] = value
		parameter_controls["min_rooms"].value = value

func _on_bool_parameter_changed(value, param_name):
	parameters[param_name] = value
	
	# Handle special cases
	if param_name == "use_random_seed":
		if parameter_controls.has("custom_seed"):
			parameter_controls["custom_seed"].editable = !value

func _on_string_parameter_changed(value, param_name):
	parameters[param_name] = value

func _on_generate_button_pressed():
	if map_generator and map_generator.has_method("generate_map"):
		status_label.text = "Generating map..."
		
		# Measure generation time
		var start_time = Time.get_ticks_msec()
		
		# Clear existing map if any
		for child in viewport.get_children():
			if child != camera and child.is_in_group("map"):
				child.queue_free()
		
		# Create map parameters
		var map_params = parameters.duplicate()
		
		# Generate seed if using random
		if map_params["use_random_seed"]:
			map_params["custom_seed"] = str(randi())
			if parameter_controls.has("custom_seed"):
				parameter_controls["custom_seed"].text = map_params["custom_seed"]
		
		# Generate map
		current_map_data = map_generator.generate_map_preview(map_params)
		
		# Add map to viewport
		if current_map_data and current_map_data.has("map_node"):
			viewport.add_child(current_map_data.map_node)
			
			# Calculate generation time
			generation_time = (Time.get_ticks_msec() - start_time) / 1000.0
			
			# Update statistics
			_update_statistics()
			
			# Update status
			status_label.text = "Map generated successfully"
			
			# Position camera
			if camera:
				var map_size = Vector2(parameters["width"], parameters["height"]) * current_map_data.tile_size
				camera.position = map_size / 2
			
			# Emit signal
			map_generated.emit(current_map_data)
		else:
			status_label.text = "Error: Failed to generate map"
	else:
		status_label.text = "Error: Map generator not loaded or invalid"

func _on_save_button_pressed():
	if current_map_data:
		# Save map configuration to file
		var config = ConfigFile.new()
		
		# Save parameters
		for param_name in parameters:
			config.set_value("parameters", param_name, parameters[param_name])
		
		# Save map data
		config.set_value("map_data", "seed", current_map_data.seed_value)
		config.set_value("map_data", "width", current_map_data.width)
		config.set_value("map_data", "height", current_map_data.height)
		config.set_value("map_data", "room_count", current_map_data.room_count)
		
		# Save to file
		var datetime = Time.get_datetime_dict_from_system()
		var timestamp = "%d-%02d-%02d_%02d-%02d-%02d" % [
			datetime["year"], datetime["month"], datetime["day"],
			datetime["hour"], datetime["minute"], datetime["second"]
		]
		var filename = "user://map_config_" + timestamp + ".cfg"
		
		var error = config.save(filename)
		if error == OK:
			status_label.text = "Map configuration saved to: " + filename
		else:
			status_label.text = "Error saving map configuration"
	else:
		status_label.text = "No map data to save"

func _on_reset_button_pressed():
	reset_to_defaults()

func reset_to_defaults():
	# Reset parameters to defaults
	parameters = {
		"width": 80,
		"height": 60,
		"min_room_size": 6,
		"max_room_size": 15,
		"min_rooms": 8,
		"max_rooms": 15,
		"corridor_width": 2,
		"room_spread": 1.5,
		"enemy_density": 0.1,
		"treasure_density": 0.05,
		"use_random_seed": true,
		"custom_seed": "",
		"place_decorations": true,
		"place_enemies": true,
		"place_treasures": true
	}
	
	# Update UI controls
	for param_name in parameter_controls:
		var control = parameter_controls[param_name]
		
		if control is Slider:
			control.value = parameters[param_name]
		elif control is CheckBox:
			control.button_pressed = parameters[param_name]
		elif control is LineEdit:
			control.text = parameters[param_name]
			control.editable = !parameters["use_random_seed"]
	
	status_label.text = "Parameters reset to defaults"

func _update_statistics():
	if current_map_data:
		tiles_count_label.text = "Tiles: " + str(current_map_data.tile_count)
		rooms_count_label.text = "Rooms: " + str(current_map_data.room_count)
		generation_time_label.text = "Generation Time: " + str(generation_time) + " sec"
	else:
		tiles_count_label.text = "Tiles: 0"
		rooms_count_label.text = "Rooms: 0"
		generation_time_label.text = "Generation Time: 0 sec" 