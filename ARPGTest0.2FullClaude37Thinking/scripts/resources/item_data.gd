class_name ItemData
extends Resource

enum ItemType { WEAPON, ARMOR, CONSUMABLE, QUEST, MATERIAL }
enum EquipSlot { NONE, WEAPON, HEAD, BODY, ACCESSORY }

@export var id: String = "item_001"
@export var name: String = "Item Name"
@export var description: String = "Item description"
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.MATERIAL
@export var equip_slot: EquipSlot = EquipSlot.NONE
@export var stack_size: int = 1
@export var value: int = 0

# Type-specific properties
@export_group("Weapon Properties")
@export var damage: int = 0
@export var attack_speed: float = 1.0
@export var attack_range: float = 1.0

@export_group("Armor Properties")
@export var defense: int = 0
@export var resistance: Dictionary = {} # Resistance to specific damage types

@export_group("Consumable Properties")
@export var health_restore: int = 0
@export var mana_restore: int = 0
@export var stamina_restore: int = 0
@export var effect_id: String = ""
@export var effect_duration: float = 0.0
@export var effect_strength: float = 0.0

@export_group("Quest Properties")
@export var quest_id: String = ""

func _init(p_id: String = "item_001", p_name: String = "Item Name", p_description: String = "", 
          p_icon: Texture2D = null, p_item_type: ItemType = ItemType.MATERIAL) -> void:
    id = p_id
    name = p_name
    description = p_description
    icon = p_icon
    item_type = p_item_type
    
    # Set default stack size based on item type
    match item_type:
        ItemType.WEAPON, ItemType.ARMOR:
            stack_size = 1
        ItemType.CONSUMABLE:
            stack_size = 10
        ItemType.QUEST:
            stack_size = 1
        ItemType.MATERIAL:
            stack_size = 99

func use(character = null) -> bool:
    if character == null:
        return false
    
    match item_type:
        ItemType.CONSUMABLE:
            return _use_consumable(character)
        ItemType.WEAPON, ItemType.ARMOR:
            return _equip(character)
        _:
            return false

func _use_consumable(character) -> bool:
    var used = false
    
    # Apply healing if applicable
    if health_restore > 0 and character.has_method("heal"):
        character.heal(health_restore)
        used = true
    
    # Apply mana restore if applicable
    if mana_restore > 0 and character.has_method("restore_mana"):
        character.restore_mana(mana_restore)
        used = true
    
    # Apply stamina restore if applicable
    if stamina_restore > 0 and character.has_method("restore_stamina"):
        character.restore_stamina(stamina_restore)
        used = true
    
    # Apply status effect if applicable
    if effect_id != "" and effect_duration > 0 and character.has_method("apply_effect"):
        character.apply_effect(effect_id, effect_strength, effect_duration)
        used = true
    
    return used

func _equip(character) -> bool:
    # Check if character has an equipment system
    if not character.has_method("equip_item"):
        return false
    
    return character.equip_item(self)

# Get a dictionary of the item's stats for display
func get_stats_display() -> Dictionary:
    var stats = {}
    
    match item_type:
        ItemType.WEAPON:
            stats["Damage"] = str(damage)
            stats["Attack Speed"] = str(attack_speed)
            stats["Range"] = str(attack_range)
        ItemType.ARMOR:
            stats["Defense"] = str(defense)
            for damage_type in resistance:
                stats["Resist " + damage_type] = str(resistance[damage_type]) + "%"
        ItemType.CONSUMABLE:
            if health_restore > 0:
                stats["Heal"] = str(health_restore)
            if mana_restore > 0:
                stats["Mana"] = str(mana_restore)
            if stamina_restore > 0:
                stats["Stamina"] = str(stamina_restore)
            if effect_id != "":
                stats["Effect"] = effect_id
                stats["Duration"] = str(effect_duration) + "s"
    
    return stats

# Create a copy of this item with specified property changes
func create_variant(properties: Dictionary) -> ItemData:
    var new_item = self.duplicate()
    
    for property in properties:
        if new_item.get(property) != null:
            new_item.set(property, properties[property])
    
    return new_item 