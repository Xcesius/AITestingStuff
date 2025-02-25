extends Control
class_name AIVisualizerTool

# Node references - will be connected when scene is created
var enemy_list: ItemList
var state_display: Label
var state_history: RichTextLabel
var detection_radius_toggle: CheckBox
var path_toggle: CheckBox
var state_time_display: Label
var target_display: Label
var pause_button: Button
var viewport_container: SubViewportContainer
var debug_viewport: SubViewport
var camera: Camera2D

# Visualization data
var tracked_enemies: Array = []
var selected_enemy = null
var state_history_data = {}
var is_initialized: bool = false
var show_detection_radius: bool = true
var show_path: bool = true
var paused: bool = false
var enemy_colors = {}
var next_color_index = 0
var color_palette = [
	Color(1, 0.3, 0.3),     # Red
	Color(0.3, 0.7, 1),     # Blue
	Color(0.3, 1, 0.3),     # Green
	Color(1, 1, 0.3),       # Yellow
	Color(1, 0.3, 1),       # Magenta
	Color(0.3, 1, 1),       # Cyan
	Color(1, 0.6, 0.3),     # Orange
	Color(0.8, 0.3, 1)      # Purple
]

signal enemy_selected(enemy)

func _ready():
	setup()

func setup():
	# Connect UI signals when scene is ready
	if detection_radius_toggle:
		detection_radius_toggle.button_pressed = show_detection_radius
		detection_radius_toggle.connect("toggled", Callable(self, "_on_detection_radius_toggled"))
	
	if path_toggle:
		path_toggle.button_pressed = show_path
		path_toggle.connect("toggled", Callable(self, "_on_path_toggled"))
	
	if pause_button:
		pause_button.connect("pressed", Callable(self, "_on_pause_button_pressed"))
	
	if enemy_list:
		enemy_list.connect("item_selected", Callable(self, "_on_enemy_selected"))
	
	is_initialized = true

func _process(delta):
	if !is_initialized or paused:
		return
	
	# Update enemy list if enemies have changed
	update_enemy_tracking()
	
	# Update visualization for selected enemy
	if selected_enemy and is_instance_valid(selected_enemy):
		update_selected_enemy_display()
	
	# Custom draw for debugging visualization
	queue_redraw()

func _draw():
	if !is_visible() or !is_initialized:
		return
	
	# This will be called for custom drawing in the control
	# Actual drawing would happen in the game world, not in the tool UI
	pass

func update_enemy_tracking():
	# Find all enemies in the scene
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	# Add new enemies to tracked list
	for enemy in enemies:
		if !tracked_enemies.has(enemy):
			add_enemy(enemy)
	
	# Remove enemies that are no longer valid
	var enemies_to_remove = []
	for enemy in tracked_enemies:
		if !is_instance_valid(enemy) or !enemies.has(enemy):
			enemies_to_remove.append(enemy)
	
	for enemy in enemies_to_remove:
		remove_enemy(enemy)
	
	# Update enemy list display
	update_enemy_list()

func add_enemy(enemy):
	tracked_enemies.append(enemy)
	state_history_data[enemy.get_instance_id()] = []
	
	# Assign color for this enemy
	enemy_colors[enemy.get_instance_id()] = color_palette[next_color_index % color_palette.size()]
	next_color_index += 1
	
	# Connect to enemy signals
	if enemy.has_signal("state_changed"):
		enemy.connect("state_changed", Callable(self, "_on_enemy_state_changed").bind(enemy))

func remove_enemy(enemy):
	tracked_enemies.erase(enemy)
	var instance_id = enemy.get_instance_id()
	state_history_data.erase(instance_id)
	enemy_colors.erase(instance_id)
	
	# If this was the selected enemy, clear selection
	if selected_enemy == enemy:
		selected_enemy = null
		clear_enemy_display()

