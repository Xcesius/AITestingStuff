extends CharacterBody2D
class_name NPCBase

signal interaction_started(npc_id)
signal interaction_ended(npc_id)

# NPC Configuration
@export var npc_id: String = ""
@export var npc_name: String = "NPC"
@export var interaction_radius: float = 50.0
@export var dialogue_path: String = ""
@export var face_player_on_interact: bool = true
@export var can_move: bool = false
@export var random_movement: bool = false
@export var is_vendor: bool = false
@export var is_quest_giver: bool = false
@export var inventory_id: String = ""

# Movement variables
@export var move_speed: float = 50.0
@export var idle_time_min: float = 2.0
@export var idle_time_max: float = 5.0
@export var movement_distance: float = 100.0

# Visual components
@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var interaction_area = $InteractionArea
@onready var dialogue_indicator = $DialogueIndicator

# State machine components
var current_state = "Idle"
var can_interact: bool = true
var is_talking: bool = false
var movement_target: Vector2 = Vector2.ZERO
var idle_timer: Timer = null
var current_dialogue: Array = []
var dialogue_index: int = 0
var available_quests: Array = []
var active_quests: Array = []
var vendor_items: Array = []

# References
var player_in_range: bool = false
var player_ref: Node2D = null
var dialogue_UI: Node = null
var quest_manager: Node = null
var quest_UI: Node = null
var vendor_UI: Node = null

func _ready():
	# Setup NPC if ID is missing
	if npc_id.is_empty():
		npc_id = name.to_lower()
	
	# Setup interaction area
	interaction_area.connect("body_entered", Callable(self, "_on_interaction_area_body_entered"))
	interaction_area.connect("body_exited", Callable(self, "_on_interaction_area_body_exited"))
	
	# Set interaction area radius
	var shape = interaction_area.get_node("CollisionShape2D").shape
	if shape is CircleShape2D:
		shape.radius = interaction_radius
	
	# Create idle timer for random movement
	if random_movement and can_move:
		idle_timer = Timer.new()
		add_child(idle_timer)
		idle_timer.connect("timeout", Callable(self, "_on_idle_timer_timeout"))
		idle_timer.one_shot = true
		idle_timer.wait_time = randf_range(idle_time_min, idle_time_max)
		idle_timer.start()
	
	# Initialize dialogue indicator
	if dialogue_indicator:
		dialogue_indicator.visible = false
	
	# Get node references
	dialogue_UI = get_node_or_null("/root/DialogueManager")
	quest_manager = get_node_or_null("/root/QuestManager")
	quest_UI = get_node_or_null("/root/QuestUI")
	vendor_UI = get_node_or_null("/root/VendorUI")
	
	# Load dialogue if specified
	if not dialogue_path.is_empty():
		load_dialogue()
	
	# Load quests if NPC is a quest giver
	if is_quest_giver and quest_manager:
		load_available_quests()
	
	# Load vendor items if NPC is a vendor
	if is_vendor and not inventory_id.is_empty():
		load_vendor_items()

func _physics_process(delta):
	if can_move and current_state == "Moving":
		_handle_movement(delta)
	
	# Update animation based on state and velocity
	_update_animation()

func _handle_movement(delta):
	if movement_target != Vector2.ZERO:
		var direction = global_position.direction_to(movement_target)
		var distance = global_position.distance_to(movement_target)
		
		if distance < 5.0:
			# Target reached, go back to idle
			velocity = Vector2.ZERO
			current_state = "Idle"
			
			if idle_timer:
				idle_timer.wait_time = randf_range(idle_time_min, idle_time_max)
				idle_timer.start()
		else:
			# Move towards target
			velocity = direction * move_speed
			move_and_slide()
			
			# Update facing direction
			if direction.x < 0:
				sprite.flip_h = true
			elif direction.x > 0:
				sprite.flip_h = false

func _update_animation():
	if animation_player:
		var anim_name = current_state.to_lower()
		
		if current_state == "Moving" and velocity == Vector2.ZERO:
			anim_name = "idle"
		elif current_state == "Idle" and velocity != Vector2.ZERO:
			anim_name = "moving"
		
		if animation_player.has_animation(anim_name) and animation_player.current_animation != anim_name:
			animation_player.play(anim_name)

