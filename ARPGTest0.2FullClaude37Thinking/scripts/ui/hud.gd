extends CanvasLayer
class_name HUD

@onready var health_bar = $HealthBarContainer/HealthBar
@onready var level_label = $PlayerInfoContainer/LevelLabel
@onready var experience_bar = $PlayerInfoContainer/ExperienceBar
@onready var damage_numbers_container = $DamageNumbersContainer
@onready var status_effects_container = $StatusEffectsContainer
@onready var minimap = $MinimapContainer/Minimap

var player_stats: CharacterStats

func _ready():
	# Initialize HUD components
	if minimap:
		minimap.set_process(true)

func initialize(character_stats: CharacterStats):
	player_stats = character_stats
	
	# Initialize health bar
	health_bar.initialize(character_stats)
	
	# Set level display
	update_level_display()
	
	# Connect signals to player stats for updates
	player_stats.connect("health_changed", Callable(self, "_on_health_changed"))
	player_stats.connect("level_up", Callable(self, "_on_level_up"))
	player_stats.connect("experience_gained", Callable(self, "_on_experience_gained"))
	
func _on_health_changed(new_health: int):
	health_bar.set_health(new_health)
	
func update_level_display():
	level_label.text = "Level " + str(player_stats.level)
	update_experience_bar()

func _on_level_up(new_level: int):
	level_label.text = "Level " + str(new_level)
	update_experience_bar()
	
	# Display level up animation
	var level_up_effect = $LevelUpEffect
	if level_up_effect:
		level_up_effect.show()
		level_up_effect.play()

func _on_experience_gained(current_exp: int, max_exp: int):
	update_experience_bar()

func update_experience_bar():
	var exp_percent = (float(player_stats.experience) / float(player_stats.next_level_exp)) * 100
	experience_bar.value = exp_percent

func show_damage_number(value: int, position: Vector2, is_critical: bool = false):
	var damage_label = preload("res://scenes/ui/damage_number.tscn").instantiate()
	damage_numbers_container.add_child(damage_label)
	damage_label.global_position = position
	damage_label.set_damage_value(value, is_critical)

func add_status_effect(effect_icon: Texture, duration: float, effect_name: String):
	var status_effect = preload("res://scenes/ui/status_effect_icon.tscn").instantiate()
	status_effects_container.add_child(status_effect)
	status_effect.initialize(effect_icon, duration, effect_name)
	
func remove_status_effect(effect_name: String):
	for effect in status_effects_container.get_children():
		if effect.effect_name == effect_name:
			effect.queue_free()
			break

func _input(event):
	if event.is_action_pressed("toggle_minimap"):
		minimap.visible = !minimap.visible 