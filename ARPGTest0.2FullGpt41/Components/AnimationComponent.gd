# AnimationComponent.gd
class_name AnimationComponent
extends Node

signal animation_started(name)
signal animation_finished(name)

func play_animation(state: String) -> void:
    # [ANIMATION_LOGIC]
    emit_signal("animation_started", state)
    # after animation ends:
    emit_signal("animation_finished", state) 