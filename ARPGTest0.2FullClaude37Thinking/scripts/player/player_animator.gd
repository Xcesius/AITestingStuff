class_name PlayerAnimator
extends Node

# Node references
@onready var sprite: AnimatedSprite2D
@onready var player: PlayerCharacter

# Animation state tracking
var current_animation: String = ""
var last_direction: Vector2 = Vector2.DOWN
var default_animation_speed: float = 1.0

# Signal connections
signal animation_finished(animation_name: String)

func _ready() -> void:
    # Get required node references
    player = get_parent() as PlayerCharacter
    sprite = player.get_node("Sprite") as AnimatedSprite2D
    
    if sprite == null:
        push_error("PlayerAnimator: Could not find AnimatedSprite2D node")
        return
    
    # Connect signals
    sprite.animation_finished.connect(func(): 
        animation_finished.emit(sprite.animation)
    )

func set_direction(direction: Vector2) -> void:
    if direction != Vector2.ZERO:
        last_direction = direction.normalized()

func play_idle() -> void:
    var anim_name = _get_directional_animation("idle")
    _play_animation(anim_name)

func play_walk() -> void:
    var anim_name = _get_directional_animation("walk")
    _play_animation(anim_name)

func play_attack(combo_count: int = 0) -> void:
    var weapon_type = _get_weapon_type()
    var base_name = weapon_type + "attack" if weapon_type != "" else "attack"
    var anim_name = _get_directional_animation(base_name)
    
    # Add combo number if greater than 0
    if combo_count > 0:
        anim_name += str(combo_count + 1)
    
    # Check if animation exists, otherwise fall back
    if not _animation_exists(anim_name):
        # Try without combo number
        anim_name = _get_directional_animation(base_name)
    
    _play_animation(anim_name)

func play_hurt() -> void:
    var anim_name = _get_directional_animation("hurt")
    _play_animation(anim_name)

func play_death() -> void:
    var anim_name = "death"
    
    # Try directional death if it exists
    var dir_death = _get_directional_animation("death")
    if _animation_exists(dir_death):
        anim_name = dir_death
    
    _play_animation(anim_name)

func _get_weapon_type() -> String:
    if player.has_method("get_equipped_item"):
        var weapon = player.get_equipped_item("weapon")
        if weapon != null and weapon is WeaponData:
            return weapon.weapon_type.to_lower() + "_"
    return ""

func _get_directional_animation(base_name: String) -> String:
    var direction = ""
    
    # Determine direction suffix based on last direction
    if abs(last_direction.x) > abs(last_direction.y):
        direction = "_right" if last_direction.x > 0 else "_left"
    else:
        direction = "_down" if last_direction.y > 0 else "_up"
    
    return base_name + direction

func _animation_exists(anim_name: String) -> bool:
    return sprite.sprite_frames != null and sprite.sprite_frames.has_animation(anim_name)

func _play_animation(anim_name: String) -> void:
    if current_animation == anim_name:
        return
    
    if _animation_exists(anim_name):
        sprite.play(anim_name)
        current_animation = anim_name
    else:
        # Fall back to default animation
        push_warning("Animation not found: " + anim_name)
        
        # Try to find a suitable fallback
        var fallback = "idle_down"
        if _animation_exists(fallback):
            sprite.play(fallback)
            current_animation = fallback 