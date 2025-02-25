extends Control
class_name PerformanceMonitorTool

# Node references for UI elements
var fps_chart: Control
var memory_chart: Control
var draw_calls_chart: Control
var objects_chart: Control
var monitoring_toggle: CheckButton
var record_button: Button
var clear_button: Button
var metrics_list: ItemList
var refresh_rate_slider: HSlider
var refresh_rate_label: Label
var threshold_slider: HSlider
var threshold_label: Label
var recording_label: Label
var selected_metric_label: Label

# Performance data
var metrics: Dictionary = {}
var current_metrics: Dictionary = {}
var is_recording: bool = false
var is_monitoring: bool = true
var refresh_rate: float = 1.0  # seconds
var fps_threshold: int = 30  # FPS alert threshold
var refresh_timer: float = 0.0
var record_start_time: float = 0.0
var recording_time: float = 0.0
var selected_metric: String = ""

# Constants
const MAX_HISTORY_POINTS = 100  # Maximum number of data points to store
const ALERT_COLOR = Color(1, 0.3, 0.3, 1)  # Red for alerts
const NORMAL_COLOR = Color(0.3, 1, 0.3, 1)  # Green for normal values
const CHART_COLORS = {
	"fps": Color(0.2, 0.7, 1),
	"memory": Color(1, 0.6, 0.2),
	"draw_calls": Color(0.8, 0.2, 1),
	"objects": Color(0.2, 1, 0.6)
}

func _ready():
	setup()

func setup():
	# Initialize performance metrics tracking
	metrics = {
		"fps": {
			"name": "FPS",
			"current": 0,
			"min": 0,
			"max": 0,
			"avg": 0,
			"history": [],
			"alerts": 0
		},
		"memory": {
			"name": "Memory (MB)",
			"current": 0,
			"min": 0,
			"max": 0, 
			"avg": 0,
			"history": [],
			"alerts": 0
		},
		"draw_calls": {
			"name": "Draw Calls",
			"current": 0,
			"min": 0,
			"max": 0,
			"avg": 0,
			"history": [],
			"alerts": 0
		},
		"objects": {
			"name": "Objects",
			"current": 0,
			"min": 0,
			"max": 0,
			"avg": 0,
			"history": [],
			"alerts": 0
		}
	}
	
	selected_metric = "fps"
	
	# Connect UI signals when scene is ready
	if monitoring_toggle:
		monitoring_toggle.button_pressed = is_monitoring
		monitoring_toggle.connect("toggled", Callable(self, "_on_monitoring_toggle"))
	
	if record_button:
		record_button.connect("pressed", Callable(self, "_on_record_button_pressed"))
	
	if clear_button:
		clear_button.connect("pressed", Callable(self, "_on_clear_button_pressed"))
	
	if metrics_list:
		metrics_list.connect("item_selected", Callable(self, "_on_metric_selected"))
		_populate_metrics_list()
	
	if refresh_rate_slider:
		refresh_rate_slider.value = refresh_rate
		refresh_rate_slider.connect("value_changed", Callable(self, "_on_refresh_rate_changed"))
	
	if refresh_rate_label:
		refresh_rate_label.text = str(refresh_rate) + " sec"
	
	if threshold_slider:
		threshold_slider.value = fps_threshold
		threshold_slider.connect("value_changed", Callable(self, "_on_threshold_changed"))
	
	if threshold_label:
		threshold_label.text = str(fps_threshold) + " FPS"
	
	if selected_metric_label:
		selected_metric_label.text = "Selected: " + metrics[selected_metric]["name"]

func _process(delta):
	if !is_monitoring:
		return
	
	# Update refresh timer
	refresh_timer += delta
	
	# If recording, update recording time
	if is_recording:
		recording_time = Time.get_ticks_msec() / 1000.0 - record_start_time
		if recording_label:
			recording_label.text = "Recording: %.1f s" % recording_time
	
	# Only update metrics on specific intervals to avoid performance impact
	if refresh_timer >= refresh_rate:
		refresh_timer = 0
		update_metrics()
		update_charts()
	
	# Force redraw of charts
	if fps_chart:
		fps_chart.queue_redraw()
	if memory_chart:
		memory_chart.queue_redraw()
	if draw_calls_chart:
		draw_calls_chart.queue_redraw()
	if objects_chart:
		objects_chart.queue_redraw()

