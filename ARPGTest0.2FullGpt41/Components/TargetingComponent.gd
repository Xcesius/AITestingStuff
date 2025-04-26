# TargetingComponent.gd
class_name TargetingComponent
extends Node

signal target_changed(new_target)
var current_target: Node = null

func set_target(target: Node) -> void:
    current_target = target
    emit_signal("target_changed", target) 