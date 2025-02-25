extends Node

signal game_paused(is_paused: bool)
signal game_over
signal level_started
signal level_completed

var player: Node2D
var current_level: Node2D
var is_game_paused: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func register_player(p_player: Node2D) -> void:
    player = p_player
    
func register_level(p_level: Node2D) -> void:
    current_level = p_level
    level_started.emit()

func pause_game() -> void:
    is_game_paused = true
    get_tree().paused = true
    game_paused.emit(true)

func resume_game() -> void:
    is_game_paused = false
    get_tree().paused = false
    game_paused.emit(false)

func toggle_pause() -> void:
    if is_game_paused:
        resume_game()
    else:
        pause_game()

func trigger_game_over() -> void:
    pause_game()
    game_over.emit()

func complete_level() -> void:
    level_completed.emit()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        toggle_pause() 