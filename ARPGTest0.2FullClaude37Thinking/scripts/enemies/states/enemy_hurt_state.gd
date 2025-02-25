class_name EnemyHurtState
extends EnemyState

# Hurt behavior settings
@export var hurt_duration: float = 0.5
@export var flash_rate: float = 0.05

# State variables
var hurt_finished: bool = false
var flash_timer: float = 0.0
var flash_visible: bool = true

func enter() -> void:
    super.enter()
    
    # Reset state variables
    hurt_finished = false
    flash_timer = 0.0
    flash_visible = true
    
    # Apply knockback in _physics_process
    
    # Play hurt animation based on facing direction
    _play_hurt_animation()

func exit() -> void:
    # Ensure sprite is visible
    enemy.sprite.visible = true
    enemy.sprite.modulate = Color.WHITE

func process(delta: float) -> void:
    super.process(delta)
    
    # Flash effect
    flash_timer += delta
    if flash_timer >= flash_rate:
        flash_timer = 0.0
        flash_visible = !flash_visible
        enemy.sprite.visible = flash_visible
    
    # Transition out of hurt state when duration is over
    if time_in_state >= hurt_duration:
        hurt_finished = true
        
        # Return to appropriate state
        if enemy.target and enemy.can_see_target():
            change_state("chase")
        else:
            change_state("idle")

func physics_process(delta: float) -> void:
    # When hurt, only apply knockback or friction
    if enemy.knockback_timer > 0:
        # Knockback is handled in the main enemy script
        pass
    else:
        # Apply friction to slow down
        enemy.velocity = enemy.velocity.move_toward(Vector2.ZERO, enemy.friction * delta)
    
    enemy.move_and_slide()

func _play_hurt_animation() -> void:
    var facing = enemy.facing_direction
    var hurt_anim = ""
    
    # Determine hurt animation based on facing direction
    if abs(facing.x) > abs(facing.y):
        if facing.x > 0:
            hurt_anim = "hurt_right"
        else:
            hurt_anim = "hurt_left"
    else:
        if facing.y > 0:
            hurt_anim = "hurt_down"
        else:
            hurt_anim = "hurt_up"
    
    # Play the animation if it exists, otherwise fall back to basic hurt
    if enemy.sprite.sprite_frames.has_animation(hurt_anim):
        enemy.sprite.play(hurt_anim)
    else:
        # Fall back to a simple hurt animation or idle animation if hurt isn't available
        if enemy.sprite.sprite_frames.has_animation("hurt"):
            enemy.sprite.play("hurt")
        else:
            # If no hurt animation exists, apply visual effect to current animation
            enemy.sprite.modulate = Color(1, 0.5, 0.5)  # Red tint 