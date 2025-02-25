extends CanvasLayer
class_name DebugConsole

@onready var console_panel = $ConsolePanel
@onready var command_input = $ConsolePanel/VBoxContainer/CommandInput
@onready var output_text = $ConsolePanel/VBoxContainer/OutputText
@onready var fps_label = $FPSLabel
@onready var stats_panel = $StatsPanel
@onready var memory_label = $StatsPanel/VBoxContainer/MemoryLabel
@onready var draw_calls_label = $StatsPanel/VBoxContainer/DrawCallsLabel
@onready var objects_label = $StatsPanel/VBoxContainer/ObjectsLabel

var command_history = []
var history_position = -1
var show_fps = true
var show_stats = true

signal command_executed(command, result)

func _ready():
	# Hide console by default
	console_panel.visible = false
	
	# Connect signals
	command_input.connect("text_submitted", Callable(self, "_on_command_submitted"))
	
	# Initialize stats display
	fps_label.visible = show_fps
	stats_panel.visible = show_stats
	
	# Register event bus signals
	EventBus.connect("debug_log", Callable(self, "add_log_message"))
	EventBus.connect("toggle_debug_overlay", Callable(self, "toggle_visibility"))
	EventBus.connect("performance_measured", Callable(self, "update_performance_stats"))

func _input(event):
	if event.is_action_pressed("toggle_console"):
		toggle_console()
	
	# Handle command history navigation
	if console_panel.visible:
		if event.is_action_pressed("ui_up") and command_history.size() > 0:
			navigate_history(-1)
		elif event.is_action_pressed("ui_down") and command_history.size() > 0:
			navigate_history(1)

func _process(_delta):
	if show_fps:
		fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
	
	if show_stats:
		update_stats_display()

func toggle_console():
	console_panel.visible = !console_panel.visible
	
	if console_panel.visible:
		command_input.grab_focus()
	else:
		# Return focus to game
		get_viewport().set_input_as_handled()

func toggle_fps_display():
	show_fps = !show_fps
	fps_label.visible = show_fps
	
	return "FPS display " + ("enabled" if show_fps else "disabled")

func toggle_stats_display():
	show_stats = !show_stats
	stats_panel.visible = show_stats
	
	return "Stats display " + ("enabled" if show_stats else "disabled")

func update_stats_display():
	# Update memory usage
	var mem_usage = OS.get_static_memory_usage() / 1024 / 1024
	memory_label.text = "Memory: " + str(mem_usage) + " MB"
	
	# Update draw calls if RenderingServer is available
	if RenderingServer:
		draw_calls_label.text = "Draw Calls: " + str(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	
	# Update object count
	objects_label.text = "Nodes: " + str(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))

func _on_command_submitted(command: String):
	# Don't process empty commands
	if command.strip_edges() == "":
		return
	
	# Add to history
	command_history.push_front(command)
	if command_history.size() > 20:
		command_history.pop_back()
	
	history_position = -1
	
	# Add to output
	output_text.text += "\n> " + command
	
	# Process command
	var result = execute_command(command)
	
	# Show result
	if result != null:
		output_text.text += "\n" + str(result)
	
	# Clear input
	command_input.text = ""
	
	# Ensure output text is scrolled to bottom
	await get_tree().process_frame
	output_text.scroll_vertical = output_text.get_line_count()
	
	# Emit signal
	command_executed.emit(command, result)

func execute_command(command: String):
	var command_parts = command.split(" ")
	var command_name = command_parts[0].to_lower()
	var args = command_parts.slice(1)
	
	match command_name:
		"help":
			return show_help()
		"clear":
			output_text.text = ""
			return null
		"fps":
			return toggle_fps_display()
		"stats":
			return toggle_stats_display()
		"player":
			return player_command(args)
		"spawn":
			return spawn_command(args)
		"god":
			return toggle_god_mode()
		"kill":
			return kill_command(args)
		"teleport":
			return teleport_command(args)
		"add_item":
			return add_item_command(args)
		"reload":
			return reload_scene()
		_:
			return "Unknown command: " + command_name

func show_help():
	return """Available commands:
help - Show this message
clear - Clear console output
fps - Toggle FPS display
stats - Toggle stats display
player <health|mana|level> [value] - Get/set player stats
spawn <enemy_type> [count] - Spawn enemies
god - Toggle god mode
kill <all|enemies|self> - Kill specified targets
teleport <x> <y> - Teleport player to coordinates
add_item <item_id> [quantity] - Add items to inventory
reload - Reload current scene"""

