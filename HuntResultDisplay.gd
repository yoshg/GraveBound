extends Panel

@onready var enemy_label = get_node("MainVbox/EnemyLabel")
@onready var stats_label = get_node("MainVbox/StatsLabel")
@onready var rewards_label = get_node("MainVbox/RewardsLabel")
@onready var enemy_graphic = get_node("MainVbox/EnemyGraphic")  # TextureRect for the enemy image
@onready var gold_label = get_node("MainVbox/GoldXPContainer/GoldLabel")
@onready var xp_label = get_node("MainVbox/GoldXPContainer/XPLabel")
@onready var close_button = get_node(".")

func _ready():
	hide()
	# Connect to the hunt_reset signal
	GameManager.connect("hunt_reset", Callable(self, "_on_hunt_reset"))
	close_button.connect("pressed", Callable(self, "_on_close_pressed"))
	# Set custom colors

func show_result(result: Dictionary) -> void:
	enemy_label.text = "Encountered: " + result.enemy_name
	stats_label.text = "%s Power: %d | Defense: %d" % [result.enemy_name, result.enemy_power, result.enemy_defense]

	if result.enemy_defeated and not result.player_defeated:
			rewards_label.text = "Victory! Gained %d Gold and %d XP" % [result.gold_drop, result.xp_drop]
	elif result.player_defeated and not result.enemy_defeated:
		rewards_label.text = "Defeat! You were overwhelmed."
	elif result.enemy_defeated and result.player_defeated:
			rewards_label.text = "Both perished in battle..."
	else:
		rewards_label.text = "The battle was inconclusive."

	show()  # Make sure the result panel is visible
	enemy_graphic.texture = null
	
	# Set the enemy graphic (assuming GameManager has the enemy_images dictionary)
	if result.enemy_name in GameManager.enemy_images:
		enemy_graphic.texture = GameManager.enemy_images[result.enemy_name]
		enemy_graphic.show()
	else:
		enemy_graphic.texture = null

func _on_hunt_reset() -> void:
	hide()  # Hides the panel instead of deleting it
	
func _on_close_pressed() -> void:
	hide()  # Allows the player to close it manually


func _on_close_button_pressed() -> void:
	hide()
