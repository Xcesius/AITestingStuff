# ItemData.gd
extends Resource
class_name ItemData

@export var name: String = "[ITEM_NAME]"
@export var description: String = "[ITEM_DESCRIPTION]"
@export var icon: Texture2D = preload("[PATH_TO_ITEM_ICON_TEXTURE]")
@export var type: String = "[ITEM_TYPE]" # e.g., "consumable", "equipment"
@export var stat_bonuses: Dictionary = {} 