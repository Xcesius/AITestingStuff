class_name EnemyAttackState
extends State

@onready var enemy: EnemyController = owner as EnemyController
@onready var attack_timer: Timer = $AttackTimer
@onready var attack_cooldown: Timer = $AttackCooldown

func _ready() -> void:
    attack_timer = Timer.new()
    attack_timer.one_shot = true
    attack_timer.timeout.connect(_on_attack_timer_timeout)
    add_child(attack_timer)
    
    attack_cooldown = Timer.new()
    attack_cooldown.one_shot = true
    attack_cooldown.timeout.connect(_on_attack_cooldown_timeout)
    add_child(attack_cooldown)

func enter() -> void:
    if attack_cooldown.time_left > 0:
        get_parent().transition_to("chase")
        return
    
    enemy.animation_player.play("attack")
    attack_timer.start(0.3)  # Attack animation duration

func exit() -> void:
    attack_timer.stop()

func update(_delta: float) -> void:
    if not enemy.target or not enemy.can_attack_target():
        get_parent().transition_to("chase")

func perform_attack() -> void:
    if enemy.target and enemy.target.has_method("take_damage"):
        enemy.target.take_damage(enemy.stats.attack_damage)
    
    attack_cooldown.start(1.0 / enemy.stats.attack_speed)

func _on_attack_timer_timeout() -> void:
    perform_attack()
    get_parent().transition_to("chase")

func _on_attack_cooldown_timeout() -> void:
    if enemy.can_attack_target():
        get_parent().transition_to("attack") 