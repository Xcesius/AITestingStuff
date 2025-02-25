class_name ItemData
extends Resource

enum ItemType {
    WEAPON,
    ARMOR,
    CONSUMABLE,
    MATERIAL,
    KEY_ITEM
}

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var type: ItemType
@export var stackable: bool = false
@export var max_stack_size: int = 1

# Stats modifiers
@export var health_mod: float = 0.0
@export var attack_mod: float = 0.0
@export var defense_mod: float = 0.0
@export var speed_mod: float = 0.0

# For consumables
@export var use_effect: String = ""
@export var use_value: float = 0.0

func can_stack_with(other: ItemData) -> bool:
    return stackable and other.id == id and other.stackable

func apply_effect(target: Node) -> void:
    match type:
        ItemType.CONSUMABLE:
            match use_effect:
                "heal":
                    if target.has_method("heal"):
                        target.heal(use_value)
                "temp_attack_boost":
                    if target.has_method("modify_attack"):
                        target.modify_attack(use_value, 10.0)  # 10 second duration
                # Add more effects as needed
        ItemType.WEAPON, ItemType.ARMOR:
            # These are handled by the equipment system
            pass 