extends Control  # HUD

@onready var gold_label = find_child("GoldLabel", true, false)
@onready var xp_label = find_child("XPLabel", true, false)
@onready var hunt_button = find_child("MainHbox/HuntButton")
@onready var travel_button = $TravelButton
@onready var background = find_child("TextureRect")  # Get background texture
@onready var travel_menu = $TravelMenu  # Popup menu for locations
@onready var travel_vbox = $TravelMenu/Panel/VBoxContainer  # VBox inside popup
@onready var inventory_list = $InventoryPanel/VBoxContainer  # Add this node in UI

# Background images for locations
var locations = {
	"Mayflower": "res://assets/backgrounds/mayflower.png",
	"Cave": "res://assets/backgrounds/cave_entrance.png",
	
}

# **Ensure _update_background is properly defined**
func _update_background(location):
	print("Updating background to:", location)  # Debugging
	if location in locations:
		var new_texture = load(locations[location])
		
		if new_texture:
			background.texture = new_texture
			print("Background updated successfully.")
		else:
			print("ERROR: Failed to load texture for", location)
	else:
		print("WARNING: No background found for", location)

func _ready():
	_setup_travel_menu()
	GameManager.connect("stats_updated", Callable(self, "_update_ui"))
	GameManager.connect("hunt_reset", Callable(self, "_update_ui"))
	GameManager.connect("location_changed", Callable(self, "_update_background"))

	_update_ui()  # Initialize UI
	_update_background(GameManager.current_location)  # Set initial background

	if not travel_button:
		print("ERROR: Travel Button not found in HUD!")

	# **Manually connect Travel Button if found**
	if travel_button and not travel_button.is_connected("pressed", Callable(self, "_on_travel_pressed")):
		travel_button.connect("pressed", Callable(self, "_on_travel_pressed"))
		print("HUD Ready. Travel Button Connected.")
	else:
		print("ERROR: Travel Button connection failed.")



func _update_ui():
	gold_label.text = "Gold: " + str(GameManager.player_gold)
	xp_label.text = "XP: " + str(GameManager.player_experience)

func _setup_travel_menu():
	if not travel_vbox:
		print("ERROR: Cannot populate Travel Menu! VBoxContainer not found.")
		return

	print("Setting up Travel Menu...")  # Debugging

	# Clear previous buttons
	for child in travel_vbox.get_children():
		travel_vbox.remove_child(child)
		child.queue_free()

	# Create and style buttons for each location
	for location in locations.keys():
		var button = Button.new()
		button.text = location
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Fill width
		button.add_theme_font_size_override("font_size", 20)  # Larger text
		button.add_theme_color_override("font_color", Color(1, 1, 1))  # White text
		button.add_theme_color_override("font_color_hover", Color(1, 0.8, 0.2))  # Yellow when hovered
		button.add_theme_color_override("font_color_pressed", Color(1, 0, 0))  # Red when clicked
		button.connect("pressed", Callable(self, "_on_location_selected").bind(location))
		travel_vbox.add_child(button)

	print("Travel Menu Setup Complete. Buttons Styled and Added:", travel_vbox.get_child_count())

func _on_travel_pressed():
	print("Travel Button Pressed!")  # Debugging

	# Set popup size before showing it
	travel_menu.set_size(Vector2(200, 200))  # Adjust width and height

	travel_menu.popup_centered()  # Show the travel selection popup

func _on_location_selected(location):
	GameManager.change_location(location)  # Update location in GameManager
	travel_menu.hide()  # Close the menu after selecting
	_update_background(location)  # Ensure background changes immediately


func _on_travel_button_pressed() -> void:
	pass # Replace with function body.

func _update_inventory_display():
	if not inventory_list:
		print("Error: Inventory panel not found!")
		return

	# Clear old items
	for child in inventory_list.get_children():
		child.queue_free()

	# Display current inventory
	for category in GameManager.inventory.keys():
		for item in GameManager.inventory[category]:
			var item_button = Button.new()
			item_button.text = "%s (%s)" % [item.name, category.capitalize()]
			item_button.connect("pressed", Callable(self, "_equip_item").bind(category, item))
			inventory_list.add_child(item_button)

	print("Inventory updated:", GameManager.inventory)
