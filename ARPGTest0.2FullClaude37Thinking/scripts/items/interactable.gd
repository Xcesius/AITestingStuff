class_name Interactable
extends Area2D

signal interaction_started(interactor)
signal interaction_completed(interactor)

@export_category("Interaction Settings")
@export var interaction_label: String = "Interact"
@export var interaction_distance: float = 50.0
@export var interaction_time: float = 0.0  # 0 for instant interaction
@export var can_interact_multiple_times: bool = false
@export var highlight_on_proximity: bool = true

@export_category("Effects")
@export var interaction_sound: AudioStream
@export var interaction_effect: PackedScene

var _has_interacted: bool = false
var _interaction_progress: float = 0.0
var _is_interacting: bool = false
var _current_interactor: Node2D

func _ready() -> void:
    connect("body_entered", _on_body_entered)
    connect("body_exited", _on_body_exited)

func can_interact(interactor: Node2D) -> bool:
    if _has_interacted and not can_interact_multiple_times:
        return false
    
    # Check distance
    var distance = global_position.distance_to(interactor.global_position)
    if distance > interaction_distance:
        return false
    
    return true

func start_interaction(interactor: Node2D) -> void:
    if not can_interact(interactor):
        return
    
    _is_interacting = true
    _current_interactor = interactor
    _interaction_progress = 0.0
    
    emit_signal("interaction_started", interactor)
    
    # If instant interaction, complete immediately
    if interaction_time <= 0.0:
        complete_interaction()

func process_interaction(delta: float) -> float:
    if not _is_interacting:
        return 0.0
    
    if interaction_time <= 0.0:
        return 1.0
    
    _interaction_progress += delta / interaction_time
    _interaction_progress = min(_interaction_progress, 1.0)
    
    if _interaction_progress >= 1.0:
        complete_interaction()
    
    return _interaction_progress

func cancel_interaction() -> void:
    _is_interacting = false
    _current_interactor = null
    _interaction_progress = 0.0

func complete_interaction() -> void:
    if not _is_interacting:
        return
    
    _has_interacted = true
    _is_interacting = false
    
    # Play sound if available
    if interaction_sound:
        var audio_player = AudioStreamPlayer2D.new()
        add_child(audio_player)
        audio_player.stream = interaction_sound
        audio_player.play()
    
    # Play effect if available
    if interaction_effect:
        var effect = interaction_effect.instantiate()
        get_parent().add_child(effect)
        effect.global_position = global_position
    
    # Emit completion signal
    emit_signal("interaction_completed", _current_interactor)
    
    # Clear current interactor
    var interactor = _current_interactor
    _current_interactor = null
    
    # Override this in child classes to implement specific behavior
    _on_interaction_completed(interactor)

func _on_interaction_completed(_interactor: Node2D) -> void:
    # Override in child classes
    pass

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player") and highlight_on_proximity:
        _highlight(true)

func _on_body_exited(body: Node2D) -> void:
    if body.is_in_group("player") and highlight_on_proximity:
        _highlight(false)

func _highlight(enabled: bool) -> void:
    # Override in child classes or implement default highlight
    var sprite = get_node_or_null("Sprite2D")
    if sprite:
        if enabled:
            sprite.modulate = Color(1.2, 1.2, 1.2)  # Slight glow
        else:
            sprite.modulate = Color(1, 1, 1)  # Normal color

func get_interaction_label() -> String:
    return interaction_label

func is_interacting() -> bool:
    return _is_interacting

func get_interaction_progress() -> float:
    return _interaction_progress 