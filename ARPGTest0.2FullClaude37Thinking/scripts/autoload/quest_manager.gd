extends Node
class_name QuestManager

# Quest States
enum QuestState {
	INACTIVE,
	ACTIVE,
	COMPLETE,
	FAILED
}

# Quest objective types
enum ObjectiveType {
	KILL_ENEMY,
	COLLECT_ITEM,
	TALK_TO_NPC,
	REACH_LOCATION,
	USE_ITEM,
	CUSTOM
}

signal quest_started(quest_id)
signal quest_updated(quest_id, objective_id, progress, total)
signal quest_completed(quest_id)
signal quest_failed(quest_id)
signal objective_completed(quest_id, objective_id)

# All quests in the game
var quests = {}

# Active quests
var active_quests = {}

# Completed quests
var completed_quests = []

# Failed quests
var failed_quests = []

func _ready():
	# Connect to event bus
	EventBus.connect("enemy_killed", Callable(self, "_on_enemy_killed"))
	EventBus.connect("item_collected", Callable(self, "_on_item_collected"))
	EventBus.connect("npc_interaction", Callable(self, "_on_npc_interaction"))
	EventBus.connect("location_reached", Callable(self, "_on_location_reached"))
	EventBus.connect("item_used", Callable(self, "_on_item_used"))
	EventBus.connect("custom_objective_updated", Callable(self, "_on_custom_objective_updated"))

# Register a quest with the manager
func register_quest(quest_data: Dictionary) -> bool:
	if not _validate_quest_data(quest_data):
		printerr("Invalid quest data for quest: " + str(quest_data.get("id", "unknown")))
		return false
	
	var quest_id = quest_data.id
	
	# Store quest
	quests[quest_id] = quest_data
	
	# If quest was in progress previously (loaded from save), update its state
	if active_quests.has(quest_id):
		var saved_progress = active_quests[quest_id].objectives_progress
		
		# Update with saved progress
		for obj_id in saved_progress:
			if quest_data.objectives.has(obj_id):
				quest_data.objectives[obj_id].progress = saved_progress[obj_id]
	
	return true

# Start a quest
func start_quest(quest_id: String) -> bool:
	if not quests.has(quest_id):
		printerr("Attempting to start unknown quest: " + quest_id)
		return false
	
	var quest = quests[quest_id]
	
	# Check prerequisites
	if not _check_prerequisites(quest):
		print("Prerequisites not met for quest: " + quest_id)
		return false
	
	# Quest already active
	if active_quests.has(quest_id):
		return true
	
	# Quest already completed
	if completed_quests.has(quest_id):
		return true
	
	# Create active quest entry
	active_quests[quest_id] = {
		"id": quest_id,
		"state": QuestState.ACTIVE,
		"objectives_progress": {},
		"start_time": Time.get_unix_time_from_system()
	}
	
	# Initialize objectives progress
	for obj_id in quest.objectives:
		active_quests[quest_id].objectives_progress[obj_id] = 0
	
	# Emit signal
	quest_started.emit(quest_id)
	
	# Trigger any immediate callbacks
	if quest.has("on_start") and quest.on_start is Callable:
		quest.on_start.call(quest_id)
	
	return true

# Check if quest prerequisites are met
func _check_prerequisites(quest: Dictionary) -> bool:
	if not quest.has("prerequisites"):
		return true
	
	var prerequisites = quest.prerequisites
	
	# Check required quests completed
	if prerequisites.has("completed_quests"):
		for req_quest in prerequisites.completed_quests:
			if not completed_quests.has(req_quest):
				return false
	
	# Check required level
	if prerequisites.has("min_level"):
		var player = get_tree().get_first_node_in_group("player")
		if player and player.stats.level < prerequisites.min_level:
			return false
	
	# Check required items
	if prerequisites.has("required_items"):
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("has_items"):
			for item_id in prerequisites.required_items:
				var amount = prerequisites.required_items[item_id]
				if not player.has_items(item_id, amount):
					return false
	
	return true

