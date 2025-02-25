class_name EnemyAttackState
extends EnemyState

# Attack behavior settings
@export var damage_frame_time: float = 0.3
@export var attack_range: float = 30.0

# State variables
var attack_finished: bool = false
var damage_applied: bool = false

func enter() -> void:
    super.enter()
    
    # Set attack flags
    enemy.is_attacking = true
    attack_finished = false
    damage_applied = false
    
    # Play attack animation based on facing direction
    _play_attack_animation()
    
    # Connect to animation signals
    enemy.sprite.animation_finished.connect(_on_animation_finished)

func exit() -> void:
    # Reset attack state
    enemy.is_attacking = false
    
    # Disconnect from animation signals
    if enemy.sprite.animation_finished.is_connected(_on_animation_finished):
        enemy.sprite.animation_finished.disconnect(_on_animation_finished)

func process(delta: float) -> void:
    super.process(delta)
    
    # Apply damage at the appropriate time during the animation
    if not damage_applied and time_in_state >= damage_frame_time:
        _apply_damage()
        damage_applied = true
    
    # Check if we should exit the attack state
    if attack_finished:
        if enemy.target and enemy.can_see_target():
            if enemy.can_attack_target():
                # Can attack again, but need a cooldown
                if enemy.attack_timer <= 0:
                    change_state("attack")
                else:
                    change_state("chase")
            else:
                change_state("chase")
        else:
            change_state("idle")

func physics_process(delta: float) -> void:
    # Apply friction to slow down movement during attack
    enemy.velocity = enemy.velocity.move_toward(Vector2.ZERO, enemy.friction * delta)
    enemy.move_and_slide()

func _play_attack_animation() -> void:
    var facing = enemy.facing_direction
    var attack_anim = ""
    
    # Determine attack animation based on facing direction
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
    
    # Play the animation if it exists, otherwise fall back to basic attack
    if enemy.sprite.sprite_frames.has_animation(attack_anim):
        enemy.sprite.play(attack_anim)
    else:
        enemy.sprite.play("attack")

func _apply_damage() -> void:
    if not enemy.target:
        return
    
    var distance = enemy.global_position.distance_to(enemy.target.global_position)
    if distance <= attack_range:
        # Apply damage to the target if it can take damage
        if enemy.target.has_method("take_damage"):
            var attack_power = enemy.attack_damage
            if enemy.stats and enemy.stats.has_method("get_total_attack"):
                attack_power = enemy.stats.get_total_attack()
            
            enemy.target.take_damage(attack_power, enemy.global_position)

func _on_animation_finished() -> void:
    if enemy.sprite.animation.begins_with("attack"):
        attack_finished = true 