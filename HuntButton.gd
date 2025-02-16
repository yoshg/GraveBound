extends Button  # Make sure the script extends Button

@onready var cooldown_timer = $HuntCooldownTimer
@onready var hud = get_node("/root/Main/HUD/MainHbox")  # Reference HUD
@onready var gold_label = hud.get_node("MainVbox/GoldLabel")
@onready var xp_label = hud.get_node("MainVbox/XPLabel")
@onready var result_display = get_node("/root/Main/HUD/HuntResultDisplay")

var is_on_cooldown = false

func _ready():
	connect("pressed", Callable(self, "_on_HuntButton_pressed"))
	cooldown_timer.timeout.connect(_on_Cooldown_ended)
	update_ui()
	# Set the initial appearance
	text = "Hunt"
	modulate = Color(1, 1, 1)  # Normal white (or default)

func _on_HuntButton_pressed():
	if is_on_cooldown:
		print("Hunt is on cooldown! Please wait...")
		return

	text = "Hunting..."
	modulate = Color(0.7,0.7,0.7)
	
	# Call the GameManager's hunt function
	var result = GameManager.hunt()
	
	if result_display:
		result_display.show_result(result)
		result_display.show()  # Make sure it is visible
	else:
		print("ERROR: HuntResultDisplay was freed!")
		
	

	# Start cooldown
	is_on_cooldown = true
	disabled = true
	cooldown_timer.start()

func _on_Cooldown_ended():
	is_on_cooldown = false
	disabled = false
	text = "Hunt"
	modulate = Color(1, 1, 1)
	print("Hunt is ready again!")
	GameManager.emit_signal("hunt_reset")

func update_ui():
	gold_label.text = "Gold: " + str(GameManager.player_gold)
	xp_label.text = "XP: " + str(GameManager.player_experience)
