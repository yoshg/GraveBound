extends PopupPanel  # Or whatever your root node type is

# Define the signal
signal equipment_selected(slot_type: String, item_name: String)

# Define the slot_type variable
var slot_type: String

func _ready():
	print("Equipment menu opened for:", slot_type)
	# Populate the item list based on the slot type
	populate_item_list()

func populate_item_list():
	match slot_type:
		"Helmet":
			print("Loading helmet items...")
			# Add helmet items to the list
		"Breastplate":
			print("Loading breastplate items...")
			# Add breastplate items to the list
		# Add more cases for other slot types
		
func _on_EquipButton_pressed():
	var selected_item = "Iron Helmet"  # Replace with actual selected item
	print("Emitting equipment_selected signal with:", slot_type, selected_item)
	emit_signal("equipment_selected", slot_type, selected_item)
	queue_free()  # Close the menu

func _on_CloseButton_pressed():
	hide()  # Hides the popup instead of deleting it
