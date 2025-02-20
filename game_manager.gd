
extends Node

signal hunt_reset
signal stats_updated
signal fight_recorded
signal show_comparison(text)
signal location_changed  # Added new signal

const LootTable = preload("res://LootTable.gd")  # Update with the correct path


# Player stats
var player_gold: int = 0
var player_experience: int = 0
var player_strength: int = 100
var player_defense: int = 100
var current_location = "Mayflower"
var current_enemy = null

var enemy_images = {
	"Goblin": preload("res://images/goblin.png"),
	"Orc": preload("res://images/orc.png"),
	"Bandit": preload("res://images/bandit.png"),
	"Wolf": preload("res://images/wolf.png"),
	"Dark Knight": preload("res://images/dark_knight.png")
}

func hunt() -> Dictionary:
	# Generate a random enemy
	var enemy_data = get_random_enemy()
	if enemy_data.is_empty():
		print_debug("Error: No enemy found!")
		return {}

	current_enemy = enemy_data  # Store the enemy for combat calculations

	# ✅ Use fixed enemy power
	var attack_power = calculate_effective_attack()
	var enemy_power = max(0, current_enemy.base_power)  # Use predefined power

	# ✅ Calculate win probability
	var alpha = 0.5
	var win_probability = pow(attack_power, alpha) / (pow(attack_power, alpha) + pow(enemy_power, alpha))
	win_probability = clamp(win_probability, 0.0, 1.0)  # Ensure valid range

	# ✅ Single roll for outcome (no ties)
	var roll = randf()
	var enemy_defeated = roll < win_probability
	var player_defeated = not enemy_defeated

	# ✅ Debugging battle results
	print_debug("Effective Attack Power:", attack_power)
	print_debug("Effective Enemy Power:", enemy_power)
	print_debug("Win Probability: %.2f%%" % (win_probability * 100))  # Show as percentage
	print_debug("Rolled Value:", roll)
	print_debug("Enemy Defeated:", enemy_defeated)
	print_debug("Player Defeated:", player_defeated)

	# Loot
	var gold_drop = randi_range(10, 50)
	var xp_drop = randi_range(5, 20)
	var loot_drops = []
	if enemy_defeated and current_enemy.has("loot_table"):
		loot_drops = current_enemy.loot_table.roll_loot()

	# Apply rewards if player wins
	if enemy_defeated:
		player_gold += gold_drop
		player_experience += xp_drop
		emit_signal("stats_updated")

	# Store fight results
	var result = {
		"enemy_name": current_enemy.name,
		"enemy_power": enemy_power,
		"enemy_defense": current_enemy.base_power,
		"enemy_defeated": enemy_defeated,
		"player_defeated": player_defeated,
		"gold_drop": gold_drop,
		"xp_drop": xp_drop,
		"loot": loot_drops
	}

	# Emit fight result signal
	emit_signal("fight_recorded", result)
	print("Fight recorded signal emitted")

	return result



func get_random_enemy() -> Dictionary:
	var enemies = {
		"Mayflower": [
			{"name": "Thief", "base_power": 50, "resistances": {"Slash": 1.0, "Blunt": 1.2}, "loot_table": LootTable.new({"Gold Pouch": {"chance": 0.5, "rarity": "Common"}})},
			{"name": "Ruffian", "base_power": 75, "resistances": {"Slash": 0.8, "Blunt": 1.0}, "loot_table": LootTable.new({"Leather Scrap": {"chance": 0.4, "rarity": "Uncommon"}})}
		],
		"Cave": [
			{"name": "Snake", "base_power": 60, "resistances": {"Slash": 0.9, "Blunt": 1.1}, "loot_table": LootTable.new({"Snake Venom": {"chance": 0.4, "rarity": "Uncommon"}})},
			{"name": "Bat", "base_power": 40, "resistances": {"Slash": 1.1, "Blunt": 0.9}, "loot_table": LootTable.new({"Bat Wing": {"chance": 0.3, "rarity": "Common"}})}
		]
	}

	# Get enemies based on current location
	var enemy_list = enemies.get(current_location, [])
	if enemy_list.size() == 0:
		print_debug("No enemies found for location: ", current_location)
		return {}

	# Pick a random enemy from the list
	return enemy_list[randi() % enemy_list.size()]


