class_name InteractionPrompt
extends Control

@export var prompt_text: String = "Press E to interact"
@export var key_binding: String = "E"
@export var font_color: Color = Color.WHITE
@export var background_color: Color = Color(0, 0, 0, 0.5)
@export var padding: Vector2 = Vector2(10, 5)
@export var auto_follow_camera: bool = true

@onready var label = $Label
@onready var background = $Background
@onready var key_label = $KeyLabel

func _ready() -> void:
    if label:
        label.text = prompt_text
        label.add_theme_color_override("font_color", font_color)
    
    if background:
        var style_box = background.get_theme_stylebox("panel").duplicate()
        style_box.bg_color = background_color
        background.add_theme_stylebox_override("panel", style_box)
    
    if key_label:
        key_label.text = key_binding
    
    # Ensure the prompt is centered on its position
    pivot_offset = size / 2

func _process(_delta: float) -> void:
    if auto_follow_camera and is_instance_valid(get_viewport().get_camera_2d()):
        # Keep the prompt in screen space
        var camera = get_viewport().get_camera_2d()
        var screen_pos = global_position - camera.get_screen_center_position() + get_viewport_rect().size / 2
        global_position = screen_pos

func set_text(text: String) -> void:
    prompt_text = text
    if label:
        label.text = text
        # Resize background to fit text
        if background:
            await get_tree().process_frame
            var text_size = label.get_minimum_size()
            background.size = text_size + padding * 2
            background.position = -padding
            pivot_offset = size / 2

func set_key(key: String) -> void:
    key_binding = key
    if key_label:
        key_label.text = key

func show_prompt() -> void:
    visible = true
    
    # Optional animation
    modulate.a = 0
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.2)

func hide_prompt() -> void:
    # Optional animation
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.2)
    tween.tween_callback(func(): visible = false) 