func update_enemy_list():
	if !enemy_list:
		return
		
	# Store current selection
	var selected_idx = enemy_list.get_selected_items()
	var current_selection = selected_idx.size() > 0 ? selected_idx[0] : -1
	var current_enemy_id = current_selection >= 0 ? enemy_list.get_item_metadata(current_selection) : -1
	
	enemy_list.clear()
	
	var idx = 0
	var new_selection = -1
	
	for enemy in tracked_enemies:
		if is_instance_valid(enemy):
			var enemy_name = enemy.name
			var enemy_type = enemy.get_class()
			var state_name = get_enemy_state(enemy)
			
			var display_text = "%s (%s) - %s" % [enemy_name, enemy_type, state_name]
			enemy_list.add_item(display_text)
			
			# Store enemy instance ID as metadata
			var instance_id = enemy.get_instance_id()
			enemy_list.set_item_metadata(idx, instance_id)
			
			# Set item color
			if enemy_colors.has(instance_id):
				enemy_list.set_item_custom_fg_color(idx, enemy_colors[instance_id])
			
			# Maintain selection if possible
			if instance_id == current_enemy_id:
				new_selection = idx
			
			idx += 1
	
	# Restore selection
	if new_selection >= 0:
		enemy_list.select(new_selection)
	elif idx > 0 and selected_enemy == null:
		# Select first item if nothing was selected
		enemy_list.select(0)
		_on_enemy_selected(0)

func _on_enemy_selected(index):
	var instance_id = enemy_list.get_item_metadata(index)
	
	# Find enemy by instance ID
	selected_enemy = null
	for enemy in tracked_enemies:
		if enemy.get_instance_id() == instance_id:
			selected_enemy = enemy
			break
	
	update_selected_enemy_display()
	emit_signal("enemy_selected", selected_enemy)

func update_selected_enemy_display():
	if !selected_enemy or !is_instance_valid(selected_enemy):
		clear_enemy_display()
		return
	
	var state_name = get_enemy_state(selected_enemy)
	var time_in_state = get_time_in_state(selected_enemy)
	var target = get_enemy_target(selected_enemy)
	
	if state_display:
		state_display.text = "Current State: " + state_name
	
	if state_time_display:
		state_time_display.text = "Time in state: %.2f sec" % time_in_state
	
	if target_display:
		if target and is_instance_valid(target):
			target_display.text = "Target: " + target.name
		else:
			target_display.text = "Target: None"
	
	update_state_history_display()
	
	# If debug viewport exists, focus camera on selected enemy
	if debug_viewport and camera and is_instance_valid(selected_enemy):
		camera.global_position = selected_enemy.global_position

func update_state_history_display():
	if !state_history or !selected_enemy:
		return
		
	var instance_id = selected_enemy.get_instance_id()
	if !state_history_data.has(instance_id):
		state_history.text = "No state history available"
		return
		
	var history = state_history_data[instance_id]
	if history.size() == 0:
		state_history.text = "No state transitions recorded"
		return
	
	var history_text = ""
	for entry in history:
		var time_str = "%.2f" % entry.time_elapsed
		var prev_state = entry.previous_state if entry.has("previous_state") else "None"
		var new_state = entry.new_state
		
		history_text += "[%s] %s -> %s\n" % [time_str, prev_state, new_state]
	
	state_history.text = history_text

func clear_enemy_display():
	if state_display:
		state_display.text = "No enemy selected"
	
	if state_time_display:
		state_time_display.text = "Time in state: 0.00 sec"
	
	if target_display:
		target_display.text = "Target: None"
	
	if state_history:
		state_history.text = ""

func _on_enemy_state_changed(previous_state, new_state, enemy):
	if !is_instance_valid(enemy):
		return
		
	var instance_id = enemy.get_instance_id()
	if state_history_data.has(instance_id):
		var time_elapsed = Time.get_ticks_msec() / 1000.0
		state_history_data[instance_id].push_front({
			"time_elapsed": time_elapsed,
			"previous_state": previous_state,
			"new_state": new_state
		})
		
		# Limit history size
		if state_history_data[instance_id].size() > 20:
			state_history_data[instance_id].resize(20)
	
	# Update UI if this is the selected enemy
	if selected_enemy == enemy:
		update_selected_enemy_display()

