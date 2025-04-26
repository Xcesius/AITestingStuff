# AbilityComponent.gd
extends Node

@export var abilities: Array = [] # Array of ability data/resources

signal ability_used(ability)

func add_ability(ability):
    if ability not in abilities:
        abilities.append(ability)

func remove_ability(ability):
    if ability in abilities:
        abilities.erase(ability)

func use_ability(ability, target=null):
    if ability in abilities:
        # [ABILITY_USE_LOGIC]
        emit_signal("ability_used", ability) 