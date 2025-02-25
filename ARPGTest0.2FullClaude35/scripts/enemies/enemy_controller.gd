class_name EnemyController
extends CharacterBody2D

signal died

@export var stats: CharacterStats
@export var detection_radius: float = 300.0
@export var attack_range: float = 50.0

@onready var state_machine: StateMachine = $StateMachine
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var player_detection: Area2D = $PlayerDetection

var target: Node2D = null
var path: Array = []
var path_index: int = 0

func _ready() -> void:
    if not stats:
        stats = CharacterStats.new()
    
    stats.died.connect(_on_died)
    player_detection.body_entered.connect(_on_player_detected)
    player_detection.body_exited.connect(_on_player_lost)

func _physics_process(_delta: float) -> void:
    if not stats.is_alive():
        return

func take_damage(amount: float) -> void:
    stats.take_damage(amount)
    state_machine.transition_to("hurt")

func move_to_target(delta: float) -> void:
    if not target or not navigation_agent.is_navigation_finished():
        return
    
    var direction = global_position.direction_to(navigation_agent.get_next_path_position())
    velocity = direction * stats.move_speed
    move_and_slide()
    
    # Update sprite direction
    sprite.flip_h = velocity.x < 0

func update_path_to_target() -> void:
    if target:
        navigation_agent.target_position = target.global_position

func _on_player_detected(body: Node2D) -> void:
    if body.is_in_group("player"):
        target = body
        state_machine.transition_to("chase")

func _on_player_lost(body: Node2D) -> void:
    if body == target:
        target = null
        state_machine.transition_to("idle")

func _on_died() -> void:
    state_machine.transition_to("dead")
    emit_signal("died")

func can_attack_target() -> bool:
    return target and global_position.distance_to(target.global_position) <= attack_range 