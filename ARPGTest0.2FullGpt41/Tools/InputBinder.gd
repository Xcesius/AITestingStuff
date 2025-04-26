# InputBinder.gd
extends Node

func _ready():
    _bind_inputs()

func _bind_inputs():
    # Add input actions if not present
    var actions = ["ui_up", "ui_down", "ui_left", "ui_right", "attack", "inventory_toggle"]
    for action in actions:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
    # [INPUT_BINDING_LOGIC]

func _input(event):
    if event.is_action_pressed("inventory_toggle"):
        # [INVENTORY_UI_TOGGLE_LOGIC]
        pass 