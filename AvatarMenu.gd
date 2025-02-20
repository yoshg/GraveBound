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
			print_debug("Opening Equipment Menu for:", slot)  # ✅ Debugging
			equipment_menu.show_menu(slot)

func unequip_item(slot: String):
	if GameManager.equipped_items.has(slot) and GameManager.equipped_items[slot] != null:
		var unequipped_item = GameManager.equipped_items[slot]
		print_debug("Unequipping:", unequipped_item["name"], "from slot:", slot)

		# Remove item from equipped_items
		GameManager.equipped_items.erase(slot)

		# Remove its stats from player stats
		GameManager.player_defense -= unequipped_item.get("flat_defense", 0)
		
		# Remove resistances
		if unequipped_item.has("resistances"):
			for attack_type in unequipped_item["resistances"]:
				GameManager.player_resistances[attack_type] -= unequipped_item["resistances"][attack_type]

		# Reset the button icon
		var button = get_node(slot.capitalize() + "Button")
		button.icon = null

		# Emit signal to update stats
		GameManager.emit_signal("stats_updated")

		print_debug(slot.capitalize() + " unequipped.")


func _update_avatar_stats():
	# ✅ Get new combat values
	var attack_power = int(GameManager.calculate_base_attack())  # Ensure integer
	var flat_defense = int(GameManager.calculate_total_flat_defense())  # Ensure integer

	# ✅ Update labels with new stats
	defense_label.text = "Defense: " + str(flat_defense)
	strength_label.text = "Power: " + str(attack_power)

	# ✅ Debugging: Ensure values are correctly fetched
	print_debug("Updated Avatar Stats - Attack Power:", attack_power, "Flat Defense:", flat_defense)

func _update_comparison(text):
	comparison_label.text = text
