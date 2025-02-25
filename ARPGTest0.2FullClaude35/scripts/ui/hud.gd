class_name HUD
extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthLabel
@onready var inventory_ui: Control = $InventoryUI

var player: PlayerController

func _ready() -> void:
    inventory_ui.hide()
    
    # Wait a frame to find player
    await get_tree().process_frame
    player = get_tree().get_first_node_in_group("player")
    
    if player and player.stats:
        player.stats.health_changed.connect(_on_player_health_changed)
        _update_health_display(player.stats.current_health, player.stats.max_health)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_inventory"):
        toggle_inventory()

func toggle_inventory() -> void:
    inventory_ui.visible = not inventory_ui.visible
    
    # Optionally pause the game when inventory is open
    get_tree().paused = inventory_ui.visible

func _update_health_display(current: float, maximum: float) -> void:
    if health_bar:
        health_bar.max_value = maximum
        health_bar.value = current
    
    if health_label:
        health_label.text = "%d/%d" % [current, maximum]

func _on_player_health_changed(new_health: float, max_health: float) -> void:
    _update_health_display(new_health, max_health) 