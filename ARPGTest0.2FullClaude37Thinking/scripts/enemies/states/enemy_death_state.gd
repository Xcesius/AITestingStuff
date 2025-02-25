class_name EnemyDeathState
extends EnemyState

# Death behavior settings
@export var death_fade_time: float = 1.0
@export var drop_experience: bool = true
@export var play_death_sound: bool = true

# State variables
var death_animation_finished: bool = false
var fade_started: bool = false

func enter() -> void:
    super.enter()
    
    # Play death animation
    _play_death_animation()
    
    # Connect to animation finished signal
    enemy.sprite.animation_finished.connect(_on_animation_finished)
    
    # Disable collisions
    enemy.set_collision_layer_value(1, false)
    enemy.set_collision_mask_value(1, false)
    
    # Stop any movement
    enemy.velocity = Vector2.ZERO
    
    # Emit died signal
    enemy.emit_signal("enemy_died", enemy, enemy.global_position)
    
    # Drop loot
    enemy.drop_loot()
    
    # Award experience to the player if it was the source of damage
    if drop_experience and enemy.target and enemy.target.has_method("add_experience"):
        enemy.target.add_experience(enemy.experience_value)
    
    # Play death sound if enabled
    if play_death_sound:
        # This would play a sound if we had implemented the audio system
        # For now it's a placeholder
        pass

func exit() -> void:
    # Disconnect from animation signal
    if enemy.sprite.animation_finished.is_connected(_on_animation_finished):
        enemy.sprite.animation_finished.disconnect(_on_animation_finished)

func process(delta: float) -> void:
    super.process(delta)
    
    # If death animation is finished, start fading out
    if death_animation_finished and not fade_started:
        fade_started = true
        _start_fade_out()
    
    # No state transitions since this is the final state

func physics_process(delta: float) -> void:
    # No physics processing in death state
    pass

func _play_death_animation() -> void:
    var facing = enemy.facing_direction
    var death_anim = ""
    
    # Determine death animation based on facing direction
    if abs(facing.x) > abs(facing.y):
        if facing.x > 0:
            death_anim = "death_right"
        else:
            death_anim = "death_left"
    else:
        if facing.y > 0:
            death_anim = "death_down"
        else:
            death_anim = "death_up"
    
    # Play the animation if it exists, otherwise fall back to basic death
    if enemy.sprite.sprite_frames.has_animation(death_anim):
        enemy.sprite.play(death_anim)
    else:
        if enemy.sprite.sprite_frames.has_animation("death"):
            enemy.sprite.play("death")
        else:
            # If no death animation exists, just make the sprite fade out
            enemy.sprite.modulate = Color(0.7, 0.7, 0.7, 1.0)  # Gray tint
            death_animation_finished = true

func _start_fade_out() -> void:
    # Create a tween to fade out the enemy sprite
    var tween = create_tween()
    tween.tween_property(enemy.sprite, "modulate", Color(1, 1, 1, 0), death_fade_time)
    tween.tween_callback(func(): enemy.queue_free())

func _on_animation_finished() -> void:
    if enemy.sprite.animation.begins_with("death"):
        death_animation_finished = true 