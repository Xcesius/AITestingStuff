class_name DebugConsole
extends CanvasLayer

@onready var console_panel: Panel = $ConsolePanel
@onready var output_text: RichTextLabel = $ConsolePanel/VBoxContainer/OutputText
@onready var input_line: LineEdit = $ConsolePanel/VBoxContainer/InputLine

var command_history: Array = []
var history_position: int = -1
var registered_commands: Dictionary = {}

func _ready() -> void:
    console_panel.hide()
    input_line.text_submitted.connect(_on_command_submitted)
    
    # Register default commands
    register_command("help", _cmd_help, "Show available commands")
    register_command("clear", _cmd_clear, "Clear console output")
    register_command("spawn_enemy", _cmd_spawn_enemy, "Spawn enemy at player position")
    register_command("give_item", _cmd_give_item, "Give item to player: give_item <item_id> [amount]")
    register_command("god_mode", _cmd_god_mode, "Toggle player invincibility")
    register_command("teleport", _cmd_teleport, "Teleport player: teleport <x> <y>")

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_console"):
        toggle_console()
    elif console_panel.visible:
        if event.is_action_pressed("ui_up"):
            _navigate_history(-1)
        elif event.is_action_pressed("ui_down"):
            _navigate_history(1)

func toggle_console() -> void:
    console_panel.visible = not console_panel.visible
    if console_panel.visible:
        input_line.grab_focus()
    get_tree().paused = console_panel.visible

func register_command(name: String, callback: Callable, description: String) -> void:
    registered_commands[name] = {
        "callback": callback,
        "description": description
    }

func log(text: String, color: Color = Color.WHITE) -> void:
    output_text.append_text("[color=#%s]%s[/color]\n" % [color.to_html(), text])

func _on_command_submitted(command: String) -> void:
    if command.strip_edges().is_empty():
        return
    
    log("> " + command, Color.YELLOW)
    command_history.append(command)
    history_position = -1
    input_line.clear()
    
    var parts = command.split(" ", false)
    var cmd_name = parts[0].to_lower()
    var args = parts.slice(1)
    
    if registered_commands.has(cmd_name):
        registered_commands[cmd_name]["callback"].call(args)
    else:
        log("Unknown command: " + cmd_name, Color.RED)

func _navigate_history(direction: int) -> void:
    if command_history.is_empty():
        return
    
    history_position = clamp(
        history_position + direction,
        -1,
        command_history.size() - 1
    )
    
    if history_position == -1:
        input_line.text = ""
    else:
        input_line.text = command_history[command_history.size() - 1 - history_position]
    
    input_line.caret_column = input_line.text.length()

# Default commands
func _cmd_help(_args: Array) -> void:
    log("Available commands:", Color.LIGHT_BLUE)
    for cmd_name in registered_commands:
        var description = registered_commands[cmd_name]["description"]
        log("  %s - %s" % [cmd_name, description])

func _cmd_clear(_args: Array) -> void:
    output_text.clear()

func _cmd_spawn_enemy(args: Array) -> void:
    var player = get_tree().get_first_node_in_group("player")
    if not player:
        log("Player not found", Color.RED)
        return
    
    var enemy_scene = load("res://scenes/enemies/enemy.tscn")
    if not enemy_scene:
        log("Enemy scene not found", Color.RED)
        return
    
    var enemy = enemy_scene.instantiate()
    enemy.global_position = player.global_position
    get_tree().current_scene.add_child(enemy)
    log("Enemy spawned at player position", Color.GREEN)

func _cmd_give_item(args: Array) -> void:
    if args.size() < 1:
        log("Usage: give_item <item_id> [amount]", Color.RED)
        return
    
    var player = get_tree().get_first_node_in_group("player")
    if not player:
        log("Player not found", Color.RED)
        return
    
    var inventory = player.get_node("Inventory")
    if not inventory:
        log("Player inventory not found", Color.RED)
        return
    
    var item_id = args[0]
    var amount = 1 if args.size() < 2 else args[1].to_int()
    
    # Load item data
    var item_data = load("res://resources/items/" + item_id + ".tres")
    if not item_data:
        log("Item not found: " + item_id, Color.RED)
        return
    
    if inventory.add_item(item_data, amount):
        log("Added %dx %s to inventory" % [amount, item_data.name], Color.GREEN)
    else:
        log("Failed to add item (inventory full?)", Color.RED)

func _cmd_god_mode(_args: Array) -> void:
    var player = get_tree().get_first_node_in_group("player")
    if not player or not player.stats:
        log("Player or player stats not found", Color.RED)
        return
    
    player.stats.invincible = not player.stats.invincible
    log("God mode " + ("enabled" if player.stats.invincible else "disabled"), Color.GREEN)

func _cmd_teleport(args: Array) -> void:
    if args.size() < 2:
        log("Usage: teleport <x> <y>", Color.RED)
        return
    
    var player = get_tree().get_first_node_in_group("player")
    if not player:
        log("Player not found", Color.RED)
        return
    
    var x = float(args[0])
    var y = float(args[1])
    player.global_position = Vector2(x, y)
    log("Teleported player to (%d, %d)" % [x, y], Color.GREEN) 