func update_metrics():
	# Get current performance data
	var current_fps = Engine.get_frames_per_second()
	var current_memory = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576  # Convert to MB
	var current_draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var current_objects = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	
	# Update current metrics
	current_metrics = {
		"fps": current_fps,
		"memory": current_memory,
		"draw_calls": current_draw_calls,
		"objects": current_objects
	}
	
	# If recording, update metric history and statistics
	if is_recording:
		for key in metrics.keys():
			var value = current_metrics[key]
			var metric = metrics[key]
			
			# Update current value
			metric["current"] = value
			
			# Add to history
			metric["history"].append(value)
			if metric["history"].size() > MAX_HISTORY_POINTS:
				metric["history"].pop_front()
			
			# Update min/max
			if metric["history"].size() == 1 or value < metric["min"]:
				metric["min"] = value
			
			if metric["history"].size() == 1 or value > metric["max"]:
				metric["max"] = value
			
			# Calculate average
			var sum = 0
			for v in metric["history"]:
				sum += v
			metric["avg"] = sum / metric["history"].size()
			
			# Check for FPS alert
			if key == "fps" and value < fps_threshold:
				metric["alerts"] += 1
	
	# Update metrics display even if not recording
	_update_metrics_display()

func _update_metrics_display():
	# Update metrics list if it exists
	if metrics_list:
		var selected_idx = metrics_list.get_selected_items()
		metrics_list.clear()
		
		var idx = 0
		for key in metrics.keys():
			var metric = metrics[key]
			var text = "%s: %d" % [metric["name"], metric["current"]]
			
			metrics_list.add_item(text)
			
			# Set color based on alerts for FPS
			if key == "fps" and metric["current"] < fps_threshold:
				metrics_list.set_item_custom_fg_color(idx, ALERT_COLOR)
			else:
				metrics_list.set_item_custom_fg_color(idx, NORMAL_COLOR)
			
			idx += 1
		
		# Restore selection
		if selected_idx.size() > 0:
			metrics_list.select(selected_idx[0])

func _populate_metrics_list():
	if metrics_list:
		metrics_list.clear()
		
		for key in metrics.keys():
			var metric = metrics[key]
			var text = "%s: 0" % metric["name"]
			metrics_list.add_item(text)

func update_charts():
	# Update is handled by _draw in each chart control
	pass

func _on_monitoring_toggle(toggle):
	is_monitoring = toggle
	
	if !is_monitoring and is_recording:
		_stop_recording()

func _on_record_button_pressed():
	if is_recording:
		_stop_recording()
	else:
		_start_recording()

func _start_recording():
	if !is_monitoring:
		is_monitoring = true
		if monitoring_toggle:
			monitoring_toggle.button_pressed = true
	
	is_recording = true
	record_start_time = Time.get_ticks_msec() / 1000.0
	recording_time = 0
	
	# Clear previous recordings
	for key in metrics.keys():
		var metric = metrics[key]
		metric["history"].clear()
		metric["min"] = 0
		metric["max"] = 0
		metric["avg"] = 0
		metric["alerts"] = 0
	
	if record_button:
		record_button.text = "Stop Recording"
	
	if recording_label:
		recording_label.text = "Recording: 0.0 s"

func _stop_recording():
	is_recording = false
	
	if record_button:
		record_button.text = "Start Recording"

func _on_clear_button_pressed():
	# Reset all metrics
	for key in metrics.keys():
		var metric = metrics[key]
		metric["history"].clear()
		metric["current"] = 0
		metric["min"] = 0
		metric["max"] = 0
		metric["avg"] = 0
		metric["alerts"] = 0
	
	_update_metrics_display()
	
	if recording_label:
		recording_label.text = "Recording: 0.0 s"

func _on_metric_selected(index):
	var key_list = metrics.keys()
	if index >= 0 and index < key_list.size():
		selected_metric = key_list[index]
		
		if selected_metric_label:
			selected_metric_label.text = "Selected: " + metrics[selected_metric]["name"]

func _on_refresh_rate_changed(value):
	refresh_rate = value
	
	if refresh_rate_label:
		refresh_rate_label.text = "%.1f sec" % refresh_rate

func _on_threshold_changed(value):
	fps_threshold = int(value)
	
	if threshold_label:
		threshold_label.text = "%d FPS" % fps_threshold

# Drawing methods for charts (to be implemented by chart controls)
func draw_fps_chart(canvas_item, rect):
	_draw_chart(canvas_item, rect, "fps", CHART_COLORS["fps"])

func draw_memory_chart(canvas_item, rect):
	_draw_chart(canvas_item, rect, "memory", CHART_COLORS["memory"])

