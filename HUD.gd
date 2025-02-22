extends Control

# UI Nodes
@onready var gold_label: Label = $GoldLabel
@onready var xp_label: Label = $XPLabel
@onready var hunt_button: Button = $MainHbox/HuntButton
@onready var travel_button: Button = $TravelButton
@onready var background: TextureRect = $TextureRect
@onready var travel_menu: Popup = $TravelMenu
@onready var travel_vbox: VBoxContainer = $TravelMenu/Panel/VBoxContainer
@onready var inventory_list: VBoxContainer = $InventoryPanel/VBoxContainer

# Location Backgrounds
var locations: Dictionary = {
	"Mayflower": "res://assets/backgrounds/mayflower.png",
	"Cave": "res://assets/backgrounds/cave_entrance.png"
}

func _ready() -> void:
	# Validate critical nodes
	if not _validate_nodes():
		return
	
	_setup_travel_menu()
	_connect_signals()
	_update_ui()
	_update_background(GameManager.current_location)
	print_debug("HUD initialized")

func _validate_nodes() -> bool:
	var missing_nodes = []
	if not gold_label: missing_nodes.append("GoldLabel")
	if not xp_label: missing_nodes.append("XPLabel")
	if not hunt_button: missing_nodes.append("HuntButton")
	if not travel_button: missing_nodes.append("TravelButton")
	if not background: missing_nodes.append("TextureRect")
	if not travel_menu: missing_nodes.append("TravelMenu")
	if not travel_vbox: missing_nodes.append("TravelVbox")
	if not inventory_list: missing_nodes.append("InventoryList")
	
	if missing_nodes:
		print_debug("ERROR: Missing nodes:", missing_nodes)
		return false
	return true

func _connect_signals() -> void:
	GameManager.stats_updated.connect(_update_ui)
	GameManager.hunt_reset.connect(_update_ui)
	GameManager.location_changed.connect(_update_background)
	
	if not travel_button.is_connected("pressed", _on_travel_pressed):
		travel_button.pressed.connect(_on_travel_pressed)

func _update_ui() -> void:
	gold_label.text = "Gold: %d" % GameManager.player_gold
	xp_label.text = "XP: %d" % GameManager.player_experience
	_update_inventory_display()

func _update_background(location: String) -> void:
	if location in locations:
		var texture = load(locations[location])
		if texture:
			background.texture = texture
			print_debug("Background updated to:", location)
		else:
			print_debug("ERROR: Failed to load texture for:", location)
	else:
		print_debug("WARNING: No background for location:", location)

func _setup_travel_menu() -> void:
	for child in travel_vbox.get_children():
		child.queue_free()
	
	for location in locations.keys():
		var button = Button.new()
		button.text = location
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_color_hover", Color(1, 0.8, 0.2))
		button.add_theme_color_override("font_color_pressed", Color.RED)
		button.pressed.connect(_on_location_selected.bind(location))
		travel_vbox.add_child(button)
	
	print_debug("Travel menu set up with", travel_vbox.get_child_count(), "locations")

func _on_travel_pressed() -> void:
	travel_menu.popup_centered(Vector2(200, 200))
	print_debug("Travel menu opened")

func _on_location_selected(location: String) -> void:
	GameManager.change_location(location)
	travel_menu.hide()
	_update_background(location)
	print_debug("Location selected:", location)

func _update_inventory_display() -> void:
	for child in inventory_list.get_children():
		child.queue_free()
	
	for category in GameManager.inventory.keys():
		for item in GameManager.inventory[category]:
			var button = Button.new()
			var is_equipped = GameManager.equipped_items.get(category) == item
			button.text = "%s (%s)%s" % [item["name"], category.capitalize(), " [E]" if is_equipped else ""]
			button.pressed.connect(_equip_item.bind(category, item))
			# Add hover effect for item details
			button.mouse_entered.connect(_show_item_details.bind(item))
			button.mouse_exited.connect(_hide_item_details)
			inventory_list.add_child(button)
	
	print_debug("Inventory display updated")

func _equip_item(category: String, item: Dictionary) -> void:
	GameManager.equip_item(category, item)
	_update_ui()
	print_debug("Equipped:", item["name"], "in", category)

func _show_item_details(item: Dictionary) -> void:
	var stats = item.get("stats", {})
	var text = "%s\n" % item["name"]
	if "flat_defense" in stats:
		text += "Defense: %d\n" % stats["flat_defense"]
	if "resistances" in stats:
		for type in stats["resistances"]:
			text += "%s Resist: %.2f\n" % [type, stats["resistances"][type]]
	if "attack" in item:
		for type in item["attack"]:
			text += "%s Attack: %d\n" % [type, item["attack"][type]]
	GameManager.emit_signal("show_comparison", text, get_global_mouse_position())

func _hide_item_details() -> void:
	GameManager.emit_signal("show_comparison", "", Vector2.ZERO)

# Debug function (optional, can be removed later)
func print_nodes(node: Node = self, indent: String = "") -> void:
	print(indent + node.name)
	for child in node.get_children():
		print_nodes(child, indent + "  ")
