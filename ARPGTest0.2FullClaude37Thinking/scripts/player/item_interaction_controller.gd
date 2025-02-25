class_name ItemInteractionController
extends Node2D

signal interaction_available(interactable)
signal interaction_unavailable
signal interaction_started(interactable)
signal interaction_completed(interactable)
signal interaction_progress_updated(progress)

@export var player: CharacterBody2D
@export var max_interaction_distance: float = 100.0
@export var interaction_prompt: Node
@export var interaction_layer: int = 2  # Layer for interactable objects

var current_interactable: Interactable
var nearest_interactable: Interactable
var interactables_in_range: Array[Interactable] = []
var _is_interacting: bool = false

func _ready() -> void:
    if interaction_prompt:
        interaction_prompt.visible = false

func _process(delta: float) -> void:
    if _is_interacting and current_interactable and current_interactable.is_interacting():
        var progress = current_interactable.process_interaction(delta)
        emit_signal("interaction_progress_updated", progress)
    else:
        # Find nearest interactable if not interacting
        _find_nearest_interactable()
        
        # Update interaction prompt
        _update_interaction_prompt()

func _physics_process(_delta: float) -> void:
    # Check for interactables in range
    if not _is_interacting:
        _find_nearest_interactable()

func _input(event: InputEvent) -> void:
    # Handle interaction input
    if event.is_action_pressed("interact"):
        if current_interactable:
            start_interaction()
        elif nearest_interactable:
            current_interactable = nearest_interactable
            start_interaction()

func _find_nearest_interactable() -> void:
    if not player:
        return
    
    var space_state = get_world_2d().direct_space_state
    var player_pos = player.global_position
    
    # Area to check for interactables (circular)
    var query = PhysicsShapeQueryParameters2D.new()
    var shape = CircleShape2D.new()
    shape.radius = max_interaction_distance
    query.set_shape(shape)
    query.transform = Transform2D(0, player_pos)
    query.collision_mask = 1 << (interaction_layer - 1)
    
    var results = space_state.intersect_shape(query)
    
    # Clear previous list
    interactables_in_range.clear()
    nearest_interactable = null
    
    var min_distance = max_interaction_distance
    
    # Filter results for interactables
    for result in results:
        var collider = result.collider
        if collider is Interactable and collider.can_interact(player):
            var distance = player_pos.distance_to(collider.global_position)
            interactables_in_range.append(collider)
            
            if distance < min_distance:
                min_distance = distance
                nearest_interactable = collider
    
    # Notify if interaction became available
    if nearest_interactable and (not current_interactable or current_interactable != nearest_interactable):
        emit_signal("interaction_available", nearest_interactable)
    elif not nearest_interactable and current_interactable and not _is_interacting:
        current_interactable = null
        emit_signal("interaction_unavailable")

func _update_interaction_prompt() -> void:
    if not interaction_prompt:
        return
    
    if nearest_interactable and not _is_interacting:
        interaction_prompt.visible = true
        
        # Update prompt text if possible
        if interaction_prompt.has_method("set_text"):
            var action_text = nearest_interactable.get_interaction_label()
            interaction_prompt.set_text(action_text)
        
        # Position prompt above interactable
        var prompt_pos = nearest_interactable.global_position
        prompt_pos.y -= 40  # Offset above object
        interaction_prompt.global_position = prompt_pos
    else:
        interaction_prompt.visible = false

func start_interaction() -> void:
    if not current_interactable or not current_interactable.can_interact(player):
        return
    
    _is_interacting = true
    current_interactable.start_interaction(player)
    emit_signal("interaction_started", current_interactable)

func cancel_interaction() -> void:
    if not _is_interacting or not current_interactable:
        return
    
    current_interactable.cancel_interaction()
    _is_interacting = false
    emit_signal("interaction_unavailable")

func _on_interactable_completed(_interactor: Node2D) -> void:
    _is_interacting = false
    emit_signal("interaction_completed", current_interactable)
    
    # Clear current interactable if it can't be interacted with again
    if not current_interactable.can_interact_multiple_times:
        current_interactable = null 