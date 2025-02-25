class_name PlayerCharacter
extends CharacterBody2D

signal health_changed(current_health, max_health)
signal experience_gained(amount, current_exp, next_level_exp)
signal level_up(new_level)
signal player_died
signal equipment_changed

# Node references
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var hitbox: Area2D = $HitBox
@onready var equipment_controller: EquipmentController = $EquipmentController
@onready var animator: PlayerAnimator = $Animator

# Resources
@export var stats: CharacterStats
@export var inventory: Inventory

# Movement variables
@export var acceleration: float = 800.0
@export var friction: float = 800.0
@export var max_speed: float = 120.0

# Combat variables
@export var attack_cooldown: float = 0.5
var attack_timer: float = 0.0
var is_attacking: bool = false
var facing_direction: Vector2 = Vector2.DOWN

# State tracking
var is_invincible: bool = false
var invincibility_timer: float = 0.0
var knockback_vector: Vector2 = Vector2.ZERO
var knockback_strength: float = 200.0
var knockback_duration: float = 0.15
var knockback_timer: float = 0.0

func _ready() -> void:
    # Initialize resources if not set
    if stats == null:
        stats = CharacterStats.new()
    if inventory == null:
        inventory = Inventory.new()
    
    # Initialize equipment controller
    if equipment_controller:
        equipment_controller.initialize(inventory, stats)
        equipment_controller.equipment_changed.connect(func(): emit_signal("equipment_changed"))
    
    # Connect signals
    stats.connect("health_depleted", Callable(self, "_on_health_depleted"))
    
    # Initialize starting state
    if state_machine:
        state_machine.initialize(self)

func _physics_process(delta: float) -> void:
    # Handle knockback
    if knockback_timer > 0:
        velocity = knockback_vector * knockback_strength
        knockback_timer -= delta
    
    # Handle invincibility frames
    if is_invincible:
        invincibility_timer -= delta
        if invincibility_timer <= 0:
            is_invincible = false
            sprite.modulate.a = 1.0  # Reset transparency
    
    # Handle attack cooldown
    if attack_timer > 0:
        attack_timer -= delta
    
    # Apply movement from state machine
    move_and_slide()
    
    # Update facing direction
    if velocity != Vector2.ZERO:
        facing_direction = velocity.normalized()
        if animator:
            animator.set_direction(facing_direction)

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
    if is_invincible:
        return
    
    var actual_damage = stats.take_damage(amount)
    emit_signal("health_changed", stats.current_health, stats.get_total_max_health())
    
    # Apply knockback in opposite direction from damage source
    if source_position != Vector2.ZERO:
        var knockback_direction = (global_position - source_position).normalized()
        apply_knockback(knockback_direction)
    
    # Apply invincibility frames
    apply_invincibility(0.5)  # Half-second of invincibility after being hit
    
    # Change to hurt state
    if state_machine and stats.is_alive():
        state_machine.change_state("hurt")

func heal(amount: int) -> void:
    stats.heal(amount)
    emit_signal("health_changed", stats.current_health, stats.get_total_max_health())

func apply_knockback(direction: Vector2) -> void:
    knockback_vector = direction
    knockback_timer = knockback_duration
    
func apply_invincibility(duration: float) -> void:
    is_invincible = true
    invincibility_timer = duration
    # Visual indication of invincibility
    sprite.modulate.a = 0.5

func add_experience(amount: int) -> void:
    var leveled_up = stats.add_experience(amount)
    emit_signal("experience_gained", amount, stats.experience, stats.next_level_exp)
    
    if leveled_up:
        emit_signal("level_up", stats.level)

func attack() -> void:
    if attack_timer <= 0 and not is_attacking:
        is_attacking = true
        attack_timer = attack_cooldown / stats.get_total_attack_speed()
        
        if state_machine:
            state_machine.change_state("attack")

func pickup_item(item_data: ItemData, count: int = 1) -> bool:
    return inventory.add_item(item_data, count)

func use_item(item_index: int) -> bool:
    var item = inventory.get_item(item_index)
    if item and item.item_data:
        if item.item_data.use(self):
            inventory.remove_item(item_index, 1)
            return true
    return false

# Equipment methods
func equip_item(item: EquipmentData) -> bool:
    if not equipment_controller:
        return false
    
    return equipment_controller.equip_item_from_inventory(item)

func unequip_item(slot: String) -> bool:
    if not equipment_controller:
        return false
    
    return equipment_controller.unequip_item(slot)

func has_item_equipped(slot: String) -> bool:
    if not equipment_controller:
        return false
    
    return equipment_controller.has_item_equipped(slot)

func get_equipped_item(slot: String) -> EquipmentData:
    if not equipment_controller:
        return null
    
    return equipment_controller.get_equipped_item(slot)

func get_all_equipment() -> Dictionary:
    if not equipment_controller:
        return {}
    
    return equipment_controller.get_all_equipment()

func calculate_weapon_damage() -> int:
    if equipment_controller:
        return equipment_controller.calculate_weapon_damage()
    return stats.get_total_attack()  # Fallback to base stats if no equipment controller

func _on_health_depleted() -> void:
    if state_machine:
        state_machine.change_state("death")
    emit_signal("player_died")

func _on_animation_finished() -> void:
    if sprite.animation.begins_with("attack"):
        is_attacking = false
        if state_machine:
            state_machine.change_state("idle")
    elif sprite.animation == "death":
        # Additional death logic if needed
        pass 