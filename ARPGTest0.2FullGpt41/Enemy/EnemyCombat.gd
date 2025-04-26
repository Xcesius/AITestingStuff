# EnemyCombat.gd
extends Node

@onready var attack_area = get_parent().get_node("AttackHitbox")
@onready var cooldown = get_parent().get_node("AttackCooldown")
@export var loot_table: Resource # [PATH_TO_LOOT_TABLE_RESOURCE]

func _ready():
    attack_area.connect("body_entered", Callable(self, "_on_attack_hit"))

func _on_attack_hit(body):
    if body.is_in_group("player"):
        body.take_damage([ENEMY_ATTACK_DAMAGE])
        # [PLAYER_HIT_EFFECTS]

func attack():
    if not cooldown.is_stopped():
        return
    attack_area.monitoring = true
    # [ENEMY_ATTACK_ANIMATION_TRIGGER]
    cooldown.start()
    await cooldown.timeout
    attack_area.monitoring = false

func on_death():
    # [ENEMY_DEATH_EFFECTS]
    _drop_loot()
    get_parent().queue_free()

func _drop_loot():
    if loot_table:
        var loot = loot_table.get_random_loot()
        if loot:
            var item = load("res://Items/ItemPickup.tscn").instantiate()
            item.set_item_data(loot)
            get_tree().current_scene.add_child(item)
            item.global_position = get_parent().global_position 