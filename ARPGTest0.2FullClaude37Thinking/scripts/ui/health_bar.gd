extends Control
class_name HealthBar

@onready var health_bar = $ProgressBar
@onready var health_label = $HealthLabel

var max_health: int = 100
var current_health: int = 100
var target_health: int = 100
var smoothing_speed: float = 5.0

signal health_depleted

func _ready():
	update_health_display()

func _process(delta):
	# Smooth health bar animation
	if current_health != target_health:
		current_health = lerp(current_health, target_health, smoothing_speed * delta)
		if abs(current_health - target_health) < 0.5:
			current_health = target_health
		update_health_display()

func initialize(character_stats: CharacterStats):
	max_health = character_stats.max_health
	set_health(character_stats.current_health)
	
func set_health(value: int):
	target_health = value
	if target_health <= 0:
		health_depleted.emit()

func update_health_display():
	var health_percent = (current_health / float(max_health)) * 100
	health_bar.value = health_percent
	health_label.text = "%d/%d" % [int(current_health), max_health]
	
	# Change color based on health percentage
	if health_percent < 25:
		health_bar.modulate = Color(1, 0, 0)  # Red
	elif health_percent < 50:
		health_bar.modulate = Color(1, 0.5, 0)  # Orange
	else:
		health_bar.modulate = Color(0, 1, 0)  # Green 