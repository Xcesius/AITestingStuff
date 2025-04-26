# Components/AdditionalComponents.gd
# This file contains scaffolding for additional ARPG components

# MovementComponent.gd
class_name MovementComponent
extends Node

@export var move_speed: float = 100.0
signal moved(direction, delta)

func move(direction: Vector2, delta: float) -> void:
    # [MOVEMENT_LOGIC] e.g., move_and_slide
    emit_signal("moved", direction, delta)

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

# InteractionComponent.gd
class_name InteractionComponent
extends Node

signal interacted(target)

func interact(target: Node) -> void:
    # [INTERACTION_LOGIC]
    emit_signal("interacted", target)

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

# ExperienceComponent.gd
class_name ExperienceComponent
extends Node

@export var current_exp: int = 0
@export var exp_to_next_level: int = 100
signal leveled_up(new_level)

func add_experience(amount: int) -> void:
    current_exp += amount
    while current_exp >= exp_to_next_level:
        current_exp -= exp_to_next_level
        # [LEVEL_UP_LOGIC]
        emit_signal("leveled_up", get("level") + 1)

# EquipmentComponent.gd
class_name EquipmentComponent
extends Node

var equipped_items: Dictionary = {} # slot_name -> item_data
signal equipped(item, slot)
signal unequipped(item, slot)

func equip(item, slot: String) -> void:
    equipped_items[slot] = item
    # [EQUIPMENT_LOGIC]
    emit_signal("equipped", item, slot)

func unequip(slot: String) -> void:
    var item = equipped_items.get(slot, null)
    if item:
        equipped_items.erase(slot)
        # [UNEQUIP_LOGIC]
        emit_signal("unequipped", item, slot)

# TargetingComponent.gd
class_name TargetingComponent
extends Node

signal target_changed(new_target)
var current_target: Node = null

func set_target(target: Node) -> void:
    current_target = target
    emit_signal("target_changed", target)

# AudioComponent.gd
class_name AudioComponent
extends Node

@export var sound_effects: Dictionary = {} # name -> AudioStream

func play_sound(name: String) -> void:
    if sound_effects.has(name):
        var player = AudioStreamPlayer.new()
        player.stream = sound_effects[name]
        add_child(player)
        player.play()

# SaveLoadComponent.gd
class_name SaveLoadComponent
extends Node

func save_state() -> Dictionary:
    # [SAVE_LOGIC]
    return {}

func load_state(data: Dictionary) -> void:
    # [LOAD_LOGIC]
    pass 