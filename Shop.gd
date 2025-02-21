extends Panel

@onready var shop_menu = $"."
@onready var shop_button = $"../ShopButton"
@onready var close_button = $CloseButton
@onready var categories_container = $CategoriesContainer
@onready var weapons_button = $CategoriesContainer/WeaponsButton
@onready var armor_button = $CategoriesContainer/ArmorButton
@onready var charms_button = $CategoriesContainer/CharmsButton
@onready var greases_button = $CategoriesContainer/GreasesButton
@onready var shop_submenu = $ShopSubMenu
@onready var item_list_container = $ShopSubMenu/ItemListContainer
@onready var back_button = $ShopSubMenu/BackButton

# Sample shop inventory
var shop_inventory = {
	"Weapons": [
		{name = "Iron Sword", price = 100, icon_path = "res://assets/weapons/ironsword.png", stats = {"attack": {"Slash": 10, "Pierce": 5, "Blunt": 2}}},
		{name = "Steel Dagger", price = 150, icon_path = "res://assets/weapons/steeldagger.png", stats = {"attack": {"Slash": 12, "Pierce": 8}}}
	],
	"Armor": [
		{name = "Iron Helmet", price = 80, icon_path = "res://assets/armor/ironhelmet.png", stats = {"flat_defense": 5, "resistances": {"Blunt": 0.1, "Slash": 0.05}}},
		{name = "Bronze Breastplate", price = 200, icon_path = "res://assets/armor/bronze_breastplate.png", stats = {"flat_defense": 10, "resistances": {"Slash": 0.2, "Pierce": 0.1}}}
	],
	"Charms": [
		{name = "Fire Charm", price = 120, icon_path = "res://assets/charms/firecharm.png", stats = {}},
		{name = "Water Charm", price = 150, icon_path = "res://assets/charms/watercharm.png", stats = {}}
	],
	"Greases": [
		{name = "Poison Grease", price = 50, icon_path = "res://assets/greases/poisongrease.png", stats = {}},
		{name = "Flame Grease", price = 60, icon_path = "res://assets/greases/flamegrease.png", stats = {}}
	]
}


func _ready():
	shop_menu.hide()
	shop_submenu.hide()

	shop_button.connect("pressed", Callable(self, "_toggle_shop"))
	close_button.connect("pressed", Callable(self, "_toggle_shop"))
	back_button.connect("pressed", Callable(self, "_return_to_categories"))

	weapons_button.connect("pressed", Callable(self, "_show_shop_items").bind("Weapons"))
	armor_button.connect("pressed", Callable(self, "_show_shop_items").bind("Armor"))
	charms_button.connect("pressed", Callable(self, "_show_shop_items").bind("Charms"))
	greases_button.connect("pressed", Callable(self, "_show_shop_items").bind("Greases"))

func _toggle_shop():
	shop_menu.visible = not shop_menu.visible

func _return_to_categories():
	shop_submenu.hide()
	categories_container.show()

func _show_shop_items(category: String):
	# Clear previous items
	for child in item_list_container.get_children():
		child.queue_free()

	# Show items from selected category
	for item in shop_inventory[category]:
		var item_button = Button.new()
		item_button.text = "%s - %d Gold" % [item.name, item.price]
		item_button.connect("pressed", Callable(self, "_attempt_purchase").bind(category, item))
		item_list_container.add_child(item_button)
	_update_shop_display(category)
	categories_container.hide()
	shop_submenu.show()

func equip_item(slot: String, item: Dictionary):
	print_debug("Equipping:", item["name"], "to slot:", slot)

	# Store in GameManager
	GameManager.equipped_items[slot] = {
		"name": item.get("name", ""),
		"icon_path": item.get("icon_path", ""),
		"flat_defense": item.get("stats", {}).get("flat_defense", 0),
		"resistances": item.get("stats", {}).get("resistances", {}),
		"attack": item.get("attack", {})  # Ensure attack key exists
	}

	# Apply the item's defense and resistances
	GameManager.player_defense += GameManager.equipped_items[slot]["flat_defense"]

	# Debugging: Check if defense is applied correctly
	print_debug("Updated Defense:", GameManager.player_defense)

	if GameManager.equipped_items[slot].has("resistances"):
		for attack_type in GameManager.equipped_items[slot]["resistances"]:
			GameManager.player_resistances[attack_type] += GameManager.equipped_items[slot]["resistances"][attack_type]

	# Ensure weapon attack is applied correctly
	if slot == "weapon":
		var attack_values = GameManager.equipped_items[slot].get("attack", {})
		if attack_values:
			for attack_type in attack_values:
				print_debug("Weapon Attack:", attack_type, "=", attack_values[attack_type])
		else:
			print_debug("Equipped weapon has no attack values.")
func _attempt_purchase(category: String, item: Dictionary):
	# Map shop categories to correct inventory slots
	var category_to_slot = {
		"Weapons": "weapon",
		"Armor": "",  # Will determine based on item name
		"Charms": "charms",
		"Greases": "greases"
	}

	# Special handling for armor (since it has multiple slots)
	if category == "Armor":
		var name_lower = item.name.to_lower()
		if "helmet" in name_lower:
			category_to_slot["Armor"] = "helmet"
		elif "breastplate" in name_lower or "chest" in name_lower:
			category_to_slot["Armor"] = "breastplate"
		elif "gloves" in name_lower:
			category_to_slot["Armor"] = "gloves"
		elif "greaves" in name_lower or "leggings" in name_lower:
			category_to_slot["Armor"] = "greaves"
		elif "boots" in name_lower or "shoes" in name_lower:
			category_to_slot["Armor"] = "shoes"

	var slot = category_to_slot.get(category, "")

	# Ensure valid inventory slot
	if slot == "" or not slot in GameManager.inventory:
		print("Error: Invalid inventory slot:", slot)
		return

	# Prevent duplicate purchases of non-stackable items
	for existing_item in GameManager.inventory[slot]:
		if existing_item.name == item.name:
			print("You already own:", item.name)
			return

	# Deduct gold and add item
	if GameManager.player_gold >= item.price:
		GameManager.player_gold -= item.price

		# Ensure correct format
		var item_to_add = {
			"name": item.name,
			"icon_path": item.icon_path,
			"stats": item.get("stats", {}),  # Default to empty stats if not provided
			"attack": item.get("attack", {})  # Ensure attack key exists
		}

		GameManager.add_item(slot, item_to_add)  # Store in inventory
		GameManager.emit_signal("stats_updated")  # Refresh UI
		
		# ✅ Remove item from the shop inventory
		shop_inventory[category].erase(item)
		_update_shop_display(category)  # Refresh the shop menu
		print("Purchased:", item.name)
	else:
		print("Not enough gold to buy", item.name)

func _update_shop_display(category: String):
	# Clear previous items
	for child in item_list_container.get_children():
		child.queue_free()

	# Show remaining items from selected category
	for item in shop_inventory[category]:
		var item_button = Button.new()
		item_button.text = "%s - %d Gold" % [item.name, item.price]
		item_button.connect("pressed", Callable(self, "_attempt_purchase").bind(category, item))
		item_list_container.add_child(item_button)

	print("Updated shop display for:", category)

