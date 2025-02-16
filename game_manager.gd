extends Node

signal hunt_reset
signal stats_updated
signal fight_recorded

# Player stats
var player_gold: int = 0
var player_experience: int = 0
var player_power: int = 100
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
	var enemy_defeated = player_power > enemy_defense
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
