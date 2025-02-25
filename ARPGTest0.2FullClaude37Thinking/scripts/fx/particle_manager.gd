extends Node2D
class_name ParticleManager

# Cache of particle scenes
var particle_scenes = {}

# Pool of inactive particles
var particle_pools = {}

# Active particles
var active_particles = []

# Default particle paths
const DEFAULT_PARTICLES = {
	"hit": "res://scenes/fx/hit_effect.tscn",
	"slash": "res://scenes/fx/slash_effect.tscn",
	"blood": "res://scenes/fx/blood_effect.tscn",
	"dust": "res://scenes/fx/dust_effect.tscn",
	"footstep": "res://scenes/fx/footstep_effect.tscn",
	"death": "res://scenes/fx/death_effect.tscn",
	"magic": "res://scenes/fx/magic_effect.tscn",
	"heal": "res://scenes/fx/heal_effect.tscn",
	"level_up": "res://scenes/fx/level_up_effect.tscn",
	"item_pickup": "res://scenes/fx/item_pickup_effect.tscn",
	"door_open": "res://scenes/fx/door_open_effect.tscn",
	"explosion": "res://scenes/fx/explosion_effect.tscn",
	"fire": "res://scenes/fx/fire_effect.tscn",
	"smoke": "res://scenes/fx/smoke_effect.tscn",
	"water_splash": "res://scenes/fx/water_splash_effect.tscn",
	"electric": "res://scenes/fx/electric_effect.tscn"
}

# Configuration
@export var pool_size: int = 20
@export var auto_preload: bool = true
@export var clear_inactive_timeout: float = 60.0

# Cleanup timer
var cleanup_timer: Timer

func _ready():
	# Create cleanup timer
	cleanup_timer = Timer.new()
	cleanup_timer.wait_time = clear_inactive_timeout
	cleanup_timer.one_shot = false
	cleanup_timer.connect("timeout", Callable(self, "_cleanup_old_particles"))
	add_child(cleanup_timer)
	cleanup_timer.start()
	
	# Connect to EventBus
	EventBus.connect("spawn_particle", Callable(self, "spawn_particle"))
	
	# Preload default particles
	if auto_preload:
		for key in DEFAULT_PARTICLES:
			preload_particle(key, DEFAULT_PARTICLES[key])

func preload_particle(particle_name: String, particle_path: String) -> bool:
	# Check if already loaded
	if particle_scenes.has(particle_name):
		return true
	
	# Try to load particle scene
	var particle_scene = load(particle_path)
	if not particle_scene:
		printerr("Failed to load particle effect: " + particle_path)
		return false
	
	# Store in cache
	particle_scenes[particle_name] = particle_scene
	
	# Create initial pool
	_create_particle_pool(particle_name, particle_scene)
	
	return true

func _create_particle_pool(particle_name: String, particle_scene):
	# Create array for this particle type if it doesn't exist
	if not particle_pools.has(particle_name):
		particle_pools[particle_name] = []
	
	# Create initial instances
	for i in range(pool_size):
		var particle = particle_scene.instantiate()
		particle.finished.connect(_on_particle_finished.bind(particle))
		add_child(particle)
		particle.visible = false
		particle.emitting = false
		particle_pools[particle_name].append(particle)

func spawn_particle(particle_name: String, position: Vector2, options: Dictionary = {}) -> GPUParticles2D:
	# Check if particle exists
	if not particle_scenes.has(particle_name):
		# Try to load it on demand
		var default_path = DEFAULT_PARTICLES.get(particle_name, "")
		if default_path.is_empty() or not preload_particle(particle_name, default_path):
			printerr("Particle not found and cannot be loaded: " + particle_name)
			return null
	
	# Get particle from pool or create new one
	var particle = _get_particle_from_pool(particle_name)
	
	# Position particle
	particle.global_position = position
	
	# Apply options
	if options.has("rotation"):
		particle.rotation = options.rotation
	if options.has("scale"):
		particle.scale = Vector2(options.scale, options.scale)
	if options.has("color"):
		if "modulate" in particle:
			particle.modulate = options.color
	if options.has("lifetime_scale"):
		particle.lifetime = particle.lifetime * options.lifetime_scale
	if options.has("emitting"):
		particle.emitting = options.emitting
	else:
		# Start emitting by default
		particle.emitting = true
	
	# Make visible
	particle.visible = true
	
	# Add to active particles
	active_particles.append(particle)
	
	return particle

func _get_particle_from_pool(particle_name: String) -> GPUParticles2D:
	var pool = particle_pools.get(particle_name, [])
	
	# Try to find inactive particle
	for particle in pool:
		if not particle.emitting:
			# Reset particle
			particle.restart()
			return particle
	
	# No available particles, create new one
	var particle_scene = particle_scenes[particle_name]
	var particle = particle_scene.instantiate()
	particle.finished.connect(_on_particle_finished.bind(particle))
	add_child(particle)
	
	# Add to pool
	particle_pools[particle_name].append(particle)
	
	return particle

func _on_particle_finished(particle):
	particle.visible = false
	
	# Remove from active particles
	var index = active_particles.find(particle)
	if index >= 0:
		active_particles.remove_at(index)

func _cleanup_old_particles():
	for particle_name in particle_pools:
		var pool = particle_pools[particle_name]
		
		# If pool is much larger than needed, remove excess
		if pool.size() > pool_size * 2:
			var to_remove = pool.size() - pool_size
			
			# Find inactive particles to remove
			var removed = 0
			for i in range(pool.size() - 1, -1, -1):
				var particle = pool[i]
				
				# Only remove if inactive
				if not particle.emitting:
					pool.remove_at(i)
					particle.queue_free()
					removed += 1
				
				if removed >= to_remove:
					break

# Shorthand methods for common effects
func spawn_hit_effect(position: Vector2, rotation: float = 0.0, scale: float = 1.0) -> GPUParticles2D:
	return spawn_particle("hit", position, {
		"rotation": rotation,
		"scale": scale
	})

func spawn_slash_effect(position: Vector2, rotation: float = 0.0, scale: float = 1.0) -> GPUParticles2D:
	return spawn_particle("slash", position, {
		"rotation": rotation,
		"scale": scale
	})

func spawn_blood_effect(position: Vector2, rotation: float = 0.0, scale: float = 1.0) -> GPUParticles2D:
	return spawn_particle("blood", position, {
		"rotation": rotation,
		"scale": scale
	})

func spawn_dust_effect(position: Vector2, scale: float = 1.0) -> GPUParticles2D:
	return spawn_particle("dust", position, {
		"scale": scale
	})

func spawn_footstep_effect(position: Vector2, scale: float = 1.0) -> GPUParticles2D:
	return spawn_particle("footstep", position, {
		"scale": scale
	})

func spawn_death_effect(position: Vector2, scale: float = 1.0) -> GPUParticles2D:
	return spawn_particle("death", position, {
		"scale": scale
	})

func stop_all_particles():
	for particle in active_particles:
		particle.emitting = false
	
	active_particles.clear()

func set_paused(paused: bool):
	# Pause or resume all active particles
	for particle in active_particles:
		particle.set_process(not paused)
		particle.set_physics_process(not paused) 