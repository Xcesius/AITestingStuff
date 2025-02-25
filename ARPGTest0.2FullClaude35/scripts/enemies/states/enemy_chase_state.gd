class_name EnemyChaseState
extends State

@onready var enemy: EnemyController = owner as EnemyController
@onready var path_update_timer: Timer = $PathUpdateTimer

func _ready() -> void:
    path_update_timer = Timer.new()
    path_update_timer.wait_time = 0.5  # Update path every half second
    path_update_timer.timeout.connect(_on_path_update_timer_timeout)
    add_child(path_update_timer)

func enter() -> void:
    enemy.animation_player.play("walk")
    path_update_timer.start()
    enemy.update_path_to_target()

func exit() -> void:
    path_update_timer.stop()

func physics_update(delta: float) -> void:
    if not enemy.target:
        get_parent().transition_to("idle")
        return
    
    if enemy.can_attack_target():
        get_parent().transition_to("attack")
        return
    
    enemy.move_to_target(delta)

func _on_path_update_timer_timeout() -> void:
    enemy.update_path_to_target() 