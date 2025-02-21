extends Panel

@onready var enemy_label = get_node("MainVbox/EnemyLabel")
@onready var stats_label = get_node("MainVbox/StatsLabel")
@onready var rewards_label = get_node("MainVbox/RewardsLabel")
@onready var enemy_graphic = get_node("MainVbox/EnemyGraphic")  # TextureRect for the enemy image
@onready var gold_label = get_node("MainVbox/GoldXPContainer/GoldLabel")
@onready var xp_label = get_node("MainVbox/GoldXPContainer/XPLabel")
@onready var close_button = get_node("CloseButton")

func _ready():
	hide()
	GameManager.connect("hunt_reset", Callable(self, "_on_hunt_reset"))
	close_button.connect("pressed", Callable(self, "_on_close_pressed"))

func show_result(result: Dictionary) -> void:
	if result.is_empty() or not result.has("enemy_name"):
		print_debug("Error: Invalid result received in HuntResultDisplay:", result)
		enemy_label.text = "Error: No enemy data."
		stats_label.text = "Could not fetch enemy stats."
		rewards_label.text = "Something went wrong with the battle."
		enemy_graphic.texture = null
		show()
		return

	# Set basic text values
	enemy_label.text = result.enemy_name
	stats_label.text = "%s Power: %d | Defense: %d" % [result.enemy_name, result.enemy_power, result.enemy_defense]

	# Set battle result message
	if result.enemy_defeated and not result.player_defeated:
		rewards_label.text = "Victory! Gained %d Gold and %d XP" % [result.gold_drop, result.xp_drop]
	elif result.player_defeated and not result.enemy_defeated:
		rewards_label.text = "Defeat! You were overwhelmed."
	elif result.enemy_defeated and result.player_defeated:
		rewards_label.text = "Both perished in battle..."
	else:
		rewards_label.text = "The battle was inconclusive."

	# Display gold and XP rewards
	gold_label.text = "%d Gold" % result.gold_drop
	xp_label.text = "%d XP" % result.xp_drop

	# Display the enemy image
	if result.enemy_name in GameManager.enemy_images:
		enemy_graphic.texture = GameManager.enemy_images[result.enemy_name]
		enemy_graphic.show()
	else:
		enemy_graphic.texture = null

	show()  # Show the panel

func _on_hunt_reset() -> void:
	hide()  # Hides the panel instead of deleting it

func _on_close_pressed() -> void:
	hide()  # Allows the player to close it manually
