class_name PlayerAttackState
extends State

@onready var player: PlayerController = owner as PlayerController
@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
    attack_timer = Timer.new()
    attack_timer.one_shot = true
    attack_timer.timeout.connect(_on_attack_timer_timeout)
    add_child(attack_timer)

func enter() -> void:
    player.animation_player.play("attack")
    attack_timer.start(1.0 / player.stats.attack_speed)
    check_for_hits()

func check_for_hits() -> void:
    var attack_area = player.get_node("AttackArea") as Area2D
    if not attack_area:
        push_warning("AttackArea node not found on player")
        return
    
    for body in attack_area.get_overlapping_bodies():
        if body.has_method("take_damage") and body != player:
            body.take_damage(player.stats.attack_damage)

func _on_attack_timer_timeout() -> void:
    if Input.is_action_pressed("attack"):
        enter()  # Chain into another attack
    else:
        get_parent().transition_to("idle")

func update(_delta: float) -> void:
    # Can add movement during attack if desired
    pass

func exit() -> void:
    attack_timer.stop() 