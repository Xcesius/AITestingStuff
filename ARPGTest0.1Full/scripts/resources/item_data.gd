extends Resource
class_name ItemData

enum ItemType {
    WEAPON,
    ARMOR,
    CONSUMABLE,
    MATERIAL,
    QUEST
}

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType
@export var stackable: bool = false
@export var max_stack: int = 1

# Stats modifications
@export var health_mod: float = 0.0
@export var attack_mod: float = 0.0
@export var defense_mod: float = 0.0
@export var speed_mod: float = 0.0

# For equipment
@export var equippable: bool = false
@export var equipment_slot: String = ""

func can_stack_with(other_item: ItemData) -> bool:
    return stackable and id == other_item.id

func is_equipment() -> bool:
    return item_type == ItemType.WEAPON or item_type == ItemType.ARMOR

func apply_effects(stats: CharacterStats) -> void:
    stats.max_health += health_mod
    stats.attack += attack_mod
    stats.defense += defense_mod
    stats.speed += speed_mod

func remove_effects(stats: CharacterStats) -> void:
    stats.max_health -= health_mod
    stats.attack -= attack_mod
    stats.defense -= defense_mod
    stats.speed -= speed_mod 