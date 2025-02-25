class_name ItemPickup
extends Area2D

signal picked_up(item_data)

@export var item_data: ItemData
@export var auto_pickup: bool = true
@export var pickup_sound: AudioStream
@export var pickup_effect: PackedScene
@export var floating_enabled: bool = true
@export var floating_amplitude: float = 4.0
@export var floating_frequency: float = 2.0

var _initial_y: float
var _time: float = 0.0
var _interactable: bool = true

func _ready() -> void:
    if floating_enabled:
        _initial_y = global_position.y
    
    # Connect signals
    connect("body_entered", _on_body_entered)
    
    # Setup sprite based on item data
    if item_data:
        var icon_sprite = $Sprite2D
        if icon_sprite:
            icon_sprite.texture = item_data.icon
    
    # Setup collision shape if it exists
    var collision = $CollisionShape2D
    if collision and not collision.shape:
        var shape = CircleShape2D.new()
        shape.radius = 20.0
        collision.shape = shape

func _process(delta: float) -> void:
    if floating_enabled:
        _time += delta
        var new_y = _initial_y + sin(_time * floating_frequency) * floating_amplitude
        global_position.y = new_y

func pickup(collector: Node2D) -> void:
    if not _interactable:
        return
        
    _interactable = false
    
    # Emit signal with item data
    emit_signal("picked_up", item_data)
    
    # Play sound if available
    if pickup_sound:
        var audio_player = AudioStreamPlayer2D.new()
        get_parent().add_child(audio_player)
        audio_player.stream = pickup_sound
        audio_player.global_position = global_position
        audio_player.play()
        
        # Remove audio player when done
        await audio_player.finished
        audio_player.queue_free()
    
    # Spawn effect if available
    if pickup_effect:
        var effect = pickup_effect.instantiate()
        get_parent().add_child(effect)
        effect.global_position = global_position
    
    # Remove the item from the scene
    queue_free()

func _on_body_entered(body: Node2D) -> void:
    if not auto_pickup or not _interactable:
        return
        
    if body.is_in_group("player"):
        # Check if player has inventory
        if body.has_method("add_item_to_inventory"):
            var success = body.add_item_to_inventory(item_data)
            if success:
                pickup(body)
        else:
            # Just pickup anyway if no inventory system
            pickup(body)

# Use this to interact with the item when auto_pickup is disabled
func interact(interactor: Node2D) -> void:
    if not _interactable:
        return
        
    if interactor.is_in_group("player"):
        # Check if player has inventory
        if interactor.has_method("add_item_to_inventory"):
            var success = interactor.add_item_to_inventory(item_data)
            if success:
                pickup(interactor)
        else:
            # Just pickup anyway if no inventory system
            pickup(interactor) 