func draw_draw_calls_chart(canvas_item, rect):
	_draw_chart(canvas_item, rect, "draw_calls", CHART_COLORS["draw_calls"])

func draw_objects_chart(canvas_item, rect):
	_draw_chart(canvas_item, rect, "objects", CHART_COLORS["objects"])

func _draw_chart(canvas_item, rect, metric_key, color):
	var metric = metrics[metric_key]
	var history = metric["history"]
	
	if history.size() < 2:
		return
	
	# Draw background grid
	_draw_chart_grid(canvas_item, rect)
	
	# Find min and max for scaling
	var min_val = metric["min"]
	var max_val = metric["max"]
	
	# Ensure there's a reasonable range
	if max_val - min_val < 1:
		max_val = min_val + 1
	
	# Add some padding
	var range = max_val - min_val
	min_val -= range * 0.1
	max_val += range * 0.1
	
	# Draw chart line
	var points = PackedVector2Array()
	var point_width = rect.size.x / float(MAX_HISTORY_POINTS - 1)
	
	for i in range(history.size()):
		var x = rect.position.x + i * point_width
		var normalized_value = (history[i] - min_val) / (max_val - min_val)
		var y = rect.position.y + rect.size.y - (normalized_value * rect.size.y)
		points.append(Vector2(x, y))
	
	if points.size() > 1:
		for i in range(points.size() - 1):
			canvas_item.draw_line(points[i], points[i + 1], color, 2.0, true)
	
	# Draw threshold line for FPS
	if metric_key == "fps":
		var normalized_threshold = (fps_threshold - min_val) / (max_val - min_val)
		var threshold_y = rect.position.y + rect.size.y - (normalized_threshold * rect.size.y)
		var threshold_start = Vector2(rect.position.x, threshold_y)
		var threshold_end = Vector2(rect.position.x + rect.size.x, threshold_y)
		
		canvas_item.draw_line(threshold_start, threshold_end, ALERT_COLOR, 1.0, true)
	
	# Draw current, min, max values
	var font_color = Color.WHITE
	var font_size = 12
	var text_offset = Vector2(5, 15)
	
	var labels = [
		"Current: %.1f" % metric["current"],
		"Min: %.1f" % metric["min"],
		"Max: %.1f" % metric["max"], 
		"Avg: %.1f" % metric["avg"]
	]
	
	for i in range(labels.size()):
		var pos = Vector2(rect.position.x + text_offset.x, rect.position.y + text_offset.y + i * text_offset.y)
		canvas_item.draw_string(ThemeDB.fallback_font, pos, labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, font_color)

func _draw_chart_grid(canvas_item, rect):
	var grid_color = Color(0.3, 0.3, 0.3, 0.5)
	var bg_color = Color(0.1, 0.1, 0.1, 0.8)
	
	# Draw background
	canvas_item.draw_rect(rect, bg_color)
	
	# Draw horizontal grid lines
	var h_lines = 5
	for i in range(h_lines):
		var y = rect.position.y + (i + 1) * (rect.size.y / (h_lines + 1))
		canvas_item.draw_line(
			Vector2(rect.position.x, y),
			Vector2(rect.position.x + rect.size.x, y),
			grid_color, 1.0, true
		)
	
	# Draw vertical grid lines
	var v_lines = 5
	for i in range(v_lines):
		var x = rect.position.x + (i + 1) * (rect.size.x / (v_lines + 1))
		canvas_item.draw_line(
			Vector2(x, rect.position.y),
			Vector2(x, rect.position.y + rect.size.y),
			grid_color, 1.0, true
		)

# Export performance data to file
func export_data():
	if !is_recording or metrics["fps"]["history"].size() == 0:
		return
	
	var data = {
		"timestamp": Time.get_datetime_string_from_system(),
		"duration": recording_time,
		"metrics": {}
	}
	
	for key in metrics.keys():
		data["metrics"][key] = {
			"min": metrics[key]["min"],
			"max": metrics[key]["max"],
			"avg": metrics[key]["avg"],
			"history": metrics[key]["history"],
			"alerts": metrics[key]["alerts"]
		}
	
	var timestamp = Time.get_datetime_dict_from_system()
	var file_timestamp = "%d-%02d-%02d_%02d-%02d-%02d" % [
		timestamp["year"], timestamp["month"], timestamp["day"],
		timestamp["hour"], timestamp["minute"], timestamp["second"]
	]
	
	var file_path = "user://performance_log_%s.json" % file_timestamp
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file:
		file.store_string(JSON.stringify(data, "  "))
		return file_path
	
	return "" 