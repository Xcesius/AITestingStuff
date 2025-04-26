# LootSimulator.gd
tool
extends Node

func simulate_loot(loot_table, trials=1000):
    var results = {}
    for i in range(trials):
        var loot = loot_table.get_random_loot()
        if loot:
            var name = loot.name if loot.has_method("name") else str(loot)
            results[name] = results.get(name, 0) + 1
    for k in results:
        print("%s: %d" % [k, results[k]])
    # [LOOT_SIMULATION_LOGIC] 