func interact():
	if not can_interact or is_talking:
		return
	
	# Emit interaction signal
	interaction_started.emit(npc_id)
	EventBus.emit_signal("npc_interaction", npc_id)
	
	# Face player if enabled
	if face_player_on_interact and player_ref:
		var direction = global_position.direction_to(player_ref.global_position)
		if direction.x < 0:
			sprite.flip_h = true
		else:
			sprite.flip_h = false
	
	# Start dialogue if available
	if not current_dialogue.is_empty() and dialogue_UI:
		is_talking = true
		dialogue_UI.start_dialogue(current_dialogue, self)
	elif is_quest_giver and not available_quests.is_empty() and quest_UI:
		is_talking = true
		quest_UI.show_available_quests(self, available_quests)
	elif is_vendor and vendor_UI:
		is_talking = true
		vendor_UI.show_vendor_items(self, vendor_items)
	else:
		# Simple interaction with no dialogue
		end_interaction()

func end_interaction():
	is_talking = false
	interaction_ended.emit(npc_id)
	
	# Resume normal activity
	if random_movement and can_move and idle_timer and not idle_timer.is_stopped():
		idle_timer.start()

func load_dialogue():
	var file = FileAccess.open(dialogue_path, FileAccess.READ)
	if file:
		var test_json_conv = JSON.new()
		test_json_conv.parse(file.get_as_text())
		var dialogue_data = test_json_conv.get_data()
		
		if dialogue_data and dialogue_data.has("dialogues"):
			current_dialogue = dialogue_data.dialogues
	else:
		printerr("Failed to load dialogue file: " + dialogue_path)

func load_available_quests():
	# This would typically load from a data file or from the quest manager
	# For simplicity, we'll just get any quests this NPC can give from quest manager
	if quest_manager:
		available_quests = []
		active_quests = []
		
		for quest_id in quest_manager.quests:
			var quest = quest_manager.quests[quest_id]
			
			if quest.has("quest_giver") and quest.quest_giver == npc_id:
				if quest_manager.is_quest_active(quest_id):
					active_quests.append(quest_id)
				elif not quest_manager.is_quest_completed(quest_id) and not quest_manager.is_quest_failed(quest_id):
					# Check prerequisites
					if quest_manager._check_prerequisites(quest):
						available_quests.append(quest_id)
		
		# Update dialogue indicator based on available quests
		if dialogue_indicator:
			dialogue_indicator.visible = not available_quests.is_empty() or not active_quests.is_empty()

func load_vendor_items():
	# This would typically load from a data file
	# For simplicity, we'll create a placeholder array
	vendor_items = []
	
	var inventory_file = "res://data/vendor_inventories/" + inventory_id + ".json"
	var file = FileAccess.open(inventory_file, FileAccess.READ)
	
	if file:
		var test_json_conv = JSON.new()
		test_json_conv.parse(file.get_as_text())
		var inventory_data = test_json_conv.get_data()
		
		if inventory_data and inventory_data.has("items"):
			vendor_items = inventory_data.items
	else:
		# Create default vendor items if no file exists
		vendor_items = [
			{"id": "potion_health", "price": 50, "quantity": 10},
			{"id": "potion_mana", "price": 75, "quantity": 5}
		]

func move_to_random_point():
	if not can_move or is_talking:
		return
	
	var random_offset = Vector2(
		randf_range(-movement_distance, movement_distance),
		randf_range(-movement_distance, movement_distance)
	)
	
	movement_target = global_position + random_offset
	current_state = "Moving"

func _on_idle_timer_timeout():
	if random_movement and can_move and not is_talking:
		move_to_random_point()

func _on_interaction_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		player_ref = body
		
		# Show indicator if available
		if dialogue_indicator:
			dialogue_indicator.visible = true

func _on_interaction_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		player_ref = null
		
		# Hide indicator
		if dialogue_indicator:
			dialogue_indicator.visible = not available_quests.is_empty() or not active_quests.is_empty()

func update_quest_status():
	if is_quest_giver and quest_manager:
		# Reload available quests
		load_available_quests()

func get_active_quest():
	if not active_quests.is_empty():
		return active_quests[0]
	return ""

func get_first_available_quest():
	if not available_quests.is_empty():
		return available_quests[0]
	return ""

func complete_active_quest(quest_id: String):
	if quest_manager and quest_manager.is_quest_active(quest_id):
		# Complete the quest if all objectives are done
		quest_manager.complete_quest(quest_id)
		
		# Update quest lists
		var index = active_quests.find(quest_id)
		if index >= 0:
			active_quests.remove_at(index)
		
		# Update dialogue indicator
		if dialogue_indicator:
			dialogue_indicator.visible = not available_quests.is_empty() or not active_quests.is_empty()
		
		return true
	
	return false 