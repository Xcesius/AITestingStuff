class_name PlayerItemInteractor
extends Node2D

# Add this as a child of the player to enable item interactions

@export var interaction_distance: float = 100.0
@export var interaction_prompt_scene: PackedScene

var interaction_controller: ItemInteractionController
var prompt_instance: Node

func _ready() -> void:
    var player = get_parent() as CharacterBody2D
    if not player:
        push_error("PlayerItemInteractor must be a child of a CharacterBody2D!")
        return
    
    # Create interaction controller
    interaction_controller = ItemInteractionController.new()
    add_child(interaction_controller)
    
    # Setup controller
    interaction_controller.player = player
    interaction_controller.max_interaction_distance = interaction_distance
    
    # Create interaction prompt if scene provided
    if interaction_prompt_scene:
        prompt_instance = interaction_prompt_scene.instantiate()
        add_child(prompt_instance)
        prompt_instance.visible = false
        interaction_controller.interaction_prompt = prompt_instance
    
    # Connect signals
    interaction_controller.connect("interaction_available", _on_interaction_available)
    interaction_controller.connect("interaction_unavailable", _on_interaction_unavailable)
    interaction_controller.connect("interaction_started", _on_interaction_started)
    interaction_controller.connect("interaction_completed", _on_interaction_completed)
    interaction_controller.connect("interaction_progress_updated", _on_interaction_progress_updated)

func _input(event: InputEvent) -> void:
    # Pass input to interaction controller
    interaction_controller._input(event)

func _on_interaction_available(interactable: Interactable) -> void:
    # Override in player script if needed
    pass

func _on_interaction_unavailable() -> void:
    # Override in player script if needed
    pass

func _on_interaction_started(interactable: Interactable) -> void:
    # Override in player script if needed
    pass

func _on_interaction_completed(interactable: Interactable) -> void:
    # Override in player script if needed
    pass

func _on_interaction_progress_updated(progress: float) -> void:
    # Override in player script if needed
    pass

func get_nearest_interactable() -> Interactable:
    return interaction_controller.nearest_interactable

func get_interactables_in_range() -> Array[Interactable]:
    return interaction_controller.interactables_in_range

func is_interacting() -> bool:
    return interaction_controller._is_interacting

func cancel_interaction() -> void:
    interaction_controller.cancel_interaction() 