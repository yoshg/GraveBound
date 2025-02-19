extends Panel

@onready var helmet_button = $HelmetButton
@onready var breastplate_button = $BreastplateButton
@onready var gloves_button = $GlovesButton
@onready var greaves_button = $GreavesButton
@onready var shoes_button = $ShoesButton
@onready var weapon_button = $WeaponButton
@onready var defense_label = $StatsBox/DefenseLabel
@onready var strength_label = $StatsBox/StrengthLabel
@onready var equipment_menu = $EquipmentMenu
@onready var comparison_label = $ComparisonLabel

func _ready():
	if GameManager:
		GameManager.connect("stats_updated", Callable(self, "_update_avatar_stats"))
		GameManager.connect("show_comparison", Callable(self, "_update_comparison"))
	else:
		print("ERROR: GameManager not found!")
		
	_update_avatar_stats()  # Initialize
	
	# Connect buttons for left-click (equip) and right-click (unequip)
	helmet_button.connect("gui_input", Callable(self, "_on_slot_input").bind("helmet"))
	breastplate_button.connect("gui_input", Callable(self, "_on_slot_input").bind("breastplate"))
	gloves_button.connect("gui_input", Callable(self, "_on_slot_input").bind("gloves"))
	greaves_button.connect("gui_input", Callable(self, "_on_slot_input").bind("greaves"))
	shoes_button.connect("gui_input", Callable(self, "_on_slot_input").bind("shoes"))
	weapon_button.connect("gui_input", Callable(self, "_on_slot_input").bind("weapon"))

func _on_slot_input(event: InputEvent, slot: String):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			unequip_item(slot)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			equipment_menu.show_menu(slot)

func unequip_item(slot: String):
	if GameManager.equipped_items[slot] != null:
		GameManager.unequip_item(slot)

		# Reset the button icon
		var button = get_node(slot.capitalize() + "Button")
		button.icon = null  # Remove the equipped item icon
		print(slot.capitalize() + " unequipped.")

		# Update stats after unequipping
		_update_avatar_stats()

func _update_avatar_stats():
	defense_label.text = "Defense: " + str(GameManager.player_defense)
	strength_label.text = "Strength: " + str(GameManager.player_strength)

func _update_comparison(text):
	comparison_label.text = text
