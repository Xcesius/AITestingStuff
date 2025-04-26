# InteractionComponent.gd
class_name InteractionComponent
extends Node

signal interacted(target)

func interact(target: Node) -> void:
    # [INTERACTION_LOGIC]
    emit_signal("interacted", target) 