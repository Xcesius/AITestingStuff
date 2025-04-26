# PlayerCombat.gd
extends Node

@onready var attack_area = get_parent().get_node("AttackHitbox")
@onready var cooldown = get_parent().get_node("AttackCooldown")

func _ready():
    attack_area.connect("body_entered", Callable(self, "_on_attack_hit"))

func _on_attack_hit(body):
    if body.is_in_group("enemies"):
        body.take_damage([PLAYER_ATTACK_DAMAGE])
        # [ENEMY_HIT_EFFECTS]

func attack():
    if not cooldown.is_stopped():
        return
    attack_area.monitoring = true
    # [PLAYER_ATTACK_ANIMATION_TRIGGER]
    cooldown.start()
    await cooldown.timeout
    attack_area.monitoring = false 