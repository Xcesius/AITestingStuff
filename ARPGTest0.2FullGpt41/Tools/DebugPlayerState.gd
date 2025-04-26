# DebugPlayerState.gd
tool
extends Node

func _draw():
    if Engine.is_editor_hint():
        var player = get_parent()
        if player and player.has_node("CollisionShape2D"):
            var shape = player.get_node("CollisionShape2D").shape
            if shape:
                draw_colored_polygon(shape.get_outline(), Color(0,1,0,0.5))
        # [STATE_TRANSITION_VISUALIZATION] 