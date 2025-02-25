extends Node
class_name AudioManager

# Sound Categories
enum SoundType {
	MUSIC,
	SFX,
	UI,
	AMBIENT,
	VOICE
}

# Sound players
var music_players: Array[AudioStreamPlayer] = []
var sfx_players: Array[AudioStreamPlayer] = []
var ui_players: Array[AudioStreamPlayer] = []
var ambient_players: Array[AudioStreamPlayer] = []
var voice_players: Array[AudioStreamPlayer] = []

# Music transition
var current_music: AudioStreamPlayer = null
var next_music: AudioStreamPlayer = null
var transition_timer: Timer = null
var transition_duration: float = 1.0
var transition_time: float = 0.0

# Settings
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var ui_volume: float = 1.0
var ambient_volume: float = 1.0
var voice_volume: float = 1.0
var master_volume: float = 1.0

# Volume bus indices
var music_bus_index: int = -1
var sfx_bus_index: int = -1
var ui_bus_index: int = -1
var ambient_bus_index: int = -1
var voice_bus_index: int = -1
var master_bus_index: int = -1

# Cached sounds dictionary
var cached_sounds: Dictionary = {}

func _ready():
	# Initialize audio buses
	music_bus_index = AudioServer.get_bus_index("Music")
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	ui_bus_index = AudioServer.get_bus_index("UI")
	ambient_bus_index = AudioServer.get_bus_index("Ambient")
	voice_bus_index = AudioServer.get_bus_index("Voice") 
	master_bus_index = AudioServer.get_bus_index("Master")
	
	# Create audio players
	_create_audio_players(3, music_players, music_bus_index) # 3 music players for crossfading
	_create_audio_players(12, sfx_players, sfx_bus_index) # 12 SFX players for many sounds
	_create_audio_players(6, ui_players, ui_bus_index) # 6 UI players
	_create_audio_players(4, ambient_players, ambient_bus_index) # 4 ambient players
	_create_audio_players(3, voice_players, voice_bus_index) # 3 voice players
	
	# Create transition timer
	transition_timer = Timer.new()
	transition_timer.one_shot = true
	add_child(transition_timer)
	transition_timer.connect("timeout", Callable(self, "_on_transition_complete"))

func _create_audio_players(count: int, player_array: Array[AudioStreamPlayer], bus_idx: int):
	for i in range(count):
		var player = AudioStreamPlayer.new()
		player.bus = AudioServer.get_bus_name(bus_idx)
		add_child(player)
		player_array.append(player)

func _process(delta):
	# Handle music crossfading
	if current_music and next_music and transition_timer.time_left > 0:
		transition_time += delta
		var t = transition_time / transition_duration
		
		# Fade out current music
		current_music.volume_db = linear_to_db(music_volume * (1.0 - t))
		
		# Fade in next music
		next_music.volume_db = linear_to_db(music_volume * t)

# Preload sounds into cache
func preload_sound(path: String) -> bool:
	if cached_sounds.has(path):
		return true
	
	var sound = load(path)
	if sound:
		cached_sounds[path] = sound
		return true
	
	return false

# Get available player for a sound type
func _get_available_player(sound_type: SoundType) -> AudioStreamPlayer:
	var players: Array[AudioStreamPlayer]
	
	match sound_type:
		SoundType.MUSIC:
			players = music_players
		SoundType.SFX:
			players = sfx_players
		SoundType.UI:
			players = ui_players
		SoundType.AMBIENT:
			players = ambient_players
		SoundType.VOICE:
			players = voice_players
	
	# Find first available player
	for player in players:
		if not player.playing:
			return player
	
	# If all players are busy, return the one that started earliest
	var oldest_player = players[0]
	var oldest_time = 0.0
	
	for player in players:
		var playback = player.get_playback_position()
		if playback > oldest_time:
			oldest_time = playback
			oldest_player = player
	
	return oldest_player

# Play sound from a given path
func play_sound(path: String, sound_type: SoundType = SoundType.SFX, volume: float = 1.0, pitch: float = 1.0) -> AudioStreamPlayer:
	var sound = null
	
	# Check cache first
	if cached_sounds.has(path):
		sound = cached_sounds[path]
	else:
		# Load sound
		sound = load(path)
		if not sound:
			printerr("Failed to load sound: " + path)
			return null
		
		# Add to cache
		cached_sounds[path] = sound
	
	# Get player
	var player = _get_available_player(sound_type)
	
	# Configure player
	player.stream = sound
	player.pitch_scale = pitch
	
	# Set volume based on sound type
	var type_volume = 1.0
	match sound_type:
		SoundType.MUSIC:
			type_volume = music_volume
		SoundType.SFX:
			type_volume = sfx_volume
		SoundType.UI:
			type_volume = ui_volume
		SoundType.AMBIENT:
			type_volume = ambient_volume
		SoundType.VOICE:
			type_volume = voice_volume
	
	player.volume_db = linear_to_db(volume * type_volume * master_volume)
	
	# Play sound
	player.play()
	
	return player

