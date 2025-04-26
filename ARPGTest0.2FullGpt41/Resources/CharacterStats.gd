# CharacterStats.gd
extends Resource
class_name CharacterStats

@export var max_health: int = [PLAYER_MAX_HEALTH]
@export var speed: float = [PLAYER_MOVE_SPEED]
@export var attack: int = [PLAYER_ATTACK_DAMAGE]
@export var defense: int = [PLAYER_DEFENSE] 