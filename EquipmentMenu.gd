extends Panel

@onready var grid_container = $GridContainer
@onready var avatar_menu = get_node("/root/Main/AvatarMenu")
var slot_buttons = {}  # Store slot buttons dynamically
var current_slot = ""

func _ready():
	hide()  # Ensure the menu is hidden on game start
	
	# Locate AvatarMenu and fetch slot buttons
	var main = get_tree().get_root().get_node("Main")
	if main and main.has_node("AvatarMenu"):
		var avatar_menu = main.get_node("AvatarMenu")
		print("Avatar Menu Found:", avatar_menu)

		# Dynamically get buttons from AvatarMenu
		var slot_names = ["helmet", "breastplate", "gloves", "greaves", "shoes", "weapon"]
		for slot in slot_names:
			var button_path = slot.capitalize() + "Button"  # Example: "BreastplateButton"
			if avatar_menu.has_node(button_path):
				slot_buttons[slot] = avatar_menu.get_node(button_path)
				print("Found button for slot:", slot, "->", slot_buttons[slot])
			else:
				print("WARNING: Button not found for slot:", slot)

func show_menu(slot: String):
	print("Equipment menu opened for:", slot)
	current_slot = slot
	print("Current slot set to:", current_slot)
	
	update_items()
	show() 

func update_items():
	# Clear previous items
	for child in grid_container.get_children():
		grid_container.remove_child(child)
		child.queue_free()
		
		
		# ✅ Debugging: Print the full inventory structure
	print_debug("Full Inventory Data:", GameManager.inventory)

	# Get items from inventory
	var items = GameManager.inventory.get(current_slot, [])
	print_debug("Updating items for slot:", current_slot)
	

	# If no items found, print a warning
	if items.size() == 0:
		print_debug("WARNING: No items found for slot:", current_slot)

	for item in items:
		print_debug("Processing Item:", item["name"])  # ✅ Debugging

		var item_container = HBoxContainer.new()  # Holds both sprite & button
		item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Create a Control node to constrain the icon size
		var icon_container = Control.new()
		icon_container.custom_minimum_size = Vector2(32, 32)  # Strict size limit

		# Create Sprite (TextureRect)
		var texture_rect = TextureRect.new()
		texture_rect.custom_minimum_size = Vector2(32, 32)  # Force strict size
		texture_rect.expand = true 

		# Load texture correctly
		if item.has("icon_path"):
			texture_rect.texture = load(item["icon_path"])
			print_debug("Setting icon for item:", item["name"], "in slot:", current_slot)
		else:
			print_debug("WARNING: Item", item["name"], "has no 'icon_path'!")

		icon_container.add_child(texture_rect)
		item_container.add_child(icon_container)

		# **Make the item selectable**
		var select_button = Button.new()
		select_button.text = "Equip " + item["name"]
		select_button.connect("pressed", Callable(self, "_on_item_selected").bind(item))
		item_container.add_child(select_button)
		
		# **New: Add mouse hover signal to compare stats**
		select_button.connect("mouse_entered", Callable(self, "_compare_stats").bind(item))
		select_button.connect("mouse_exited", Callable(self, "_clear_comparison"))

		grid_container.add_child(item_container)

func _compare_stats(new_item):
	if not current_slot in GameManager.equipped_items:
		return

	var old_item = GameManager.equipped_items[current_slot]
	# Ensure old_item and new_item have stats, defaulting to {"defense": 0, "strength": 0}
	var old_stats = old_item.get("stats", {}) if old_item != null else {}
	var new_stats = new_item.get("stats", {})

	# Ensure each stat exists, defaulting to 0
	var old_defense = old_stats.get("defense", 0)
	var new_defense = new_stats.get("defense", 0)

	var old_strength = old_stats.get("strength", 0)
	var new_strength = new_stats.get("strength", 0)

	var comparison_text = "Comparing:\n"
	comparison_text += "Defense: " + str(old_defense) + " → " + str(new_defense) + "\n"
	comparison_text += "Strength: " + str(old_strength) + " → " + str(new_strength)
	
	GameManager.emit_signal("show_comparison", comparison_text)

func _clear_comparison():
	GameManager.emit_signal("show_comparison", "")

func equip_item(item):
	print_debug("Equipping:", item["name"], "to slot:", current_slot)

	# Store in GameManager
	GameManager.equipped_items[current_slot] = {
		"name": item.get("name", ""),
		"icon_path": item.get("icon_path", ""),
		"flat_defense": item.get("stats", {}).get("flat_defense", 0),
		"resistances": item.get("stats", {}).get("resistances", {})
	}

	# Apply the item's defense and resistances
	GameManager.player_defense += GameManager.equipped_items[current_slot]["flat_defense"]

	# Debugging: Check if defense is applied correctly
	print_debug("Updated Defense:", GameManager.player_defense)

	if GameManager.equipped_items[current_slot].has("resistances"):
		for attack_type in GameManager.equipped_items[current_slot]["resistances"]:
			GameManager.player_resistances[attack_type] += GameManager.equipped_items[current_slot]["resistances"][attack_type]

	# Update Avatar UI
	avatar_menu._update_avatar_stats()

	# Close EquipmentMenu after equipping
	avatar_menu.close_menu()


func _on_item_selected(item: Dictionary):
	GameManager.equip_item(current_slot, item)  # Equip the item

	# Get the Main node first
	var main = get_tree().get_root().get_node("Main")
	if main and main.has_node("AvatarMenu"):
		var avatar_menu = main.get_node("AvatarMenu")  # Get AvatarMenu correctly
		print("Avatar Menu Found:", avatar_menu)

		# Find the correct button based on the slot selected
		var button_path = current_slot.capitalize() + "Button"  # Example: "breastplate" → "BreastplateButton"
		if avatar_menu.has_node(button_path):
			var button = avatar_menu.get_node(button_path)
			print("Button Found:", button, "for slot:", current_slot)

			if button and item.has("icon_path"):
				var texture = load(item.icon_path)
				if texture:
					if button is TextureButton:
						button.texture_normal = texture  # Assign the icon properly
					else:
						button.icon = texture  # Fallback for regular Button

					print("Equipped", item.name, "to", current_slot)
				else:
					print("Failed to load equipped item icon:", item.icon_path)
			else:
				print("No valid icon path in item:", item)
		else:
			print("Button for slot", current_slot, "not found inside AvatarMenu!")
	else:
		print("Main Scene or AvatarMenu Not Found!")
	
	GameManager.emit_signal("show_comparison", "")
	hide()  # Close menu


	
	# Close the menu if clicking outside of it

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var rect = get_global_rect()
		if not rect.has_point(get_global_mouse_position()):
			hide()
