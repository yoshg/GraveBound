
extends Node

signal hunt_reset
signal stats_updated
signal fight_recorded
signal show_comparison(text, position)
signal location_changed  # Added new signal

const LootTable = preload("res://LootTable.gd")  # Update with the correct path

# Player stats
var player_gold: int = 10000000
var player_experience: int = 0
var player_strength: int = 100
var player_defense: int = 100
var current_location = "Mayflower"
var current_enemy = null
var player_attack: Dictionary = {}  # ✅ Declare attack variable properly
var player_weapon: Dictionary = {}  # ✅ Properly declared variable for equipped weapon
var player_armor_pierce: Dictionary = {}  # ✅ Tracks armor piercing stats
var player_flat_defense: int = 0  # ✅ Stores total flat defense
var player_resistances: Dictionary = {}  # ✅ Stores resistance values for attack types

var enemy_images = {
	"Goblin": preload("res://images/goblin.png"),
	"Orc": preload("res://images/orc.png"),
	"Bandit": preload("res://images/bandit.png"),
	"Wolf": preload("res://images/wolf.png"),
	"Dark Knight": preload("res://images/dark_knight.png"),
	"Ruffian": preload("res://images/ruffian.png"),
	"Thief": preload("res://images/thief.png")
}

func hunt() -> Dictionary:
	# Generate a random enemy
	var enemy_data = get_random_enemy()
	print("Selected enemy:", enemy_data)  # Debug output

	if enemy_data.is_empty() or not enemy_data.has("name"):
		print_debug("Error: No valid enemy found!")
		return {
			"enemy_name": "Unknown Enemy",
			"enemy_power": 0,
			"enemy_defense": 0,
			"enemy_defeated": false,
			"player_defeated": false,
			"gold_drop": 0,
			"xp_drop": 0,
			"loot": []
		}
	current_enemy = enemy_data  # Store the enemy for combat calculations
	
	# Ensure `current_enemy` has a `name`
	if not current_enemy.has("name"):
		print_debug("Error: Current enemy is missing 'name':", current_enemy)
		return {}

	# ✅ Use fixed enemy power **with defense reduction**
	var attack_power = calculate_effective_attack()
	var effective_enemy_power = calculate_effective_enemy_power(current_enemy.base_power, "Slash")  # ✅ Pass base power and attack type

	# ✅ Calculate win probability
	var alpha = 0.5
	var win_probability = pow(attack_power, alpha) / (pow(attack_power, alpha) + pow(effective_enemy_power, alpha))
	win_probability = clamp(win_probability, 0.0, 1.0)  # Ensure valid range

	# ✅ Single roll for outcome (no ties)
	var roll = randf()
	var enemy_defeated = roll < win_probability
	var player_defeated = not enemy_defeated

	# ✅ Debugging battle results
	print_debug("Effective Attack Power:", attack_power)
	print_debug("Effective Enemy Power (After Defense Reduction):", effective_enemy_power)  # ✅ Now properly reduced
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
		"enemy_power": effective_enemy_power,  # ✅ Now reflects defense reduction
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
	print_debug("Current location in get_random_enemy():", current_location)
	
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
	if not enemies.has(current_location):
		print_debug("Error: Location not found in enemy list:", current_location)
		return {}

	var enemy_list = enemies[current_location]
	if enemy_list.is_empty():
		print_debug("Error: No enemies found for location:", current_location)
		return {}

	# Pick a random enemy from the list and ensure it's valid
	var selected_enemy = enemy_list[randi() % enemy_list.size()]
	if not "name" in selected_enemy:
		print_debug("Error: Enemy data missing 'name':", selected_enemy)
		return {}
	
	print_debug("Fetching enemy list for:", current_location)
	print_debug("Enemy list contains:", enemy_list)

	return selected_enemy

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

	"charms": [],

	"greases": [],

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
	# Get the currently equipped item in the slot
	var old_item = equipped_items.get(slot, null)

	# ✅ If an item was previously equipped, subtract its stats first
	if old_item and "stats" in old_item:
		player_flat_defense -= old_item.stats.get("flat_defense", 0)
		for attack_type in old_item.stats.get("resistances", {}).keys():
			player_resistances[attack_type] -= old_item.stats["resistances"].get(attack_type, 0)

	# ✅ Now equip the new item
	equipped_items[slot] = item.duplicate(true)

	# ✅ Add new item's stats
	if "stats" in item:
		player_flat_defense += item.stats.get("flat_defense", 0)
		for attack_type in item.stats.get("resistances", {}).keys():
			player_resistances[attack_type] = player_resistances.get(attack_type, 0) + item.stats["resistances"].get(attack_type, 0)

	# Debugging
	print_debug("Equipped", item.get("name", "Unknown Item"), "Flat Defense:", player_flat_defense, "Resistances:", player_resistances)
	emit_signal("stats_updated")  # ✅ Ensures UI updates




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
	if new_location in ["Mayflower", "Cave"]:  # Ensure location is valid
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
	# Get the equipped weapon
	var weapon = GameManager.equipped_items.get("weapon", null)  # ✅ Ensure correct slot
	if not weapon:
		print_debug("No weapon equipped! Returning 0 attack.")
		return 0

	var attack_stats = weapon.get("attack", {})  # ✅ Prevents crash if attack is missing
	if attack_stats.is_empty():
		print_debug("Equipped weapon has no attack stats! Returning 0 attack.")
		return 0

	var total_attack = 0.0

	for attack_type in attack_stats.keys():
		var weapon_power = attack_stats.get(attack_type, 0)  # ✅ Prevents crash if attack type is missing
		var enemy_resistance = current_enemy.resistances.get(attack_type, 0)  # ✅ Fetch enemy resistance

		# Apply armor-piercing effects if they exist
		var armor_pierce = GameManager.player_armor_pierce.get(attack_type, 0)  # ✅ Get armor pierce for the attack type
		var effective_resistance = max(0, enemy_resistance - armor_pierce)  # ✅ Subtract armor pierce, but keep resistance non-negative

		# Calculate effective attack power
		var attack_value = weapon_power * (1.0 - effective_resistance)  # ✅ Subtract adjusted resistance correctly
		if attack_value < 0:
			attack_value = 0  # ✅ Ensure attack doesn't go negative

		total_attack += attack_value

		# Debugging output
		print_debug("Attack Type:", attack_type, "Power:", weapon_power, "Enemy Resistance:", enemy_resistance, 
			"Armor Pierce:", armor_pierce, "Effective Resistance:", effective_resistance, "Effective:", attack_value)

	print_debug("Total Attack Power:", total_attack)
	return total_attack


