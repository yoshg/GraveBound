extends Panel

@onready var label = $ComparisonLabel

func _ready():
	hide()  # Start hidden

func _process(delta):
	# Move the panel only when it's visible
	if visible:
		global_position = get_viewport().get_mouse_position() + Vector2(10, 10)  # Offset to prevent overlap

func show_comparison(text: String):
	if text.strip_edges() == "":
		hide()
	else:
		label.text = text
		show()
		# Move to the mouse position immediately when shown
		global_position = get_viewport().get_mouse_position() + Vector2(10, 10)
		print_debug("ComparisonPanel Showing at:", global_position)
