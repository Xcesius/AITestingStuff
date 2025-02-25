class_name DungeonExit
extends Area2D

signal player_entered

@export var next_level_delay: float = 0.5
@export var effect_scene: PackedScene

func _ready() -> void:
    connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        # Prevent multiple triggers
        disconnect("body_entered", _on_body_entered)
        
        # Play effect if available
        if effect_scene:
            var effect = effect_scene.instantiate()
            get_parent().add_child(effect)
            effect.global_position = global_position
        
        # Emit signal after delay
        var timer = get_tree().create_timer(next_level_delay)
        await timer.timeout
        emit_signal("player_entered") 