# AudioComponent.gd
class_name AudioComponent
extends Node

@export var sound_effects: Dictionary = {} # name -> AudioStream

func play_sound(name: String) -> void:
    if sound_effects.has(name):
        var player = AudioStreamPlayer.new()
        player.stream = sound_effects[name]
        add_child(player)
        player.play() 