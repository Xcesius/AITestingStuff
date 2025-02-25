extends Control
class_name LootSimulatorTool

# Node references (will be connected when scene is created)
var enemy_dropdown: OptionButton
var loot_table_dropdown: OptionButton
var simulation_count_slider: HSlider
var simulation_count_label: Label
var simulate_button: Button
var clear_button: Button
var results_container: VBoxContainer
var item_list: ItemList
var stats_label: Label
var progress_bar: ProgressBar
var simulation_thread: Thread

# Simulation data
var simulation_count: int = 1000
var current_enemy_type: String = ""
var current_loot_table: String = ""
var enemies_data: Dictionary = {}
var loot_tables_data: Dictionary = {}
var simulation_results: Dictionary = {}
var is_simulating: bool = false

signal simulation_completed(results)

func _ready():
	# This will be called when the scene is instantiated
	setup()

func setup():
	# Load available enemy types and loot tables
	load_enemy_data()
	load_loot_table_data()
	
	# Connect UI signals when scene is ready
	if simulate_button:
		simulate_button.connect("pressed", Callable(self, "_on_simulate_button_pressed"))
	
	if clear_button:
		clear_button.connect("pressed", Callable(self, "_on_clear_button_pressed"))
	
	if simulation_count_slider:
		simulation_count_slider.connect("value_changed", Callable(self, "_on_simulation_count_changed"))
		simulation_count_slider.value = simulation_count
	
	if simulation_count_label:
		simulation_count_label.text = str(simulation_count)
	
	# Populate dropdowns
	update_enemy_dropdown()
	update_loot_table_dropdown()

func load_enemy_data():
	# Load enemy data from resources
	var enemy_dir = "res://resources/enemies/"
	var dir = DirAccess.open(enemy_dir)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var resource_path = enemy_dir + file_name
				var resource = ResourceLoader.load(resource_path)
				
				if resource:
					var enemy_id = file_name.get_basename()
					enemies_data[enemy_id] = resource
			
			file_name = dir.get_next()
	else:
		# Fallback with some example enemies
		enemies_data = {
			"goblin": {
				"name": "Goblin",
				"loot_table": "goblin_loot"
			},
			"skeleton": {
				"name": "Skeleton",
				"loot_table": "skeleton_loot"
			},
			"boss": {
				"name": "Dungeon Boss",
				"loot_table": "boss_loot"
			}
		}

func load_loot_table_data():
	# Load loot table data from resources
	var loot_dir = "res://resources/loot_tables/"
	var dir = DirAccess.open(loot_dir)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var resource_path = loot_dir + file_name
				var resource = ResourceLoader.load(resource_path)
				
				if resource:
					var loot_id = file_name.get_basename()
					loot_tables_data[loot_id] = resource
			
			file_name = dir.get_next()
	else:
		# Fallback with example loot tables
		loot_tables_data = {
			"common_loot": {
				"name": "Common Loot",
				"entries": [
					{"item_id": "gold_coin", "weight": 80, "min_count": 1, "max_count": 10},
					{"item_id": "health_potion", "weight": 20, "min_count": 1, "max_count": 1},
					{"item_id": "arrow", "weight": 40, "min_count": 5, "max_count": 15}
				],
				"drop_chance": 0.8
			},
			"goblin_loot": {
				"name": "Goblin Loot",
				"entries": [
					{"item_id": "gold_coin", "weight": 70, "min_count": 1, "max_count": 5},
					{"item_id": "dagger", "weight": 10, "min_count": 1, "max_count": 1},
					{"item_id": "leather_scrap", "weight": 30, "min_count": 1, "max_count": 3}
				],
				"drop_chance": 0.7
			},
			"skeleton_loot": {
				"name": "Skeleton Loot",
				"entries": [
					{"item_id": "gold_coin", "weight": 60, "min_count": 2, "max_count": 8},
					{"item_id": "bone", "weight": 50, "min_count": 1, "max_count": 3},
					{"item_id": "rusty_sword", "weight": 15, "min_count": 1, "max_count": 1}
				],
				"drop_chance": 0.75
			},
			"boss_loot": {
				"name": "Boss Loot",
				"entries": [
					{"item_id": "gold_coin", "weight": 100, "min_count": 50, "max_count": 100},
					{"item_id": "magic_sword", "weight": 25, "min_count": 1, "max_count": 1},
					{"item_id": "magic_shield", "weight": 25, "min_count": 1, "max_count": 1},
					{"item_id": "rare_gem", "weight": 10, "min_count": 1, "max_count": 3}
				],
				"guaranteed_drops": ["boss_key"],
				"drop_chance": 1.0
			}
		}