# Update objective progress
func update_objective(quest_id: String, objective_id: String, progress: int) -> bool:
	if not active_quests.has(quest_id) or active_quests[quest_id].state != QuestState.ACTIVE:
		return false
	
	if not quests.has(quest_id) or not quests[quest_id].objectives.has(objective_id):
		return false
	
	var quest = quests[quest_id]
	var objective = quest.objectives[objective_id]
	var current_progress = active_quests[quest_id].objectives_progress[objective_id]
	var target_amount = objective.amount
	
	# Update progress
	current_progress = min(current_progress + progress, target_amount)
	active_quests[quest_id].objectives_progress[objective_id] = current_progress
	
	# Emit progress update signal
	quest_updated.emit(quest_id, objective_id, current_progress, target_amount)
	
	# Check if objective completed
	if current_progress >= target_amount:
		_complete_objective(quest_id, objective_id)
	
	# Check if quest completed
	_check_quest_completion(quest_id)
	
	return true

# Mark objective as completed
func _complete_objective(quest_id: String, objective_id: String):
	if not active_quests.has(quest_id) or not quests.has(quest_id):
		return
	
	var quest = quests[quest_id]
	if not quest.objectives.has(objective_id):
		return
	
	var objective = quest.objectives[objective_id]
	
	# Ensure progress is maxed
	active_quests[quest_id].objectives_progress[objective_id] = objective.amount
	
	# Mark as completed
	objective.completed = true
	
	# Emit signal
	objective_completed.emit(quest_id, objective_id)
	
	# Trigger objective completion callback
	if objective.has("on_complete") and objective.on_complete is Callable:
		objective.on_complete.call(quest_id, objective_id)

# Check if all quest objectives are completed
func _check_quest_completion(quest_id: String):
	if not active_quests.has(quest_id) or not quests.has(quest_id):
		return
	
	var quest = quests[quest_id]
	var all_completed = true
	
	# Check each objective
	for obj_id in quest.objectives:
		var objective = quest.objectives[obj_id]
		var current_progress = active_quests[quest_id].objectives_progress[obj_id]
		var target_amount = objective.amount
		
		# If any required objective is not complete, quest isn't complete
		if not objective.optional and current_progress < target_amount:
			all_completed = false
			break
	
	if all_completed:
		complete_quest(quest_id)

# Complete a quest
func complete_quest(quest_id: String) -> bool:
	if not active_quests.has(quest_id) or active_quests[quest_id].state != QuestState.ACTIVE:
		return false
	
	if not quests.has(quest_id):
		return false
	
	var quest = quests[quest_id]
	
	# Update quest state
	active_quests[quest_id].state = QuestState.COMPLETE
	active_quests[quest_id].completion_time = Time.get_unix_time_from_system()
	
	# Move to completed list
	completed_quests.append(quest_id)
	
	# Emit signal
	quest_completed.emit(quest_id)
	
	# Award rewards
	if quest.has("rewards"):
		_grant_quest_rewards(quest_id, quest.rewards)
	
	# Trigger completion callback
	if quest.has("on_complete") and quest.on_complete is Callable:
		quest.on_complete.call(quest_id)
	
	# Start follow-up quests
	if quest.has("next_quests"):
		for next_quest_id in quest.next_quests:
			start_quest(next_quest_id)
	
	return true

# Fail a quest
func fail_quest(quest_id: String, reason: String = "") -> bool:
	if not active_quests.has(quest_id) or active_quests[quest_id].state != QuestState.ACTIVE:
		return false
	
	if not quests.has(quest_id):
		return false
	
	var quest = quests[quest_id]
	
	# Update quest state
	active_quests[quest_id].state = QuestState.FAILED
	active_quests[quest_id].failure_time = Time.get_unix_time_from_system()
	active_quests[quest_id].failure_reason = reason
	
	# Move to failed list
	failed_quests.append(quest_id)
	
	# Emit signal
	quest_failed.emit(quest_id)
	
	# Trigger failure callback
	if quest.has("on_fail") and quest.on_fail is Callable:
		quest.on_fail.call(quest_id, reason)
	
	return true

# Award quest rewards
func _grant_quest_rewards(quest_id: String, rewards: Dictionary):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Experience points
	if rewards.has("xp") and player.stats.has_method("add_experience"):
		player.stats.add_experience(rewards.xp)
	
	# Gold/currency
	if rewards.has("gold") and player.has_method("add_gold"):
		player.add_gold(rewards.gold)
	
	# Items
	if rewards.has("items") and player.has_method("add_item"):
		for item_id in rewards.items:
			var quantity = rewards.items[item_id]
			player.add_item(item_id, quantity)
	
	# Equipment
	if rewards.has("equipment") and player.has_method("add_item"):
		for item_id in rewards.equipment:
			player.add_item(item_id, 1, rewards.equipment[item_id])