func calculate_effective_enemy_power(base_enemy_power: float, attack_type: String) -> float:
	# Get player's resistance to this attack type
	var resistance = player_resistances.get(attack_type, 0)  # ✅ Fetch resistance from player stats

	# Apply resistance correctly
	var reduced_power = base_enemy_power * (1.0 - resistance) - player_flat_defense  # ✅ Flat defense and resistances reduce damage
	
	if reduced_power < 0:
		reduced_power = 0  # ✅ Ensure enemy power doesn't go negative

	# Debugging
	print_debug("Final Enemy Power:", reduced_power, "Defense Applied:", player_flat_defense, "Resistance Applied:", resistance)
	return reduced_power

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

# Function to add an item to inventory
func add_item(slot: String, item_data: Dictionary):
	if slot in inventory:
		# Prevent duplicate purchases for non-stackable items
		for existing_item in inventory[slot]:
			if existing_item.name == item_data.name:
				print("Already own:", item_data.name)
				return  # Stop duplicate purchases

		# Add item to inventory dynamically
		inventory[slot].append(item_data)
		print(item_data.name + " added to inventory!")

		emit_signal("stats_updated")  # Update inventory UI


# Function to remove an item from inventory
func remove_item(slot: String, item_name: String):
	if slot in inventory:
		for i in range(inventory[slot].size()):
			var item = inventory[slot][i]
			if item.name == item_name:
				if "quantity" in item and item.quantity > 1:
					item.quantity -= 1  # Reduce stack size
					print(item_name + " quantity decreased!")
				else:
					inventory[slot].remove_at(i)  # Remove item completely
					print(item_name + " removed from inventory!")
				return
	print("Item not found:", item_name)