func update_enemy_dropdown():
	if enemy_dropdown:
		enemy_dropdown.clear()
		
		enemy_dropdown.add_item("-- Select Enemy --")
		var index = 1
		
		for enemy_id in enemies_data:
			var enemy = enemies_data[enemy_id]
			var display_name = enemy.get("name", enemy_id)
			
			enemy_dropdown.add_item(display_name)
			enemy_dropdown.set_item_metadata(index, enemy_id)
			index += 1

func update_loot_table_dropdown():
	if loot_table_dropdown:
		loot_table_dropdown.clear()
		
		loot_table_dropdown.add_item("-- Select Loot Table --")
		var index = 1
		
		for loot_id in loot_tables_data:
			var loot_table = loot_tables_data[loot_id]
			var display_name = loot_table.get("name", loot_id)
			
			loot_table_dropdown.add_item(display_name)
			loot_table_dropdown.set_item_metadata(index, loot_id)
			index += 1

func _on_enemy_dropdown_item_selected(index: int):
	if index == 0:
		current_enemy_type = ""
	else:
		current_enemy_type = enemy_dropdown.get_item_metadata(index)
		
		# If this enemy has a loot table, auto-select it
		if enemies_data.has(current_enemy_type):
			var enemy = enemies_data[current_enemy_type]
			var loot_table_id = enemy.get("loot_table", "")
			
			if loot_table_id and loot_tables_data.has(loot_table_id):
				# Find index of loot table in dropdown
				for i in range(loot_table_dropdown.get_item_count()):
					if loot_table_dropdown.get_item_metadata(i) == loot_table_id:
						loot_table_dropdown.select(i)
						current_loot_table = loot_table_id
						break

func _on_loot_table_dropdown_item_selected(index: int):
	if index == 0:
		current_loot_table = ""
	else:
		current_loot_table = loot_table_dropdown.get_item_metadata(index)

func _on_simulation_count_changed(value: float):
	simulation_count = int(value)
	if simulation_count_label:
		simulation_count_label.text = str(simulation_count)

func _on_simulate_button_pressed():
	if is_simulating:
		return
		
	if current_loot_table == "":
		if current_enemy_type != "":
			# Try to get loot table from enemy
			var enemy = enemies_data[current_enemy_type]
			current_loot_table = enemy.get("loot_table", "")
			
		if current_loot_table == "":
			print("No loot table selected")
			return
	
	# Clear previous results
	simulation_results.clear()
	if item_list:
		item_list.clear()
	
	# Start simulation
	is_simulating = true
	if progress_bar:
		progress_bar.value = 0
		progress_bar.max_value = simulation_count
		progress_bar.visible = true
	
	# Update UI state
	if simulate_button:
		simulate_button.disabled = true
	
	# Start simulation in a thread to avoid freezing the UI
	simulation_thread = Thread.new()
	simulation_thread.start(Callable(self, "_run_simulation"))

