extends Control
class_name StatusEffectIcon

@onready var icon = $TextureRect
@onready var timer_progress = $ProgressBar
@onready var tooltip = $TooltipLabel

var effect_icon: Texture
var duration: float = 0.0
var time_remaining: float = 0.0
var effect_name: String = ""

func _ready():
	tooltip.visible = false

func initialize(new_icon: Texture, new_duration: float, new_effect_name: String):
	effect_icon = new_icon
	duration = new_duration
	time_remaining = duration
	effect_name = new_effect_name
	
	# Set the icon
	icon.texture = effect_icon
	
	# Set tooltip
	tooltip.text = effect_name + "\nDuration: " + str(int(duration)) + "s"
	
	# Initialize progress bar
	timer_progress.max_value = duration
	timer_progress.value = duration

func _process(delta):
	# Update time remaining
	time_remaining -= delta
	
	if time_remaining <= 0:
		queue_free()
		return
	
	# Update progress bar
	timer_progress.value = time_remaining
	
	# Calculate progress bar color based on time remaining
	var progress_ratio = time_remaining / duration
	var color = Color(1, progress_ratio, progress_ratio)  # Transition from green to red
	timer_progress.modulate = color

func _on_mouse_entered():
	tooltip.visible = true
	
	# Update tooltip text with current time
	tooltip.text = effect_name + "\nDuration: " + str(int(time_remaining)) + "s"

func _on_mouse_exited():
	tooltip.visible = false 