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
@onready var comparison_panel = get_node("/root/Main/HUD/AvatarMenu/ComparisonPanel")
@onready var comparison_label = get_node("/root/Main/HUD/AvatarMenu/ComparisonPanel/ComparisonLabel")

# Sample shop inventory
var shop_inventory = {
	"Weapons": [
		{
			"name": "Iron Sword",
			"price": 100,
			"icon_path": "res://assets/weapons/ironsword.png",
			"stats": {
				"attack": {"Slash": 10, "Pierce": 5, "Blunt": 2},
				"armor_pierce": {"Slash": 0.3, "Pierce": 0.1, "Blunt": 0}
			}
		},
		{
			"name": "Steel Dagger",
			"price": 150,
			"icon_path": "res://assets/weapons/steeldagger.png",
			"stats": {
				"attack": {"Slash": 12, "Pierce": 8},
				"armor_pierce": {"Slash": 0.2, "Pierce": 0.15}
			}
		}
	],
	"Armor": [
		{
			"name": "Iron Helmet",
			"price": 80,
			"icon_path": "res://assets/armor/ironhelmet.png",
			"stats": {
				"flat_defense": 5,
				"resistances": {"Blunt": 0.1, "Slash": 0.05}
			}
		},
		{
			"name": "Bronze Breastplate",
			"price": 200,
			"icon_path": "res://assets/armor/bronze_breastplate.png",
			"stats": {
				"flat_defense": 10,
				"resistances": {"Slash": 0.2, "Pierce": 0.1}
			}
		}
	],
	"Charms": [
		{
			"name": "Fire Charm",
			"price": 120,
			"icon_path": "res://assets/charms/firecharm.png",
			"stats": {}
		},
		{
			"name": "Water Charm",
			"price": 150,
			"icon_path": "res://assets/charms/watercharm.png",
			"stats": {}
		}
	],
	"Greases": [
		{
			"name": "Poison Grease",
			"price": 50,
			"icon_path": "res://assets/greases/poisongrease.png",
			"stats": {}
		},
		{
			"name": "Flame Grease",
			"price": 60,
			"icon_path": "res://assets/greases/flamegrease.png",
			"stats": {}
		}
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
		# ✅ Connect hover signals
		item_button.connect("mouse_entered", Callable(self, "_compare_shop_item").bind(item))
		item_button.connect("mouse_exited", Callable(self, "_clear_comparison"))
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
		"attack": item.get("attack", {}),  # Ensure attack key exists
		"armor_pierce": item.get("stats", {}).get("armor_pierce", {})
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
		"Armor": "",  # Determine based on item name
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

	# Deduct gold and add item **without modifying structure**
	if GameManager.player_gold >= item.price:
		GameManager.player_gold -= item.price

		# ✅ Store the item exactly as it is in the shop, making sure attack exists
		var item_to_add = {
			"name": item.name,
			"icon_path": item.icon_path,
			"stats": item.get("stats", {}),  # Default to empty stats if not provided
		}
		# ✅ Ensure "attack" is properly stored only if it exists
		if "attack" in item.stats:
			item_to_add["attack"] = item.stats.attack

		GameManager.add_item(slot, item_to_add)
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
	
# ✅ Display Comparison for Shop Items
# **Function to show comparison when hovering over a shop item**
func _compare_shop_item(item: Dictionary):
	if not comparison_panel or not comparison_label:
		print("Error: Comparison Panel not found in Shop!")
		return
	
	var equipped_slot = ""
	var equipped_item = null

	# Find which slot this item would go into
	if "weapon" in item.name.to_lower():
		equipped_slot = "weapon"
	elif "helmet" in item.name.to_lower():
		equipped_slot = "helmet"
	elif "breastplate" in item.name.to_lower() or "chest" in item.name.to_lower():
		equipped_slot = "breastplate"
	elif "gloves" in item.name.to_lower():
		equipped_slot = "gloves"
	elif "greaves" in item.name.to_lower() or "leggings" in item.name.to_lower():
		equipped_slot = "greaves"
	elif "boots" in item.name.to_lower() or "shoes" in item.name.to_lower():
		equipped_slot = "shoes"
	elif "charm" in item.name.to_lower():
		equipped_slot = "charms"
	elif "grease" in item.name.to_lower():
		equipped_slot = "greases"

	# Get currently equipped item in that slot
	if equipped_slot in GameManager.equipped_items:
		equipped_item = GameManager.equipped_items[equipped_slot]

	# Build comparison text
	var comparison_text = "Comparing:\n"
	
	# Show item's base stats
	if "flat_defense" in item.stats:
		comparison_text += "Defense: %d\n" % item.stats.flat_defense
	if "resistances" in item.stats:
		for attack_type in item.stats.resistances.keys():
			comparison_text += "%s Resistance: %.2f\n" % [attack_type, item.stats.resistances[attack_type]]
	if "attack" in item.stats:
		comparison_text += "\nAttack Stats:\n"
		for attack_type in item.stats.attack.keys():
			comparison_text += "%s: %d\n" % [attack_type, item.stats.attack[attack_type]]

	# Compare with equipped item
	if equipped_item:
		comparison_text += "\nEquipped Comparison:\n"
		if "flat_defense" in equipped_item:
			comparison_text += "Defense: %d → %d\n" % [equipped_item.get("flat_defense", 0), item.stats.get("flat_defense", 0)]
		if "resistances" in equipped_item:
			for attack_type in equipped_item.get("resistances", {}):
				var old_resist = equipped_item["resistances"].get(attack_type, 0)
				var new_resist = item.stats.get("resistances", {}).get(attack_type, 0)
				comparison_text += "%s Resistance: %.2f → %.2f\n" % [attack_type, old_resist, new_resist]
		if "attack" in equipped_item:
			comparison_text += "\nAttack Stats:\n"
			for attack_type in equipped_item.get("attack", {}):
				var old_attack = equipped_item["attack"].get(attack_type, 0)
				var new_attack = item.stats.get("attack", {}).get(attack_type, 0)
				comparison_text += "%s: %d → %d\n" % [attack_type, old_attack, new_attack]

	# Show the comparison panel at the mouse position
	var mouse_pos = get_viewport().get_mouse_position()
	comparison_panel.global_position = mouse_pos + Vector2(10, 10)
	comparison_label.text = comparison_text
	comparison_panel.show()

# Ensure comparison panel hides when no longer hovering
func _clear_comparison():
	if comparison_panel:
		comparison_panel.hide()

# ✅ Find the Equipped Item in the Correct Slot
func _get_equipped_item(category: String, shop_item_name: String) -> Dictionary:
	var slot = ""

	if category == "Weapons":
		slot = "weapon"
	elif category == "Armor":
		if "helmet" in shop_item_name.to_lower():
			slot = "helmet"
		elif "breastplate" in shop_item_name.to_lower() or "chest" in shop_item_name.to_lower():
			slot = "breastplate"
		elif "gloves" in shop_item_name.to_lower():
			slot = "gloves"
		elif "greaves" in shop_item_name.to_lower():
			slot = "greaves"
		elif "boots" in shop_item_name.to_lower() or "shoes" in shop_item_name.to_lower():
			slot = "shoes"

	# Return the equipped item (or an empty dictionary if nothing is equipped)
	return GameManager.equipped_items.get(slot, {})