func _run_simulation():
	var loot_table = loot_tables_data[current_loot_table]
	var total_drops = 0
	var no_drop_count = 0
	
	for i in range(simulation_count):
		var result = simulate_loot_drop(loot_table)
		
		if result.size() == 0:
			no_drop_count += 1
		else:
			total_drops += result.size()
			
			for item in result:
				var item_id = item["item_id"]
				var count = item["count"]
				
				if not simulation_results.has(item_id):
					simulation_results[item_id] = {
						"total_count": 0,
						"drop_count": 0, # Number of times this item dropped
						"min_count": count,
						"max_count": count
					}
				
				simulation_results[item_id]["total_count"] += count
				simulation_results[item_id]["drop_count"] += 1
				simulation_results[item_id]["min_count"] = min(simulation_results[item_id]["min_count"], count)
				simulation_results[item_id]["max_count"] = max(simulation_results[item_id]["max_count"], count)
		
		# Update progress bar
		if progress_bar and i % 100 == 0:
			call_deferred("_update_progress", i)
	
	# Calculate statistics
	var drop_rate = float(simulation_count - no_drop_count) / float(simulation_count) * 100.0
	var avg_items_per_drop = float(total_drops) / float(simulation_count - no_drop_count) if (simulation_count - no_drop_count) > 0 else 0
	
	# Add statistics to results
	simulation_results["_stats"] = {
		"total_simulations": simulation_count,
		"no_drop_count": no_drop_count,
		"drop_rate": drop_rate,
		"avg_items_per_drop": avg_items_per_drop
	}
	
	# Update UI on main thread
	call_deferred("_update_results")

func _update_progress(progress: int):
	if progress_bar:
		progress_bar.value = progress

func _update_results():
	# Update item list
	if item_list:
		item_list.clear()
		
		for item_id in simulation_results:
			if item_id == "_stats":
				continue
				
			var result = simulation_results[item_id]
			var drop_rate = float(result["drop_count"]) / float(simulation_results["_stats"]["total_simulations"]) * 100.0
			var avg_per_drop = float(result["total_count"]) / float(result["drop_count"]) if result["drop_count"] > 0 else 0
			
			var text = "%s: %d drops (%.2f%%), Avg: %.2f per drop, Range: %d-%d" % [
				item_id,
				result["total_count"],
				drop_rate,
				avg_per_drop,
				result["min_count"],
				result["max_count"]
			]
			
			item_list.add_item(text)
	
	# Update stats label
	if stats_label:
		var stats = simulation_results["_stats"]
		stats_label.text = "Simulations: %d\nDrop Rate: %.2f%%\nAvg Items Per Drop: %.2f" % [
			stats["total_simulations"],
			stats["drop_rate"],
			stats["avg_items_per_drop"]
		]
	
	# Reset UI state
	if progress_bar:
		progress_bar.visible = false
	
	if simulate_button:
		simulate_button.disabled = false
	
	is_simulating = false
	
	# Clean up thread
	simulation_thread.wait_to_finish()
	
	# Emit signal
	simulation_completed.emit(simulation_results)

func _on_clear_button_pressed():
	if item_list:
		item_list.clear()
	
	if stats_label:
		stats_label.text = ""
	
	simulation_results.clear()

func simulate_loot_drop(loot_table):
	var result = []
	
	# Add guaranteed drops
	if loot_table.has("guaranteed_drops"):
		for item_id in loot_table["guaranteed_drops"]:
			result.append({"item_id": item_id, "count": 1})
	
	# Check if we get any random drops
	var drop_chance = loot_table.get("drop_chance", 0.5)
	if randf() > drop_chance:
		return result
	
	# Roll for random drops
	var entries = loot_table.get("entries", [])
	if entries.size() == 0:
		return result
	
	# Calculate total weight
	var total_weight = 0
	for entry in entries:
		total_weight += entry.get("weight", 1)
	
	if total_weight > 0:
		var roll = randi_range(1, total_weight)
		var current_weight = 0
		
		for entry in entries:
			current_weight += entry.get("weight", 1)
			if roll <= current_weight:
				var min_count = entry.get("min_count", 1)
				var max_count = entry.get("max_count", 1)
				var count = randi_range(min_count, max_count)
				
				result.append({
					"item_id": entry.get("item_id", "unknown"),
					"count": count
				})
				break
	
	return result

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# Clean up thread if still running when node is deleted
		if is_simulating and simulation_thread and simulation_thread.is_started():
			simulation_thread.wait_to_finish() 