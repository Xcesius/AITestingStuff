# StatusEffectComponent.gd
class_name StatusEffectComponent
extends Node

var effects: Array = [] # List of active effects
signal effect_applied(effect)
signal effect_removed(effect)

func apply_effect(effect) -> void:
    effects.append(effect)
    # [EFFECT_APPLY_LOGIC]
    emit_signal("effect_applied", effect)

func remove_effect(effect) -> void:
    effects.erase(effect)
    # [EFFECT_REMOVE_LOGIC]
    emit_signal("effect_removed", effect) 