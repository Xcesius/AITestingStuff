class_name EnemyAnimator
extends Node

# Node references
@onready var sprite: AnimatedSprite2D
@onready var enemy: EnemyCharacter

# Animation state tracking
var current_animation: String = ""
var last_direction: Vector2 = Vector2.DOWN

# Signal connections
signal animation_finished(animation_name: String)

func _ready() -> void:
    # Get required node references
    enemy = get_parent() as EnemyCharacter
    sprite = enemy.get_node("Sprite") as AnimatedSprite2D
    
    if sprite == null:
        push_error("EnemyAnimator: Could not find AnimatedSprite2D node")
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

func play_chase() -> void:
    # Try chase animation if it exists, otherwise fall back to walk
    var anim_name = _get_directional_animation("chase")
    if not _animation_exists(anim_name):
        anim_name = _get_directional_animation("walk")
    _play_animation(anim_name)

func play_attack() -> void:
    var anim_name = _get_directional_animation("attack")
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
        push_warning("Animation not found for enemy: " + anim_name)
        
        # Try to find a suitable fallback
        var fallback = "idle_down"
        if _animation_exists(fallback):
            sprite.play(fallback)
            current_animation = fallback 