class_name EnemyCharacter
extends CharacterBody2D

signal health_changed(current_health, max_health)
signal enemy_died(enemy, position)

# Node references
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var state_machine: EnemyStateMachine = $StateMachine
@onready var detection_area: Area2D = $DetectionArea
@onready var hitbox: Area2D = $HitBox
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animator: EnemyAnimator = $Animator

# Resources
@export var stats: Resource
@export var loot_table: LootTable

# Movement variables
@export var move_speed: float = 60.0
@export var acceleration: float = 400.0
@export var friction: float = 600.0
@export var wander_radius: float = 100.0
@export var chase_distance: float = 200.0
@export var attack_distance: float = 30.0

# Combat variables
@export var attack_cooldown: float = 1.0
@export var attack_damage: int = 5
@export var experience_value: int = 10
var attack_timer: float = 0.0
var is_attacking: bool = false
var target: Node2D
var home_position: Vector2
var facing_direction: Vector2 = Vector2.DOWN

# State tracking
var is_alive: bool = true
var is_invincible: bool = false
var invincibility_timer: float = 0.0
var knockback_vector: Vector2 = Vector2.ZERO
var knockback_strength: float = 120.0
var knockback_duration: float = 0.2
var knockback_timer: float = 0.0

func _ready() -> void:
    # Initialize stats
    if stats == null:
        # Default stats if none provided
        stats = CharacterStats.new(30, 5, 0, 1.0, 1.0)
    
    # Set initial position as home
    home_position = global_position
    
    # Connect signals
    stats.connect("health_depleted", Callable(self, "_on_health_depleted"))
    detection_area.body_entered.connect(_on_detection_area_body_entered)
    detection_area.body_exited.connect(_on_detection_area_body_exited)
    
    # Initialize state machine
    if state_machine:
        state_machine.initialize(self)

func _physics_process(delta: float) -> void:
    if not is_alive:
        return
    
    # Handle knockback
    if knockback_timer > 0:
        velocity = knockback_vector * knockback_strength
        knockback_timer -= delta
    
    # Handle invincibility
    if is_invincible:
        invincibility_timer -= delta
        if invincibility_timer <= 0:
            is_invincible = false
            sprite.modulate.a = 1.0
    
    # Handle attack cooldown
    if attack_timer > 0:
        attack_timer -= delta
    
    # Apply movement
    move_and_slide()
    
    # Update facing direction
    if velocity != Vector2.ZERO:
        facing_direction = velocity.normalized()
        if animator:
            animator.set_direction(facing_direction)

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
    if not is_alive or is_invincible:
        return
    
    var actual_damage = stats.take_damage(amount)
    emit_signal("health_changed", stats.current_health, stats.max_health)
    
    # Apply knockback from damage source
    if source_position != Vector2.ZERO:
        var knockback_direction = (global_position - source_position).normalized()
        apply_knockback(knockback_direction)
    
    # Apply invincibility frames
    apply_invincibility(0.2)
    
    # Change to hurt state
    if state_machine and stats.is_alive():
        state_machine.change_state("hurt")
    
    # Flash sprite to indicate damage
    sprite.modulate = Color(1, 0.5, 0.5)  # Red tint
    var tween = create_tween()
    tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0.5), 0.2)

func apply_knockback(direction: Vector2) -> void:
    knockback_vector = direction
    knockback_timer = knockback_duration

func apply_invincibility(duration: float) -> void:
    is_invincible = true
    invincibility_timer = duration
    sprite.modulate.a = 0.5

func attack() -> void:
    if attack_timer <= 0 and not is_attacking and target != null:
        is_attacking = true
        attack_timer = attack_cooldown
        
        if state_machine:
            state_machine.change_state("attack")

func can_see_target() -> bool:
    if target == null:
        return false
    
    # Check if target is within detection range
    var distance = global_position.distance_to(target.global_position)
    if distance > chase_distance:
        return false
    
    # Raycast to check for obstacles
    var space_state = get_world_2d().direct_space_state
    var query = PhysicsRayQueryParameters2D.create(global_position, target.global_position)
    query.exclude = [self]
    var result = space_state.intersect_ray(query)
    
    if result and result.collider == target:
        return true
    
    return false

func can_attack_target() -> bool:
    if target == null:
        return false
    
    var distance = global_position.distance_to(target.global_position)
    return distance <= attack_distance and can_see_target()

func navigate_to_target(target_position: Vector2, delta: float) -> void:
    if nav_agent.is_navigation_finished():
        return
    
    nav_agent.target_position = target_position
    
    var next_position = nav_agent.get_next_path_position()
    var direction = global_position.direction_to(next_position)
    
    # Set facing direction
    facing_direction = direction
    
    # Calculate velocity
    var target_velocity = direction * move_speed
    velocity = velocity.move_toward(target_velocity, acceleration * delta)

func navigate_to_home(delta: float) -> void:
    navigate_to_target(home_position, delta)

func drop_loot() -> void:
    if loot_table:
        var drops = loot_table.roll_loot()
        if drops.size() > 0:
            # Spawn items
            for drop in drops:
                # This would typically instantiate an ItemPickup scene
                print("Enemy dropped: ", drop.item_id, " x", drop.count)

func _on_health_depleted() -> void:
    is_alive = false
    
    if state_machine:
        state_machine.change_state("death")
    
    # Disable collisions
    set_collision_layer_value(1, false)
    set_collision_mask_value(1, false)
    
    # Emit died signal
    emit_signal("enemy_died", self, global_position)
    
    # Drop loot
    drop_loot()

func _on_detection_area_body_entered(body: Node2D) -> void:
    if body.is_in_group("player") and is_alive:
        target = body
        
        if state_machine and state_machine.current_state.name.to_lower() == "idle":
            state_machine.change_state("chase")

func _on_detection_area_body_exited(body: Node2D) -> void:
    if body == target:
        target = null
        
        if state_machine and state_machine.current_state.name.to_lower() == "chase":
            state_machine.change_state("return")

func _on_animation_finished() -> void:
    if sprite.animation.begins_with("attack"):
        is_attacking = false
        
        if state_machine:
            # After attack, either chase or return to idle
            if target and can_see_target():
                state_machine.change_state("chase")
            else:
                state_machine.change_state("idle")
    elif sprite.animation == "death":
        # Schedule for removal after death animation
        queue_free() 