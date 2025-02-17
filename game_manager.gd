
extends Node

signal hunt_reset
signal stats_updated
signal fight_recorded
signal show_comparison(text)


# Player stats
var player_gold: int = 0
var player_experience: int = 0
var player_strength: int = 100
var player_defense: int = 100

var enemy_images = {
	"Goblin": preload("res://images/goblin.png"),
	"Orc": preload("res://images/orc.png"),
	"Bandit": preload("res://images/bandit.png"),
	"Wolf": preload("res://images/wolf.png"),
	"Dark Knight": preload("res://images/dark_knight.png")
}

func hunt() -> Dictionary:
	# Generate random enemy
	var enemy_name = get_random_enemy_name()
	var enemy_power = randi_range(50, 150)
	var enemy_defense = randi_range(50, 150)
	
	# Loot
	var gold_drop = randi_range(10, 50)
	var xp_drop = randi_range(5, 20)

	# Combat logic
	var enemy_defeated = player_strength > enemy_defense
	var player_defeated = enemy_power > player_defense

	var result = {
		"enemy_name": enemy_name,
		"enemy_power": enemy_power,
		"enemy_defense": enemy_defense,
		"enemy_defeated": enemy_defeated,
		"player_defeated": player_defeated,
		"gold_drop": gold_drop,
		"xp_drop": xp_drop
	}

	# If player wins, reward them
	if enemy_defeated and not player_defeated:
		player_gold += gold_drop
		player_experience += xp_drop
		
		emit_signal("stats_updated")
		
	if enemy_defeated or player_defeated:
		emit_signal("fight_recorded", result)
		print("Fight recorded signal emitted")
	
	return result

func get_random_enemy_name() -> String:
	var enemy_list = ["Goblin", "Orc", "Bandit", "Wolf", "Dark Knight"]
	return enemy_list[randi() % enemy_list.size()]

# Inventory system
var inventory = {
	"helmet": [
		{
			"name": "Iron Helmet",
			"icon_path": "res://assets/armor/ironhelmet.png"
		},
		
		{
			"name": "Bronze Helmet",
			"icon_path": "res://assets/armor/bronzehelmet.png"
		},
		
		{
			"name": "Water Helmet",
			"icon_path": "res://assets/armor/WaterHelmet.png"
		}
		
	],
	"breastplate": [
		{
			"name": "Dragon Breastplate",
			"icon_path": "res://assets/armor/DragonArmor.png",
			"stats": {
				"defense": 1000000,
				"strength": 1000000,
			}
			
			
			
		},
		
		{
			"name": "Water Breastplate",
			"icon_path": "res://assets/armor/Water Breastplate.png",
			"stats": {
				"defense": 0,
				"strength": 0,
			}
		}
		],
	"gloves": [],
	"greaves": [],
	"shoes": [
		
		{
			"name": "Water Boots",
			"icon_path": "res://assets/armor/WaterBoots.png"
		}
	],
	"weapons": []
}

# Currently equipped items
var equipped_items = {
	"helmet": null,
	"breastplate": null,
	"gloves": null,
	"greaves": null,
	"shoes": null,
	"weapon": null
}

# Function to equip an item
func equip_item(slot: String, item: Dictionary):
	if not item.has("stats"):
		print("ERROR: Item has no stats!", item)
		return

	# Unequip old item first (if any)
	if slot in equipped_items:
		var old_item = equipped_items[slot]
		
		if old_item != null and old_item.has("stats"):
			_update_player_stats(old_item["stats"], true)

	# Equip new item
	equipped_items[slot] = item
	_update_player_stats(item["stats"], false)

	# Emit signal to update UI
	emit_signal("stats_updated")
	print("Equipped", item["name"], "to", slot)

func _update_player_stats(stats: Dictionary, remove: bool = false):
	var multiplier = -1 if remove else 1

	if stats.has("defense"):
		player_defense += stats["defense"] * multiplier
	if stats.has("strength"):
		player_strength += stats["strength"] * multiplier
	

	print("Updated stats:", "Defense:", player_defense, "Power:",)
	
	
func add_item(slot: String, item_data: Dictionary):
	if slot in inventory:
		inventory[slot].append(item_data)
		print(item_data.name + " added to inventory!")

# Apply stat changes when equipping items
func apply_item_stats():
	# Reset stats to base values
	player_strength = 100
	player_defense = 100

	# Apply bonuses from equipped items
	for slot in equipped_items:
		var item = equipped_items[slot]
		if item:
			if "power" in item:
				player_strength += item.power
			if "defense" in item:
				player_defense += item.defense

	emit_signal("stats_updated")