func get_random_enemy_name() -> String:
	var enemy_list = ["Goblin", "Orc", "Bandit", "Wolf", "Dark Knight"]
	return enemy_list[randi() % enemy_list.size()]


# Inventory system
var inventory = {
	
	"helmet": [
		{
			"name": "Iron Helmet",
			"icon_path": "res://assets/armor/ironhelmet.png",
			"stats": {
				"flat_defense": 5,  # Small flat defense
				"resistances": { "Blunt": 0.1, "Slash": 0.05 }  # Small resistances
			}
			
		},
		
		{
			"name": "Bronze Helmet",
			"icon_path": "res://assets/armor/bronzehelmet.png",
			"stats": {
				"resistances": { "Blunt": 0.15, "Pierce": 0.05 }
			}
		},
		{
			"name": "Water Helmet",
			"icon_path": "res://assets/armor/WaterHelmet.png",
			"stats": {
				"flat_defense": 8,
				"resistances": { "Magic": 0.2 }
			}
		}
	],

	"breastplate": [
		{
			"name": "Dragon Breastplate",
			"icon_path": "res://assets/armor/DragonArmor.png",
			"stats": {
				"flat_defense": 1000000,  # Should be a cheat item
				"resistances": {
					"Slash": 1.0, "Blunt": 1.0, "Pierce": 1.0, "Magic": 1.0, "Holy": 1.0
				}
			}
		},
		{
			"name": "Water Breastplate",
			"icon_path": "res://assets/armor/Water Breastplate.png",
			"stats": {
				"flat_defense": 12,
				"resistances": { "Magic": 0.3, "Blunt": 0.1 }
			}
		}
	],

	"gloves": [],

	"greaves": [],

	"shoes": [
		{
			"name": "Water Boots",
			"icon_path": "res://assets/armor/WaterBoots.png",
			"stats": {
				"flat_defense": 6,
				"resistances": { "Magic": 0.2, "Pierce": 0.05 }
			}
		}
	],

	"weapon": [
		{
			"name": "God Sword",
			"icon_path": "res://assets/weapons/godsword.png",
			"attack": {  # ✅ INSANE ATTACK POWER
				"Slash": 1000000,
				"Pierce": 500000,
				"Blunt": 2050000
		},
			"armor_pierce": {  # ✅ DESTROYS ENEMY RESISTANCES
				"Slash": 1.0,
				"Pierce": 1.0,
				"Blunt": 1.0
			}
		},
		
		{
			"name": "Iron Sword",
			"icon_path": "res://assets/weapons/ironsword.png",
			"attack": {  
				"Slash": 10,
				"Pierce": 5,
				"Blunt": 2
		},
			"armor_pierce": {  
				"Slash": .3,
				"Pierce": .1,
				"Blunt": .0
			}
		}
	]
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
	# Unequip old item first (if any)
	if slot in equipped_items:
		var old_item = equipped_items[slot]
		if old_item != null and old_item.has("stats"):
			_update_player_stats(old_item["stats"], true)

	# Equip new item
	equipped_items[slot] = item
	
	# If equipping a weapon, update GameManager
	if slot == "weapon":
		GameManager.equipped_items["weapon"] = item

	# Apply stats
	if item.has("stats"):
		_update_player_stats(item["stats"], false)

	# Emit signal to update UI
	emit_signal("stats_updated")



func unequip_item(slot: String):
	if slot in equipped_items and equipped_items[slot] != null:
		var item = equipped_items[slot]

		# Reverse stat changes if the item has stats
		if item.has("stats"):
			_update_player_stats(item["stats"], true)

		# Remove item from equipped items
		equipped_items[slot] = null

		emit_signal("stats_updated")
		print("Unequipped", item.get("name", "Unknown Item"), "from", slot)


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

func change_location(new_location: String):
	if new_location in ["Mayflower", "Cave Entrance"]:  # Ensure location is valid
		current_location = new_location
		print("Traveled to:", current_location)
		emit_signal("location_changed", current_location)  # Notify HUD
	else:
		print("Invalid location:", new_location)

func calculate_base_attack() -> float:
	# Get the equipped weapon
	var weapon = equipped_items.get("weapon", null)

	if weapon == null:
		print_debug("No weapon equipped! Returning 0 attack.")
		return 0  # No weapon equipped

	# ✅ Collect attack values
	var attack_values = []
	for attack_type in weapon.attack.keys():
		attack_values.append(weapon.attack[attack_type])

	# ✅ Calculate average
	if attack_values.size() == 0:
		print_debug("Weapon has no valid attack types! Returning 0 attack.")
		return 0

	var avg_attack = float(attack_values.reduce(func(a, b): return a + b, 0)) / attack_values.size()

	# ✅ Debugging logs
	print_debug("Base Attack Power (Average):", avg_attack)

	return avg_attack


func calculate_effective_attack() -> float:
	# Get the equipped weapon from equipped_items dictionary
	var weapon = equipped_items.get("weapon", null)
	
	if weapon == null:
		print_debug("No weapon equipped!")  # ✅ Debugging
		return 0  # No weapon equipped

	print_debug("Equipped Weapon:", weapon["name"])
	
	var total_attack = 0.0
	for attack_type in weapon.attack.keys():
		var weapon_power = weapon.attack[attack_type]
		var resistance = current_enemy.resistances.get(attack_type, 1.0)
		var armor_pierce = weapon.armor_pierce.get(attack_type, 0.0)

		# Apply armor piercing
		resistance = max(0, resistance - armor_pierce)

		# Calculate effective attack power
		var attack_value = weapon_power * (1.0 - resistance)
		total_attack += attack_value
		
	# ✅ Debugging logs
		print_debug("Attack Type:", attack_type, "Power:", weapon_power, "Effective:", attack_value)

	# ✅ Debug final attack power
	print_debug("Total Attack Power:", total_attack)

	return total_attack


func calculate_effective_enemy_power() -> float:
	if current_enemy == null:
		return 0  # No enemy set

	# Get equipped armor pieces
	var armor_pieces = ["helmet", "breastplate", "gloves", "greaves", "shoes"]
	var flat_defense = 0
	var resistances = {}

	# Debugging: Check if armor exists in `equipped_items`
	print_debug("Equipped Armor Items:", equipped_items)

	# Loop through equipped armor
	for slot in armor_pieces:
		var armor = equipped_items.get(slot, null)
		if armor != null and armor.has("stats"):  # ✅ Fix: Ensure we're accessing stats
			print_debug("Processing Armor:", armor["name"], "Slot:", slot)

			# ✅ Fix: Extract `flat_defense` from the `stats` dictionary
			flat_defense += armor["stats"].get("flat_defense", 0)

			# ✅ Fix: Extract `resistances` from the `stats` dictionary
			var armor_resistances = armor["stats"].get("resistances", {})
			for attack_type in armor_resistances.keys():
				resistances[attack_type] = resistances.get(attack_type, 0) + armor_resistances[attack_type]

	# Debugging armor values
	print_debug("Final Flat Defense:", flat_defense)
	print_debug("Final Resistances:", resistances)

	# Apply flat defense reduction
	var enemy_power = max(0, current_enemy.base_power - flat_defense)

	# Apply resistances
	for attack_type in resistances.keys():
		enemy_power *= (1 - resistances[attack_type])

	# Debug final enemy power
	print_debug("Final Enemy Power:", enemy_power)

	return max(0, enemy_power)

func calculate_total_flat_defense() -> int:
	var total_flat_defense = 0

	# ✅ Loop through equipped armor and sum flat defense
	for slot in ["helmet", "breastplate", "gloves", "greaves", "shoes"]:
		var item = equipped_items.get(slot, null)
		if item and item.has("stats") and item["stats"].has("flat_defense"):
			total_flat_defense += item["stats"]["flat_defense"]

	# ✅ Debugging: Ensure correct calculations
	print_debug("Total Flat Defense:", total_flat_defense)

	return total_flat_defense
