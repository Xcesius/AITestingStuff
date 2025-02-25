class_name TreasureChest
extends StaticBody2D

signal opened
signal item_dropped(item_data, position)

@export var loot_table: LootTable
@export var min_items: int = 1
@export var max_items: int = 3
@export var item_pickup_scene: PackedScene
@export var open_sound: AudioStream
@export var open_effect: PackedScene
@export var spread_distance: float = 50.0
@export var auto_open: bool = false

var _opened: bool = false
var _level: int = 1
var _interactable: bool = true

func _ready() -> void:
    if auto_open:
        connect("body_entered", _on_body_entered)

func set_level(level: int) -> void:
    _level = level

func open() -> void:
    if _opened or not _interactable:
        return
    
    _opened = true
    _interactable = false
    
    # Change sprite to opened state
    var sprite = $Sprite2D
    if sprite and sprite.has_method("play"):
        sprite.play("open")
    
    # Play sound if available
    if open_sound:
        var audio_player = AudioStreamPlayer2D.new()
        add_child(audio_player)
        audio_player.stream = open_sound
        audio_player.play()
    
    # Play effect if available
    if open_effect:
        var effect = open_effect.instantiate()
        get_parent().add_child(effect)
        effect.global_position = global_position
    
    # Generate loot
    generate_loot()
    
    # Emit opened signal
    emit_signal("opened")

func generate_loot() -> void:
    if not loot_table:
        push_warning("No loot table assigned to chest!")
        return
    
    if not item_pickup_scene:
        push_warning("No item pickup scene assigned to chest!")
        return
    
    # Determine how many items to drop
    var item_count = randi_range(min_items, max_items)
    
    # Scale item count with level
    item_count += floor(_level / 3) # Every 3 levels add an extra item
    
    # Generate items from loot table
    var items = []
    for i in range(item_count):
        var item = loot_table.roll_item(_level)
        if item:
            items.append(item)
    
    # Spawn item pickups
    for i in range(items.size()):
        var item = items[i]
        
        # Calculate position with some spread
        var angle = 2 * PI * i / items.size()
        var offset = Vector2(cos(angle), sin(angle)) * spread_distance
        var pos = global_position + offset
        
        # Create the pickup
        var pickup = item_pickup_scene.instantiate()
        get_parent().add_child(pickup)
        pickup.global_position = pos
        
        # Set the item data
        if pickup is ItemPickup:
            pickup.item_data = item
        
        # Emit signal
        emit_signal("item_dropped", item, pos)

func _on_body_entered(body: Node2D) -> void:
    if not auto_open or _opened or not _interactable:
        return
    
    if body.is_in_group("player"):
        open()

# Use this to interact with the chest when auto_open is disabled
func interact(interactor: Node2D) -> void:
    if _opened or not _interactable:
        return
    
    if interactor.is_in_group("player"):
        open() 