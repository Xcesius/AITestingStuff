extends Node2D
class_name DamageNumber

@onready var label = $Label
@onready var animation_player = $AnimationPlayer

var value: int = 0
var velocity: Vector2 = Vector2(0, -50)  # Initial upward movement
var duration: float = 1.0
var time_elapsed: float = 0.0
var fade_speed: float = 1.5
var critical_hit: bool = false

func _ready():
	# Play the animation
	animation_player.play("float_and_fade")

func set_damage_value(damage_value: int, is_critical: bool = false):
	value = damage_value
	critical_hit = is_critical
	
	# Set the label text
	label.text = str(value)
	
	# Apply different styling for critical hits
	if critical_hit:
		label.add_theme_color_override("font_color", Color(1, 0, 0))  # Red
		label.add_theme_font_size_override("font_size", 24)  # Larger font
		
		# Make the text bold
		var font = label.get_theme_font("font")
		if font:
			label.add_theme_font_override("font", font.duplicate(true))
			
		# Dramatic scale effect for critical hits
		scale = Vector2(1.5, 1.5)

func _process(delta):
	# Update position based on velocity
	position += velocity * delta
	
	# Apply gravity effect to slow down upward movement
	velocity.y += 50 * delta
	
	# Update time elapsed
	time_elapsed += delta
	
	# Remove when animation completes
	if time_elapsed >= duration:
		queue_free()

# Animation signal callback
func _on_animation_finished(_anim_name):
	queue_free() 