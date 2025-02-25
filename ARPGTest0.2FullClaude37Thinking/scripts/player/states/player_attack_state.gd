class_name PlayerAttackState
extends PlayerState

var attack_finished: bool = false
var can_combo: bool = false
var combo_count: int = 0
var max_combo: int = 3

func _ready() -> void:
    state_name = "attack"

func enter() -> void:
    attack_finished = false
    player.is_attacking = true
    
    # Play attack animation based on facing direction
    _play_attack_animation()
    
    # Connect to animation finished signal
    player.sprite.animation_finished.connect(_on_animation_finished)
    
    # Apply attack logic
    _apply_attack()

func exit() -> void:
    attack_finished = false
    can_combo = false
    
    # Disconnect from animation signal to prevent memory leaks
    if player.sprite.animation_finished.is_connected(_on_animation_finished):
        player.sprite.animation_finished.disconnect(_on_animation_finished)
    
    # Reset attacking flag only if we're not going into another attack state (combo)
    if state_machine.current_state.name.to_lower() != "attack":
        player.is_attacking = false
        combo_count = 0

func process(delta: float) -> void:
    # Nothing special in process for attack state
    pass

func physics_process(delta: float) -> void:
    # Apply friction to slow down movement during attack
    player.velocity = player.velocity.move_toward(Vector2.ZERO, player.friction * delta)
    player.move_and_slide()
    
    # Check if attack is finished and we should return to idle
    if attack_finished and not can_combo:
        change_state("idle")

func handle_input(event: InputEvent) -> void:
    # Check for combo attack input
    if event.is_action_pressed("attack") and can_combo and combo_count < max_combo:
        # Reset for next attack in combo
        attack_finished = false
        can_combo = false
        combo_count += 1
        
        # Play next attack animation
        _play_attack_animation()
        
        # Apply attack logic for next hit
        _apply_attack()
        
        get_viewport().set_input_as_handled()

func _play_attack_animation() -> void:
    var facing = player.facing_direction
    var attack_anim = ""
    
    # Check if player has a weapon equipped and use weapon-specific animations if available
    var weapon = null
    if player.has_method("get_equipped_item"):
        weapon = player.get_equipped_item("weapon")
    
    # Build animation name based on weapon type and direction
    if weapon != null and weapon is WeaponData:
        var weapon_type = weapon.weapon_type.to_lower()
        
        # Determine attack animation based on facing direction and weapon type
        if abs(facing.x) > abs(facing.y):
            if facing.x > 0:
                attack_anim = weapon_type + "_attack_right"
            else:
                attack_anim = weapon_type + "_attack_left"
        else:
            if facing.y > 0:
                attack_anim = weapon_type + "_attack_down"
            else:
                attack_anim = weapon_type + "_attack_up"
    else:
        # Default unarmed animation if no weapon equipped
        if abs(facing.x) > abs(facing.y):
            if facing.x > 0:
                attack_anim = "attack_right"
            else:
                attack_anim = "attack_left"
        else:
            if facing.y > 0:
                attack_anim = "attack_down"
            else:
                attack_anim = "attack_up"
    
    # Add combo number for multiple attack animations
    if combo_count > 0:
        attack_anim += str(combo_count + 1)
    
    # Play the animation if it exists, otherwise fall back to basic attack
    if player.sprite.sprite_frames.has_animation(attack_anim):
        player.sprite.play(attack_anim)
    else:
        # Try without combo number
        attack_anim = attack_anim.split(str(combo_count + 1))[0]
        if player.sprite.sprite_frames.has_animation(attack_anim):
            player.sprite.play(attack_anim)
        else:
            # Fall back to default attack animation
            var default_anim = "attack_" + ("right" if facing.x > 0 else "left" if facing.x < 0 else "down" if facing.y > 0 else "up")
            if player.sprite.sprite_frames.has_animation(default_anim):
                player.sprite.play(default_anim)

func _apply_attack() -> void:
    # Get attack hitbox
    var hitbox = player.hitbox
    if not hitbox:
        return
    
    # Position hitbox based on facing direction and weapon (if equipped)
    var facing = player.facing_direction
    var weapon = null
    var attack_range = 1.0
    var attack_width = 1.0
    
    # Get weapon data if equipped
    if player.has_method("get_equipped_item"):
        weapon = player.get_equipped_item("weapon")
        if weapon != null and weapon is WeaponData:
            attack_range = weapon.attack_range
            attack_width = weapon.attack_width
    
    # Adjust hitbox position and size based on player's facing direction and weapon stats
    var hitbox_shape = hitbox.get_node("CollisionShape2D") as CollisionShape2D
    if hitbox_shape:
        if abs(facing.x) > abs(facing.y):
            # Horizontal attack
            hitbox_shape.shape.size = Vector2(32 * attack_range, 16 * attack_width)
            hitbox_shape.position.x = facing.x * 16 * attack_range
            hitbox_shape.position.y = 0
        else:
            # Vertical attack
            hitbox_shape.shape.size = Vector2(16 * attack_width, 32 * attack_range)
            hitbox_shape.position.x = 0
            hitbox_shape.position.y = facing.y * 16 * attack_range
    
    # Get all bodies in the hitbox
    var bodies = hitbox.get_overlapping_bodies()
    for body in bodies:
        if body.is_in_group("enemies") and body.has_method("take_damage"):
            # Use weapon damage calculation if available
            var damage = player.calculate_weapon_damage() if player.has_method("calculate_weapon_damage") else player.stats.get_total_attack()
            body.take_damage(damage, player.global_position)

func _on_animation_finished() -> void:
    if player.sprite.animation.begins_with("attack") or player.sprite.animation.contains("_attack_"):
        attack_finished = true
        
        # Allow combo for a short window
        can_combo = true
        
        # Start a timer to disable combo if not used
        await get_tree().create_timer(0.3).timeout
        can_combo = false
        
        # If combo window expired and no new attack, return to idle
        if attack_finished and state_machine.current_state == self:
            change_state("idle") 