# Play music with crossfade
func play_music(path: String, crossfade_duration: float = 1.0) -> AudioStreamPlayer:
	if path.is_empty():
		stop_music()
		return null
	
	var sound = null
	
	# Check cache
	if cached_sounds.has(path):
		sound = cached_sounds[path]
	else:
		# Load music
		sound = load(path)
		if not sound:
			printerr("Failed to load music: " + path)
			return null
		
		# Add to cache
		cached_sounds[path] = sound
	
	# If no current music, start immediately
	if not current_music or not current_music.playing:
		current_music = _get_available_player(SoundType.MUSIC)
		current_music.stream = sound
		current_music.volume_db = linear_to_db(music_volume * master_volume)
		current_music.play()
		return current_music
	
	# If crossfading
	next_music = _get_available_player(SoundType.MUSIC)
	if next_music == current_music:
		next_music = _get_available_player(SoundType.MUSIC)
	
	next_music.stream = sound
	next_music.volume_db = linear_to_db(0.0)  # Start silent
	next_music.play()
	
	# Start transition
	transition_duration = crossfade_duration
	transition_time = 0.0
	transition_timer.wait_time = crossfade_duration
	transition_timer.start()
	
	return next_music

func _on_transition_complete():
	if current_music:
		current_music.stop()
	
	current_music = next_music
	next_music = null

func stop_music():
	if current_music:
		current_music.stop()
		current_music = null
	
	if next_music:
		next_music.stop()
		next_music = null
	
	if transition_timer.time_left > 0:
		transition_timer.stop()

# Play a UI sound
func play_ui_sound(path: String, volume: float = 1.0) -> AudioStreamPlayer:
	return play_sound(path, SoundType.UI, volume)

# Play a voice sound
func play_voice(path: String, volume: float = 1.0) -> AudioStreamPlayer:
	return play_sound(path, SoundType.VOICE, volume)

# Play an ambient sound
func play_ambient(path: String, volume: float = 1.0) -> AudioStreamPlayer:
	return play_sound(path, SoundType.AMBIENT, volume)

# Set volume for a specific type
func set_volume(sound_type: SoundType, volume: float):
	volume = clamp(volume, 0.0, 1.0)
	
	match sound_type:
		SoundType.MUSIC:
			music_volume = volume
			_update_bus_volume(music_bus_index, music_volume * master_volume)
		SoundType.SFX:
			sfx_volume = volume
			_update_bus_volume(sfx_bus_index, sfx_volume * master_volume)
		SoundType.UI:
			ui_volume = volume
			_update_bus_volume(ui_bus_index, ui_volume * master_volume)
		SoundType.AMBIENT:
			ambient_volume = volume
			_update_bus_volume(ambient_bus_index, ambient_volume * master_volume)
		SoundType.VOICE:
			voice_volume = volume
			_update_bus_volume(voice_bus_index, voice_volume * master_volume)

# Set master volume
func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	_update_bus_volume(master_bus_index, master_volume)
	
	# Update all other buses too
	_update_bus_volume(music_bus_index, music_volume * master_volume)
	_update_bus_volume(sfx_bus_index, sfx_volume * master_volume)
	_update_bus_volume(ui_bus_index, ui_volume * master_volume)
	_update_bus_volume(ambient_bus_index, ambient_volume * master_volume)
	_update_bus_volume(voice_bus_index, voice_volume * master_volume)

func _update_bus_volume(bus_idx: int, volume: float):
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(volume))
		
func get_volume(sound_type: SoundType) -> float:
	match sound_type:
		SoundType.MUSIC:
			return music_volume
		SoundType.SFX:
			return sfx_volume
		SoundType.UI:
			return ui_volume
		SoundType.AMBIENT:
			return ambient_volume
		SoundType.VOICE:
			return voice_volume
	return 1.0

func get_master_volume() -> float:
	return master_volume

# Clear all cached sounds
func clear_cache():
	cached_sounds.clear()

# Stop all sounds
func stop_all_sounds():
	stop_music()
	
	for player in sfx_players:
		player.stop()
	
	for player in ui_players:
		player.stop()
	
	for player in ambient_players:
		player.stop()
	
	for player in voice_players:
		player.stop() 