extends Panel

@onready var grid_container = $GridContainer
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

	# Get items from inventory
	var items = GameManager.inventory.get(current_slot, [])
	print("Updating items for slot:", current_slot, "Items:", items)

	for item in items:
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
			print("Setting icon for item:", item.name, "in slot:", current_slot)
		else:
			print("WARNING: Item", item.name, "has no 'icon_path'!")

		icon_container.add_child(texture_rect)
		item_container.add_child(icon_container)

		# **Make the item selectable**
		var select_button = Button.new()
		select_button.text = "Equip " + item.name
		select_button.connect("pressed", Callable(self, "_on_item_selected").bind(item))
		item_container.add_child(select_button)

		grid_container.add_child(item_container)
		

func equip_item(item):
	if current_slot in slot_buttons:
		var button = slot_buttons[current_slot]
		if item.has("icon_path"):
			button.icon = load(item["icon_path"])  # Load from path
			print("Equipped", item.name, "to", current_slot)
		else:
			print("ERROR: No 'icon_path' found in item:", item)
	else:
		print("ERROR: No button found for slot", current_slot)

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

	hide()  # Close menu


	
	# Close the menu if clicking outside of it
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var rect = get_global_rect()
		if not rect.has_point(get_global_mouse_position()):
			hide()
