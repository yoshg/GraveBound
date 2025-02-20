extends Node

class_name LootTable

var drops: Dictionary  # Stores item names, drop rates, and rarity

func _init(_drops: Dictionary):
	drops = _drops  # Example: {"Snake Venom": {"chance": 0.4, "rarity": "Uncommon"}}
	
func roll_loot() -> Array:
	var loot_obtained = []
	for item in drops.keys():
		if randf() < drops[item]["chance"]:  # Roll based on drop rate
			loot_obtained.append({"name": item, "rarity": drops[item]["rarity"]})
	return loot_obtained
