extends Node
class_name EventBusClass

# Player events
signal player_health_changed(new_health, max_health)
signal player_mana_changed(new_mana, max_mana)
signal player_level_up(new_level)
signal player_experience_gained(current_exp, max_exp)
signal player_died
signal player_respawned

# Inventory events
signal item_added_to_inventory(item_data)
signal item_removed_from_inventory(item_data)
signal item_used(item_data)
signal inventory_updated

# Equipment events
signal item_equipped(slot_name, item_data)
signal item_unequipped(slot_name)
signal equipment_updated

# Enemy events
signal enemy_spawned(enemy)
signal enemy_killed(enemy, by_player)
signal enemy_damaged(enemy, damage_amount, hit_position)

# World events
signal level_loaded(level_data)
signal level_completed(level_data)
signal checkpoint_reached(checkpoint_id)
signal game_saved(save_slot)
signal game_loaded(save_slot)

# UI events
signal show_message(message_text, duration)
signal show_dialog(dialog_data)
signal show_tooltip(tooltip_data, position)
signal hide_tooltip
signal camera_sensitivity_changed(new_sensitivity)

# Game flow events
signal game_paused
signal game_resumed
signal game_started
signal game_over
signal main_menu_requested

# Audio events
signal play_sound(sound_name, volume_db, pitch_scale)
signal play_music(music_name, fade_duration)
signal stop_music(fade_duration)

# Achievement/Quest events
signal quest_started(quest_data)
signal quest_updated(quest_data, progress)
signal quest_completed(quest_data)
signal achievement_unlocked(achievement_id)

# Debug events
signal debug_log(message, category, severity)
signal toggle_debug_overlay
signal performance_measured(fps, memory_usage)

func _ready():
	# Set process mode to always process even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS 