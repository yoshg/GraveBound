extends Panel

const MAX_ENTRIES = 4  # Keep only the last 4 fights

@onready var log_container = $ScrollContainer/VBoxContainer  # The VBoxContainer inside CombatLog

var logs = []  # Stores fight history

func _ready():
	hide()  # Hide on game start
	GameManager.connect("fight_recorded", Callable(self, "_add_fight_log"))

func _add_fight_log(result: Dictionary):
	show()  # Make the panel visible when a fight is logged
	
# Log Entry Container
	var log_entry = HBoxContainer.new()
	log_entry.custom_minimum_size = Vector2(250, 50)  # Set a fixed row height
	log_entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Make sure it expands horizontally
	log_entry.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Prevent vertical stretching

	# Enemy Thumbnail
	var thumbnail = TextureRect.new()
	thumbnail.custom_minimum_size = Vector2(40, 40)  # Set a max size
	thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumbnail.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	thumbnail.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Prevent stretching
	thumbnail.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Prevent stretchingCT_CENTERED
	
	
	# Ensure the image exists before assigning
	if result.enemy_name in GameManager.enemy_images:
		thumbnail.texture = GameManager.enemy_images[result.enemy_name]
		print("Thumbnail assigned for:", result.enemy_name)
	else:
		print("No image found for:", result.enemy_name)

	# Enemy Info Label
	var log_text = Label.new()
	log_text.text = "%s - Loot: %d Gold, %d XP" % [
		result.enemy_name, result.gold_drop, result.xp_drop
	]
	log_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_text.add_theme_font_size_override("font_size", 14)  # Increase readability
	print("Log entry added:", log_text.text)
	# Add elements to entry
	log_entry.add_child(thumbnail)
	log_entry.add_child(log_text)

	# Add entry to the log container
	log_container.add_child(log_entry)
	logs.append(log_entry)

	# Keep only last 4 entries
	if logs.size() > MAX_ENTRIES:
		var removed_entry = logs.pop_front()
		log_container.remove_child(removed_entry)
		removed_entry.queue_free()
