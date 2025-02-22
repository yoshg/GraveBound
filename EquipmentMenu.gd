extends Panel

signal show_comparison(text, position)

@onready var grid_container = $GridContainer
@onready var avatar_menu = get_node("/root/Main/AvatarMenu")
var slot_buttons = {}  # Store slot buttons dynamically
var current_slot = ""
var comparison_panel = null  # Store the reference to prevent null errors

func _ready():
	# Delay execution until the next frame to ensure all nodes exist
	await get_tree().process_frame  

	# Now safely get the AvatarMenu
	var avatar_menu = get_node_or_null("/root/Main/AvatarMenu")
	
	# Check if AvatarMenu exists
	if not avatar_menu:
		print_debug("Error: AvatarMenu not found!")
		return
	
	# Now safely get the ComparisonPanel inside AvatarMenu
	var comparison_panel = avatar_menu.get_node_or_null("ComparisonPanel")
	var comparison_label = avatar_menu.get_node_or_null("ComparisonPanel/ComparisonLabel")

	# Validate nodes
	if not comparison_panel or not comparison_label:
		print_debug("Error: ComparisonPanel or ComparisonLabel not found in AvatarMenu!")
		return

	print_debug("ComparisonPanel and ComparisonLabel found successfully in EquipmentMenu!")

	# Now continue with the rest of your setup...
	hide()  # Ensure the menu is hidden on game start
	
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
		select_button.text = item["name"]
		select_button.connect("pressed", Callable(self, "_on_item_selected").bind(item))
		item_container.add_child(select_button)
		
		# **New: Add mouse hover signal to compare stats**
		select_button.connect("mouse_entered", Callable(self, "_compare_stats").bind(item))
		select_button.connect("mouse_exited", Callable(self, "_clear_comparison"))

		grid_container.add_child(item_container)

func _compare_stats(new_item):
	if not current_slot in GameManager.equipped_items:
		return

	var old_item = GameManager.equipped_items.get(current_slot, null)
	
	# Ensure both items have stats, defaulting to `{}` if missing
	var old_stats = old_item.get("stats", {}) if old_item != null else {}
	var new_stats = new_item.get("stats", {})

	# Ensure each stat exists, defaulting to 0
	var old_defense = old_stats.get("flat_defense", 0)
	var new_defense = new_stats.get("flat_defense", 0)

	# Gather resistance stats
	var old_resistances = old_stats.get("resistances", {})
	var new_resistances = new_stats.get("resistances", {})

	# Gather attack stats (if it's a weapon)
	var old_attack = old_item.get("attack", {}) if old_item != null else {}
	var new_attack = new_item.get("attack", {})

	# Construct comparison text
	var comparison_text = "Comparing:\n"
	comparison_text += "Defense: %d → %d\n" % [old_defense, new_defense]

	# Compare resistances
	for attack_type in new_resistances.keys():
		var old_resist = old_resistances.get(attack_type, 0)
		var new_resist = new_resistances.get(attack_type, 0)
		comparison_text += "%s Resistance: %.2f → %.2f\n" % [attack_type, old_resist, new_resist]

	# Compare attack stats if it's a weapon
	if new_attack.size() > 0:
		comparison_text += "\nAttack Stats:\n"
		for attack_type in new_attack.keys():
			var old_attack_value = old_attack.get(attack_type, 0)
			var new_attack_value = new_attack.get(attack_type, 0)
			comparison_text += "%s: %d → %d\n" % [attack_type, old_attack_value, new_attack_value]

	# ✅ Move the comparison menu to the mouse position
	var mouse_pos = get_viewport().get_mouse_position()
	print_debug("Emitting Comparison Signal:", comparison_text)
	GameManager.emit_signal("show_comparison", comparison_text, mouse_pos)

func _clear_comparison():
	GameManager.emit_signal("show_comparison", "")  # Send an empty string to clear it

func equip_item(item):
	print_debug("Equipping:", item["name"], "to slot:", current_slot)

	# Get the item's stats safely
	var item_stats = item.get("stats", {})

	# Ensure attack and armor_pierce are extracted correctly
	var attack_stats = item_stats.get("attack", {}).duplicate(true)  # ✅ Ensure copy
	var armor_pierce_stats = item_stats.get("armor_pierce", {}).duplicate(true)  # ✅ Ensure copy

	# Store in GameManager
	GameManager.equipped_items[current_slot] = {
		"name": item.get("name", ""),
		"icon_path": item.get("icon_path", ""),
		"flat_defense": item_stats.get("flat_defense", 0),
		"resistances": item_stats.get("resistances", {}).duplicate(true),  # ✅ Ensure copy
		"attack": attack_stats,  # ✅ Now properly stored
		"armor_pierce": armor_pierce_stats  # ✅ Now properly stored
	}

	# Debugging: Confirm attack and armor_pierce are set correctly
	print_debug("Weapon Attack:", attack_stats)
	print_debug("Armor Pierce:", armor_pierce_stats)

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
