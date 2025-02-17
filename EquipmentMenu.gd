
extends Panel

@onready var grid_container = $GridContainer
var current_slot = ""

func _ready():
	hide()  # Ensure the menu is hidden on game start

func show_menu(slot: String):
	print("Equipment menu opened for:", slot)
	current_slot = slot
	update_items()
	show()

func update_items():
	# Clear previous items
	for child in grid_container.get_children():
		grid_container.remove_child(child)
		child.queue_free()

	# Get items from inventory
	var items = GameManager.inventory[current_slot]
	
	for item in items:
		var item_container = HBoxContainer.new()  # Holds both sprite & button
		item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Create a Control node to constrain the icon size
		var icon_container = Control.new()
		icon_container.custom_minimum_size = Vector2(32, 32)  # Strict size limit

	# Create Sprite (TextureRect)
		var texture_rect = TextureRect.new()
		texture_rect.custom_minimum_size = Vector2(32, 32)  # Force strict size
		texture_rect.expand = true  # Prevent it from resizing uncontrollably
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		if item.has("icon_path") and item.icon_path != "":
			var texture = load(item.icon_path)  # Load image
			if texture:
				texture_rect.texture = texture
				texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				texture_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			else:
				print("Failed to load texture:", item.icon_path)
		else:
			print("No icon path found for item:", item.name)
			
			icon_container.add_child(texture_rect)

		# Create Button
		var button = Button.new()
		button.text = item.name
		button.custom_minimum_size = Vector2(100, 32)  # Ensures buttons don't stretch
		button.connect("pressed", Callable(self, "_on_item_selected").bind(item))
		

		# Add sprite and button to the container
		item_container.add_child(texture_rect)
		item_container.add_child(button)

		# Add the container to GridContaine
		grid_container.add_child(item_container)

func _on_item_selected(item: Dictionary):
	GameManager.equip_item(current_slot, item)  # Equip the item

	# Get the Main node first
	var main = get_tree().get_root().get_node("Main")
	if main and main.has_node("AvatarMenu"):
		var avatar_menu = main.get_node("AvatarMenu")  # Get AvatarMenu correctly
		print("Avatar Menu Found:", avatar_menu)

		# Now check for HelmetButton inside AvatarMenu
		if avatar_menu.has_node("HelmetButton"):
			var button = avatar_menu.get_node("HelmetButton")
			print("Button Found:", button)
			
			if button and item.has("icon_path"):
				var texture = load(item.icon_path)
				if texture:
					if button is TextureButton:
						button.texture_normal = texture  # Assign the icon properly
					else:
						button.icon = texture  # Fallback for regular Button
						
						
					# **FORCE STRICT SIZE LIMITS**
					#button.custom_minimum_size = Vector2(32, 32)  # Force exact size
					#button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
					#button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
					#button.queue_redraw()  # Force UI refresh
					
					
					
					
				else:
					print("Failed to load equipped item icon:", item.icon_path)
			else:
				print("No valid icon path in item:", item)
		else:
			print("HelmetButton Not Found inside AvatarMenu!")
	else:
		print("Main Scene or AvatarMenu Not Found!")
	hide()  # Close menu

	
	# Close the menu if clicking outside of it
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var rect = get_global_rect()
		if not rect.has_point(get_global_mouse_position()):
			hide()