# Event handlers for automated objective updates
func _on_enemy_killed(enemy_type: String, enemy_id: String):
	_update_objectives_of_type(ObjectiveType.KILL_ENEMY, enemy_type)

func _on_item_collected(item_id: String, quantity: int):
	_update_objectives_of_type(ObjectiveType.COLLECT_ITEM, item_id, quantity)

func _on_npc_interaction(npc_id: String):
	_update_objectives_of_type(ObjectiveType.TALK_TO_NPC, npc_id)

func _on_location_reached(location_id: String):
	_update_objectives_of_type(ObjectiveType.REACH_LOCATION, location_id)

func _on_item_used(item_id: String, target_id: String = ""):
	_update_objectives_of_type(ObjectiveType.USE_ITEM, item_id)

func _on_custom_objective_updated(quest_id: String, objective_id: String, progress: int):
	update_objective(quest_id, objective_id, progress)

# Helper to update all relevant objectives of a certain type
func _update_objectives_of_type(objective_type: ObjectiveType, target_id: String, amount: int = 1):
	for quest_id in active_quests:
		if active_quests[quest_id].state != QuestState.ACTIVE:
			continue
		
		var quest = quests[quest_id]
		
		for obj_id in quest.objectives:
			var objective = quest.objectives[obj_id]
			
			if objective.type == objective_type and objective.target_id == target_id:
				update_objective(quest_id, obj_id, amount)

# Validate quest data format
func _validate_quest_data(quest_data: Dictionary) -> bool:
	# Check required fields
	if not quest_data.has("id") or not quest_data.has("title") or not quest_data.has("objectives"):
		return false
	
	# Validate objectives
	for obj_id in quest_data.objectives:
		var obj = quest_data.objectives[obj_id]
		
		if not obj.has("type") or not obj.has("description") or not obj.has("amount"):
			return false
		
		# Validate target_id for applicable objective types
		if obj.type != ObjectiveType.CUSTOM and not obj.has("target_id"):
			return false
	
	return true

# Get active quest data for saving
func get_active_quests_data() -> Array:
	var quests_data = []
	
	for quest_id in active_quests:
		quests_data.append(active_quests[quest_id])
	
	return quests_data

# Get completed quests for saving
func get_completed_quests_data() -> Array:
	return completed_quests.duplicate()

# Load quests from saved data
func load_quests_data(active_data: Array, completed_data: Array):
	# Clear current state
	active_quests.clear()
	completed_quests.clear()
	
	# Load active quests
	for quest_data in active_data:
		if quest_data.has("id"):
			active_quests[quest_data.id] = quest_data
	
	# Load completed quests
	completed_quests = completed_data.duplicate()

# Get quest by ID
func get_quest(quest_id: String) -> Dictionary:
	if quests.has(quest_id):
		return quests[quest_id]
	return {}

# Get objective progress
func get_objective_progress(quest_id: String, objective_id: String) -> Dictionary:
	if not active_quests.has(quest_id) or not quests.has(quest_id):
		return {"current": 0, "total": 0, "completed": false}
	
	if not quests[quest_id].objectives.has(objective_id):
		return {"current": 0, "total": 0, "completed": false}
	
	var current = active_quests[quest_id].objectives_progress[objective_id]
	var total = quests[quest_id].objectives[objective_id].amount
	var completed = current >= total
	
	return {"current": current, "total": total, "completed": completed}

# Check if quest is active
func is_quest_active(quest_id: String) -> bool:
	return active_quests.has(quest_id) and active_quests[quest_id].state == QuestState.ACTIVE

# Check if quest is completed
func is_quest_completed(quest_id: String) -> bool:
	return completed_quests.has(quest_id)

# Check if quest is failed
func is_quest_failed(quest_id: String) -> bool:
	return failed_quests.has(quest_id)

# Get list of all active quests
func get_active_quest_ids() -> Array:
	return active_quests.keys()

# Get list of all completed quests
func get_completed_quest_ids() -> Array:
	return completed_quests

# Abandon a quest
func abandon_quest(quest_id: String) -> bool:
	if not active_quests.has(quest_id):
		return false
	
	# Remove from active quests
	active_quests.erase(quest_id)
	
	return true

# Create a basic quest data structure
static func create_quest_template(id: String, title: String, description: String) -> Dictionary:
	return {
		"id": id,
		"title": title,
		"description": description,
		"objectives": {},
		"rewards": {
			"xp": 0,
			"gold": 0,
			"items": {}
		},
		"prerequisites": {}
	} 