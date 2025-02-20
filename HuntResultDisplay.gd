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
	if GameManager.current_enemy == null:
		print_debug("Error: No current_enemy set in GameManager!")
		return
	
	# Update labels using current_enemy
	enemy_label.text = "Encountered: " + GameManager.current_enemy.name
	stats_label.text = "%s Power: %d | Defense: %d" % [
		GameManager.current_enemy.name,
		GameManager.current_enemy.base_power,
		GameManager.current_enemy.base_power
	]

	# Determine battle outcome text
	var outcome_text = "The battle was inconclusive."
	if result.enemy_power == 0 or (result.enemy_defeated and not result.player_defeated):
		outcome_text = "Victory! Gained %d Gold and %d XP" % [result.gold_drop, result.xp_drop]
	elif result.player_defeated and not result.enemy_defeated:
		outcome_text = "Defeat! You were overwhelmed."
	elif result.enemy_defeated and result.player_defeated:
		outcome_text = "Both perished in battle..."

	# Update rewards
	rewards_label.text = outcome_text

	# Set the enemy graphic
	enemy_graphic.texture = GameManager.enemy_images.get(GameManager.current_enemy.name, null)
	enemy_graphic.visible = enemy_graphic.texture != null
	
	show()


func _on_hunt_reset() -> void:
	hide()  # Hides the panel instead of deleting it
	
func _on_close_button_pressed() -> void:
	hide()
