extends Node
class_name SaveSystem

const SAVE_DIR = "user://saves/"
const SAVE_FILE_EXTENSION = ".json"
const ENCRYPTION_PASSWORD = "rpg_prototype_save_v1"
const MAX_SAVE_SLOTS = 5

var save_data = {}
var current_save_slot = 0

func _ready():
	# Create saves directory if it doesn't exist
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(SAVE_DIR):
		dir.make_dir(SAVE_DIR)
	
	# Initialize save data structure
	reset_save_data()

func reset_save_data():
	save_data = {
		"player": {
			"stats": {},
			"inventory": [],
			"equipment": {},
			"position": {"x": 0, "y": 0},
			"current_map": "",
		},
		"world": {
			"discovered_maps": [],
			"completed_quests": [],
			"active_quests": [],
			"game_time": 0,
			"defeated_enemies": {}
		},
		"game_settings": {
			"audio_settings": {
				"master_volume": 1.0,
				"music_volume": 1.0,
				"sfx_volume": 1.0
			},
			"gameplay_settings": {
				"difficulty": "normal",
				"camera_shake": true,
				"damage_numbers": true
			}
		},
		"metadata": {
			"save_date": "",
			"play_time": 0,
			"version": "0.2"
		}
	}

func get_save_list() -> Array:
	var saves = []
	var dir = DirAccess.open(SAVE_DIR)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(SAVE_FILE_EXTENSION):
				var save_slot = file_name.replace(SAVE_FILE_EXTENSION, "").to_int()
				var save_path = SAVE_DIR + file_name
				
				# Load minimal metadata
				var save_info = get_save_metadata(save_path)
				save_info["slot"] = save_slot
				saves.append(save_info)
			
			file_name = dir.get_next()
	
	# Sort saves by slot number
	saves.sort_custom(func(a, b): return a["slot"] < b["slot"])
	
	return saves

func get_save_metadata(save_path: String) -> Dictionary:
	var metadata = {
		"slot": -1,
		"save_date": "",
		"play_time": 0,
		"version": "",
		"player_level": 1,
		"player_name": "Adventurer"
	}
	
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.READ, ENCRYPTION_PASSWORD)
		if file:
			var test_json_conv = JSON.new()
			test_json_conv.parse(file.get_as_text())
			var data = test_json_conv.get_data()
			
			if data and data.has("metadata"):
				metadata["save_date"] = data.metadata.save_date
				metadata["play_time"] = data.metadata.play_time
				metadata["version"] = data.metadata.version
				
				if data.has("player") and data.player.has("stats"):
					if data.player.stats.has("level"):
						metadata["player_level"] = data.player.stats.level
					if data.player.stats.has("name"):
						metadata["player_name"] = data.player.stats.name
	
	return metadata

func save_game(slot: int) -> bool:
	# Update metadata
	save_data.metadata.save_date = Time.get_datetime_string_from_system()
	save_data.metadata.play_time = OS.get_ticks_msec() / 1000
	
	# Save player data
	var player = get_tree().get_first_node_in_group("player")
	if player:
		save_data.player.stats = _get_serialized_stats(player.stats)
		save_data.player.position = {"x": player.global_position.x, "y": player.global_position.y}
		save_data.player.inventory = _get_serialized_inventory(player.inventory)
		save_data.player.equipment = _get_serialized_equipment(player.equipment)
		
		# Get current scene name
		var current_scene = get_tree().current_scene
		save_data.player.current_map = current_scene.name
	
	# Save world data
	save_data.world.game_time = Time.get_ticks_msec() / 1000
	
	# Save quests
	var quest_manager = get_node("/root/QuestManager")
	if quest_manager:
		save_data.world.active_quests = quest_manager.get_active_quests_data()
		save_data.world.completed_quests = quest_manager.get_completed_quests_data()
	
	# Convert to JSON
	var json_string = JSON.stringify(save_data)
	
	# Save to file
	var save_path = SAVE_DIR + str(slot) + SAVE_FILE_EXTENSION
	var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.WRITE, ENCRYPTION_PASSWORD)
	
	if file:
		file.store_string(json_string)
		current_save_slot = slot
		return true
	
	print("Error saving game: " + str(FileAccess.get_open_error()))
	return false

