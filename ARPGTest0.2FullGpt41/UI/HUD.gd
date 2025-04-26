# HUD.gd
extends CanvasLayer

@onready var health_bar = $[HEALTH_BAR_NODE_NAME]
@onready var health_label = $[HEALTH_LABEL_NODE_NAME]

func update_health(current, max):
    health_bar.value = current
    health_bar.max_value = max
    health_label.text = "%d / %d" % [current, max] 