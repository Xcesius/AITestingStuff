# EnemyCombat.gd
extends Node2D

func on_death():
    $AnimatedSprite2D.play("death")  # Replace with actual death animation name
    if has_node("/root/LootManager"):
        get_node("/root/LootManager").drop_loot(position, "[PATH_TO_LOOT_TABLE_RESOURCE]")
    queue_free() 