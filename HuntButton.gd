extends Button

@onready var cooldown_timer = $HuntCooldownTimer
@onready var hud = get_node("/root/Main/HUD/MainHbox")
@onready var gold_label = hud.get_node("MainVbox/GoldLabel")
@onready var xp_label = hud.get_node("MainVbox/XPLabel")
@onready var result_display = get_node("/root/Main/HUD/HuntResultDisplay")

var countdown = 5
var is_on_cooldown = false

func _ready():
	connect("pressed", Callable(self, "_on_HuntButton_pressed"))
	cooldown_timer.timeout.connect(Callable(self, "_on_Cooldown_ended"))
	text = "Hunt"

func _on_HuntButton_pressed():
	if is_on_cooldown:
		print("Hunt is on cooldown! Please wait...")
		return

	text = "Hunting..."
	modulate = Color(0.7, 0.7, 0.7)

	var result = GameManager.hunt()
	if result_display:
		result_display.show_result(result)
		result_display.show()
	else:
		print("ERROR: HuntResultDisplay was freed!")

	# Start cooldown
	is_on_cooldown = true
	disabled = true
	countdown = int(cooldown_timer.wait_time)
	update_button_text()
	cooldown_timer.start()
	_start_countdown()

func _start_countdown():
	while countdown > 0:
		await get_tree().create_timer(1.0).timeout
		countdown -= 1
		update_button_text()

	_on_Cooldown_ended()

func _on_Cooldown_ended():
	is_on_cooldown = false
	disabled = false
	text = "Hunt"
	modulate = Color(1, 1, 1)
	print("Hunt is ready again!")
	GameManager.emit_signal("hunt_reset")

func update_button_text():
	text = "0:%02d" % countdown
