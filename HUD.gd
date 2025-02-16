extends Control  # Renamed to HUD

@onready var gold_label = find_child("GoldLabel", true, false)
@onready var xp_label = find_child("XPLabel", true, false)
@onready var hunt_button = find_child("MainHbox/HuntButton")

func _ready():
	
	GameManager.connect("stats_updated", Callable(self, "_update_ui"))
	_update_ui()  # Initialize UI
	# Verify that the nodes exist before using them
	if not gold_label or not xp_label or not hunt_button:
		print("ERROR: UI elements missing from HUD! Check scene tree.")
		return
	
	# Connect to GameManager signals for updating UI
	GameManager.connect("hunt_reset", Callable(self, "_update_ui"))
	_update_ui()  # Initialize UI with current stats

func _update_ui():
	gold_label.text = "Gold: " + str(GameManager.player_gold)
	xp_label.text = "XP: " + str(GameManager.player_experience)
