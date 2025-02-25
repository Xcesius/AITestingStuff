extends Camera2D
class_name GameCamera

# Camera following
@export var target_path: NodePath
@export var follow_speed: float = 5.0
@export var look_ahead_factor: float = 0.2
@export var look_ahead_smoothing: float = 0.5
@export var offset_smoothing: float = 0.5

# Camera shake
@export var trauma_reduction_rate: float = 1.0
@export var max_shake_offset: Vector2 = Vector2(32, 24)
@export var max_shake_rotation: float = 0.1
@export var noise_shake_speed: float = 15.0
@export var noise_pattern_factor: Vector2 = Vector2(100, 100)

# Camera zoom
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var zoom_speed: float = 0.5
@export var zoom_margin: float = 0.1
@export var zoom_smoothing: float = 0.5

# Camera effects
@export var enable_screen_shake: bool = true
@export var enable_zoom_effects: bool = true

# Internal variables
var target: Node2D = null
var trauma: float = 0.0
var noise: FastNoiseLite = FastNoiseLite.new()
var noise_position: float = 0.0
var current_offset: Vector2 = Vector2.ZERO
var target_offset: Vector2 = Vector2.ZERO
var target_zoom: Vector2 = Vector2.ONE
var look_direction: Vector2 = Vector2.ZERO
var look_target: Vector2 = Vector2.ZERO

func _ready():
	# Setup camera noise for shake effect
	noise.seed = randi()
	noise.frequency = 0.05
	
	# Find target if path provided
	if not target_path.is_empty():
		target = get_node(target_path)
	else:
		# Try to find a player in the scene
		target = get_tree().get_first_node_in_group("player")
	
	# Register events
	EventBus.connect("camera_shake_requested", Callable(self, "add_trauma"))
	EventBus.connect("camera_zoom_requested", Callable(self, "set_zoom_level"))
	EventBus.connect("camera_target_changed", Callable(self, "set_camera_target"))

func _process(delta):
	# Skip if no target
	if not target or not is_instance_valid(target):
		return
	
	# Follow target with smoothing
	follow_target(delta)
	
	# Update camera shake
	process_shake(delta)
	
	# Update camera zoom
	process_zoom(delta)

func follow_target(delta):
	# Calculate look ahead
	if target.has_method("get_move_direction"):
		var move_dir = target.get_move_direction()
		look_direction = look_direction.lerp(move_dir, delta * look_ahead_smoothing)
	elif target is CharacterBody2D:
		look_direction = look_direction.lerp(target.velocity.normalized(), delta * look_ahead_smoothing)
	
	# Calculate look ahead target
	look_target = look_direction * look_ahead_factor * get_viewport_rect().size
	
	# Calculate target offset with look ahead
	target_offset = target_offset.lerp(look_target, delta * offset_smoothing)
	
	# Smoothly move camera to target
	if follow_speed <= 0:
		global_position = target.global_position + target_offset
	else:
		global_position = global_position.lerp(target.global_position + target_offset, delta * follow_speed)

func process_shake(delta):
	if enable_screen_shake:
		# Reduce trauma over time
		trauma = max(trauma - trauma_reduction_rate * delta, 0.0)
		
		if trauma > 0.0:
			# Update noise position
			noise_position += delta * noise_shake_speed
			
			# Calculate shake amount (trauma squared for more natural shake)
			var shake_amount = trauma * trauma
			
			# Apply noise-based shake
			offset.x = max_shake_offset.x * shake_amount * noise.get_noise_1d(noise_position * noise_pattern_factor.x)
			offset.y = max_shake_offset.y * shake_amount * noise.get_noise_1d(noise_position * noise_pattern_factor.y + 1.0)
			rotation = max_shake_rotation * shake_amount * noise.get_noise_1d(noise_position * 2.0 + 2.0)
		else:
			# Reset shake
			offset = Vector2.ZERO
			rotation = 0
	else:
		# Reset shake
		offset = Vector2.ZERO
		rotation = 0

func process_zoom(delta):
	if enable_zoom_effects:
		# Smoothly interpolate towards target zoom
		zoom = zoom.lerp(target_zoom, delta * zoom_smoothing)

func add_trauma(amount: float):
	if enable_screen_shake:
		trauma = min(trauma + amount, 1.0)

func set_zoom_level(zoom_level: float, duration: float = 0.0):
	zoom_level = clamp(zoom_level, min_zoom, max_zoom)
	target_zoom = Vector2(zoom_level, zoom_level)
	
	if duration > 0:
		# Return to normal zoom after duration
		var tween = create_tween()
		tween.tween_callback(func(): 
			target_zoom = Vector2.ONE
		).set_delay(duration)

func set_camera_target(new_target: Node2D):
	if new_target and is_instance_valid(new_target):
		target = new_target
		
		# Jump to target immediately
		global_position = target.global_position

func zoom_in(amount: float = 0.1):
	var new_zoom = min(target_zoom.x + amount, max_zoom)
	target_zoom = Vector2(new_zoom, new_zoom)

func zoom_out(amount: float = 0.1):
	var new_zoom = max(target_zoom.x - amount, min_zoom)
	target_zoom = Vector2(new_zoom, new_zoom)

# Focus on a specific position with optional zoom
func focus_position(pos: Vector2, custom_zoom: float = -1, duration: float = 1.0):
	var original_target = target
	var original_zoom = target_zoom
	
	# Temporarily remove target
	target = null
	
	# Set zoom if provided
	if custom_zoom > 0:
		target_zoom = Vector2(custom_zoom, custom_zoom)
	
	# Move to position
	var tween = create_tween()
	tween.tween_property(self, "global_position", pos, duration).set_ease(Tween.EASE_IN_OUT)
	
	# Return to normal state after duration
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		target = original_target
		target_zoom = original_zoom
		
# Camera shake overload methods for easier usage
func shake_small():
	add_trauma(0.2)

func shake_medium():
	add_trauma(0.4)

func shake_large():
	add_trauma(0.6)

func shake_extreme():
	add_trauma(0.8) 