func _on_detection_radius_toggled(toggle):
	show_detection_radius = toggle

func _on_path_toggled(toggle):
	show_path = toggle

func _on_pause_button_pressed():
	paused = !paused
	if pause_button:
		pause_button.text = "Resume" if paused else "Pause"

# Helper methods to extract info from enemies regardless of their implementation
func get_enemy_state(enemy):
	# Try different ways to get the state name
	if enemy.has_method("get_current_state_name"):
		return enemy.get_current_state_name()
	elif enemy.has_method("get_state_name"):
		return enemy.get_state_name()
	elif enemy.get("current_state"):
		if typeof(enemy.current_state) == TYPE_STRING:
			return enemy.current_state
		elif typeof(enemy.current_state) == TYPE_OBJECT and enemy.current_state.has_method("get_name"):
			return enemy.current_state.get_name()
	elif enemy.get("state_machine") and enemy.state_machine.has_method("get_current_state_name"):
		return enemy.state_machine.get_current_state_name()
	
	# Fallback
	return "Unknown"

func get_time_in_state(enemy):
	# Try different ways to get time in state
	if enemy.has_method("get_time_in_state"):
		return enemy.get_time_in_state()
	elif enemy.get("state_time"):
		return enemy.state_time
	elif enemy.get("state_machine") and enemy.state_machine.has_method("get_time_in_state"):
		return enemy.state_machine.get_time_in_state()
	
	# Fallback
	return 0.0

func get_enemy_target(enemy):
	# Try different ways to get the enemy's target
	if enemy.has_method("get_target"):
		return enemy.get_target()
	elif enemy.get("target"):
		return enemy.target
	elif enemy.get("state_machine") and enemy.state_machine.has_method("get_target"):
		return enemy.state_machine.get_target()
	
	# Fallback
	return null

# Custom drawing in game world functions - these would be called by debug visualization nodes
func draw_detection_radius(canvas_item, enemy):
	if !show_detection_radius or !is_instance_valid(enemy):
		return
	
	var detection_radius = 100  # Default fallback
	
	# Try to get actual detection radius from enemy
	if enemy.has_method("get_detection_radius"):
		detection_radius = enemy.get_detection_radius()
	elif enemy.get("detection_radius"):
		detection_radius = enemy.detection_radius
	elif enemy.get("aggro_range"):
		detection_radius = enemy.aggro_range
	
	var color = enemy_colors.get(enemy.get_instance_id(), Color.RED)
	color.a = 0.3  # Make it semi-transparent
	
	# Draw circle for detection radius
	canvas_item.draw_circle(Vector2.ZERO, detection_radius, color)
	canvas_item.draw_arc(Vector2.ZERO, detection_radius, 0, TAU, 32, color, 1.0, true)

func draw_path(canvas_item, enemy):
	if !show_path or !is_instance_valid(enemy):
		return
	
	var path = []
	
	# Try to get navigation path from enemy
	if enemy.has_method("get_navigation_path"):
		path = enemy.get_navigation_path()
	elif enemy.get("navigation_path"):
		path = enemy.navigation_path
	elif enemy.get("path"):
		path = enemy.path
	
	if path.size() < 2:
		return
	
	var color = enemy_colors.get(enemy.get_instance_id(), Color.RED)
	
	# Draw lines between path points
	for i in range(path.size() - 1):
		var start = path[i] - enemy.global_position
		var end = path[i + 1] - enemy.global_position
		canvas_item.draw_line(start, end, color, 2.0, true)
		
		# Draw a small circle at each path point
		canvas_item.draw_circle(start, 3, color)
	
	# Draw circle at the last point
	if path.size() > 0:
		canvas_item.draw_circle(path[path.size() - 1] - enemy.global_position, 3, color)

# Called when the visualizer becomes visible
func on_visibility_changed():
	if visible:
		# Start tracking enemies when the visualizer becomes visible
		update_enemy_tracking()
	else:
		# Clear selected enemy when hidden
		selected_enemy = null 