func player_command(args):
	if args.size() == 0:
		return "Usage: player <health|mana|level> [value]"
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return "Player not found in scene"
	
	var stat_name = args[0].to_lower()
	
	# If no value provided, just show current value
	if args.size() == 1:
		match stat_name:
			"health":
				return "Player health: " + str(player.stats.current_health) + "/" + str(player.stats.max_health)
			"mana":
				return "Player mana: " + str(player.stats.current_mana) + "/" + str(player.stats.max_mana)
			"level":
				return "Player level: " + str(player.stats.level) + " (XP: " + str(player.stats.experience) + "/" + str(player.stats.next_level_exp) + ")"
			_:
				return "Unknown stat: " + stat_name
	
	# If value provided, set it
	var value = int(args[1])
	
	match stat_name:
		"health":
			player.stats.current_health = value
			return "Set player health to " + str(value)
		"mana":
			player.stats.current_mana = value
			return "Set player mana to " + str(value)
		"level":
			while player.stats.level < value:
				player.stats.level_up()
			return "Set player level to " + str(value)
		_:
			return "Unknown stat: " + stat_name

func spawn_command(args):
	if args.size() == 0:
		return "Usage: spawn <enemy_type> [count]"
		
	var enemy_type = args[0]
	var count = 1
	
	if args.size() > 1:
		count = int(args[1])
	
	var spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if not spawner:
		return "No enemy spawner found in scene"
		
	var result = spawner.spawn_enemies(enemy_type, count)
	return result

func toggle_god_mode():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return "Player not found in scene"
		
	player.god_mode = !player.god_mode
	return "God mode " + ("enabled" if player.god_mode else "disabled")

func kill_command(args):
	if args.size() == 0:
		return "Usage: kill <all|enemies|self>"
		
	var target = args[0].to_lower()
	
	match target:
		"all":
			var enemies = get_tree().get_nodes_in_group("enemy")
			for enemy in enemies:
				enemy.die()
				
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.die()
				
			return "Killed all entities"
			
		"enemies":
			var enemies = get_tree().get_nodes_in_group("enemy")
			for enemy in enemies:
				enemy.die()
			return "Killed " + str(enemies.size()) + " enemies"
			
		"self":
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.die()
				return "Player killed"
			return "Player not found in scene"
			
		_:
			return "Unknown target: " + target

func teleport_command(args):
	if args.size() < 2:
		return "Usage: teleport <x> <y>"
		
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return "Player not found in scene"
		
	var x = float(args[0])
	var y = float(args[1])
	
	player.global_position = Vector2(x, y)
	return "Teleported player to (" + str(x) + ", " + str(y) + ")"

func add_item_command(args):
	if args.size() == 0:
		return "Usage: add_item <item_id> [quantity]"
		
	var item_id = args[0]
	var quantity = 1
	
	if args.size() > 1:
		quantity = int(args[1])
		
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.has_method("add_item"):
		return "Player not found or doesn't have inventory"
		
	var result = player.add_item(item_id, quantity)
	return result

func reload_scene():
	get_tree().reload_current_scene()
	return "Reloading scene..."

func add_log_message(message: String, category: String = "INFO", severity: int = 0):
	var severity_str = ""
	match severity:
		0: severity_str = "[INFO]"
		1: severity_str = "[WARNING]"
		2: severity_str = "[ERROR]"
		_: severity_str = "[DEBUG]"
		
	var timestamp = Time.get_time_string_from_system()
	var log_entry = timestamp + " " + severity_str + " [" + category + "]: " + message
	
	output_text.text += "\n" + log_entry
	
	# Ensure we don't exceed max log lines
	var lines = output_text.text.split("\n")
	if lines.size() > 500:
		output_text.text = lines.slice(-500).join("\n")
	
	# Scroll to bottom
	await get_tree().process_frame
	output_text.scroll_vertical = output_text.get_line_count()

func navigate_history(direction):
	# Move in history
	history_position += direction
	
	# Clamp history position
	history_position = clamp(history_position, -1, command_history.size() - 1)
	
	if history_position == -1:
		command_input.text = ""
	else:
		command_input.text = command_history[history_position]
		
	# Move cursor to end
	command_input.caret_column = command_input.text.length()

func update_performance_stats(fps: int, memory_usage: int):
	if fps_label:
		fps_label.text = "FPS: " + str(fps)
	
	if memory_label:
		memory_label.text = "Memory: " + str(memory_usage) + " MB" 