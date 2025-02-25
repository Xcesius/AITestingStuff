class_name WeaponPickup
extends ItemPickup

@export var weapon_data: WeaponData
@export var preview_rotation_speed: float = 1.0

func _ready() -> void:
    super._ready()
    
    # Override item_data with weapon_data if provided
    if weapon_data and not item_data:
        item_data = weapon_data

func _process(delta: float) -> void:
    super._process(delta)
    
    # Add slight rotation to weapon pickups for visual appeal
    if _interactable:
        var sprite = $Sprite2D
        if sprite:
            sprite.rotation += delta * preview_rotation_speed

# Override to handle weapon-specific behavior
func pickup(collector: Node2D) -> void:
    if not _interactable:
        return
    
    # If collector is player and has an equipment system, equip the weapon
    if collector.is_in_group("player") and collector.has_method("equip_weapon"):
        var success = collector.equip_weapon(weapon_data)
        if success:
            _interactable = false
            emit_signal("picked_up", weapon_data)
            
            # Play effects and cleanup
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
        # Fall back to standard item pickup behavior
        super.pickup(collector) 