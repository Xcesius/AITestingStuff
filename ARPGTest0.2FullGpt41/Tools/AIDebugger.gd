# AIDebugger.gd
tool
extends Node

var log: Array = []

func log_state_transition(enemy, new_state):
    var entry = "%s transitioned to %s" % [enemy.name, str(new_state)]
    log.append(entry)
    print(entry)
    # [AI_DECISION_LOGGING] 