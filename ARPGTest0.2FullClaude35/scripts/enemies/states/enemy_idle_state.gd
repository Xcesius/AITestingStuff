class_name EnemyIdleState
extends State

@onready var enemy: EnemyController = owner as EnemyController
@onready var idle_timer: Timer = $IdleTimer

var patrol_points: Array[Vector2] = []
var current_patrol_point: int = 0

func _ready() -> void:
    idle_timer = Timer.new()
    idle_timer.one_shot = true
    idle_timer.timeout.connect(_on_idle_timer_timeout)
    add_child(idle_timer)
    
    # Generate some patrol points around spawn position
    generate_patrol_points()

func enter() -> void:
    enemy.animation_player.play("idle")
    idle_timer.start(randf_range(2.0, 4.0))

func exit() -> void:
    idle_timer.stop()

func generate_patrol_points() -> void:
    var spawn_pos = enemy.global_position
    var radius = 100.0
    var num_points = 4
    
    for i in range(num_points):
        var angle = (2 * PI * i) / num_points
        var point = spawn_pos + Vector2(cos(angle), sin(angle)) * radius
        patrol_points.append(point)

func _on_idle_timer_timeout() -> void:
    if enemy.target:
        get_parent().transition_to("chase")
    else:
        get_parent().transition_to("patrol") 