func load_game(slot: int) -> bool:
	var save_path = SAVE_DIR + str(slot) + SAVE_FILE_EXTENSION
	
	if not FileAccess.file_exists(save_path):
		print("Save file does not exist: " + save_path)
		return false
	
	var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.READ, ENCRYPTION_PASSWORD)
	if not file:
		print("Error opening save file: " + str(FileAccess.get_open_error()))
		return false
	
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var data = test_json_conv.get_data()
	
	if data == null:
		print("Error parsing JSON from save file")
		return false
	
	# Store loaded data
	save_data = data
	current_save_slot = slot
	
	# Load scene based on saved location
	if data.player.has("current_map") and data.player.current_map != "":
		call_deferred("_load_map_and_position", data.player.current_map, Vector2(data.player.position.x, data.player.position.y))
	
	# Apply settings
	if data.has("game_settings"):
		_apply_game_settings(data.game_settings)
	
	return true

func _load_map_and_position(map_name: String, position: Vector2):
	# Get the map scene path
	var map_path = "res://scenes/maps/" + map_name + ".tscn"
	
	# Check if scene exists
	if ResourceLoader.exists(map_path):
		# Change scene
		get_tree().change_scene_to_file(map_path)
		
		# Wait for scene to load and set player position
		await get_tree().process_frame
		
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.global_position = position
			
			# Restore player stats
			_apply_player_data(player)
	else:
		print("Error: Map scene does not exist: " + map_path)

func _apply_player_data(player):
	# Apply stats
	if save_data.player.has("stats"):
		_apply_serialized_stats(player.stats, save_data.player.stats)
	
	# Apply inventory
	if save_data.player.has("inventory"):
		_apply_serialized_inventory(player.inventory, save_data.player.inventory)
	
	# Apply equipment
	if save_data.player.has("equipment"):
		_apply_serialized_equipment(player.equipment, save_data.player.equipment)

func delete_save(slot: int) -> bool:
	var save_path = SAVE_DIR + str(slot) + SAVE_FILE_EXTENSION
	
	if FileAccess.file_exists(save_path):
		var err = DirAccess.remove_absolute(save_path)
		if err != OK:
			print("Error deleting save file: " + str(err))
			return false
		return true
	
	return false

func _get_serialized_stats(stats) -> Dictionary:
	var serialized = {}
	
	# Convert stats resource to dictionary
	for property in stats.get_property_list():
		var name = property.name
		if name != "Reference" and name != "Resource" and name != "resource_local_to_scene" and name != "resource_path" and name != "script":
			serialized[name] = stats.get(name)
	
	return serialized

func _apply_serialized_stats(stats_resource, serialized_data: Dictionary):
	for key in serialized_data:
		if stats_resource.get(key) != null:
			stats_resource.set(key, serialized_data[key])

func _get_serialized_inventory(inventory) -> Array:
	var serialized = []
	
	for item_id in inventory.items:
		var item = inventory.items[item_id]
		serialized.append({
			"item_id": item.id,
			"quantity": item.quantity,
			"properties": item.properties
		})
	
	return serialized

func _apply_serialized_inventory(inventory, serialized_data: Array):
	# Clear current inventory
	inventory.clear()
	
	# Add items from save
	for item_data in serialized_data:
		inventory.add_item(item_data.item_id, item_data.quantity, item_data.properties)

func _get_serialized_equipment(equipment) -> Dictionary:
	var serialized = {}
	
	for slot in equipment.equipped_items:
		var item = equipment.equipped_items[slot]
		if item:
			serialized[slot] = {
				"item_id": item.id,
				"properties": item.properties
			}
	
	return serialized

func _apply_serialized_equipment(equipment, serialized_data: Dictionary):
	# Clear current equipment
	equipment.unequip_all()
	
	# Equip items from save
	for slot in serialized_data:
		var item_data = serialized_data[slot]
		equipment.equip_item_by_id(item_data.item_id, slot, item_data.properties)

func _apply_game_settings(settings: Dictionary):
	if settings.has("audio_settings"):
		var audio_settings = settings.audio_settings
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(audio_settings.master_volume))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(audio_settings.music_volume)) 
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(audio_settings.sfx_volume)) 