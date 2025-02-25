class_name HealingItemPickup
extends ItemPickup

@export var heal_amount: int = 20
@export var healing_effect_scene: PackedScene
@export var use_immediately: bool = false

func _ready() -> void:
    super._ready()
    
    # Set item name based on heal amount if item_data doesn't have a name
    if item_data and item_data.name.is_empty():
        if heal_amount <= 10:
            item_data.name = "Small Health Potion"
        elif heal_amount <= 30:
            item_data.name = "Medium Health Potion"
        else:
            item_data.name = "Large Health Potion"

# Override pickup to allow immediate use
func pickup(collector: Node2D) -> void:
    if not _interactable:
        return
    
    # If use immediately is enabled and collector has health
    if use_immediately and collector.has_method("heal"):
        # Heal the collector
        collector.heal(heal_amount)
        
        # Play healing effect if available
        if healing_effect_scene:
            var effect = healing_effect_scene.instantiate()
            get_parent().add_child(effect)
            effect.global_position = collector.global_position
        
        # Standard pickup behavior for effects
        _interactable = false
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
    else:
        # Use standard item pickup behavior
        super.pickup(collector)

# Function to use the healing item
func use(user: Node2D) -> bool:
    if user.has_method("heal"):
        user.heal(heal_amount)
        
        # Play healing effect if available
        if healing_effect_scene:
            var effect = healing_effect_scene.instantiate()
            get_parent().add_child(effect)
            effect.global_position = user.global_position
            
        return true
    
    return false 