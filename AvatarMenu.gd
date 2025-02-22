extends Panel

@onready var	helmet_button: Button = $HelmetButton
@onready var	breastplate_button: Button = $BreastplateButton
@onready var	gloves_button: Button = $GlovesButton
@onready var	greaves_button: Button = $GreavesButton
@onready var	shoes_button: Button = $ShoesButton
@onready var	weapon_button: Button = $WeaponButton
@onready var	defense_label: Label = $StatsBox/DefenseLabel
@onready var	strength_label: Label = $StatsBox/StrengthLabel
@onready var	equipment_menu: Node = $EquipmentMenu
@onready var	comparison_panel: Panel = $ComparisonPanel
@onready var	comparison_label: Label = $ComparisonPanel/ComparisonLabel

func	_ready() -> void:
	await	get_tree().process_frame
	
	if	not is_instance_valid(comparison_panel) or not is_instance_valid(comparison_label):
		print_debug("Error: ComparisonPanel or ComparisonLabel not found in AvatarMenu!")
		return
	
	if	not GameManager:
		print_debug("ERROR: GameManager not found!")
		return
	
	GameManager.stats_updated.connect(_update_avatar_stats)
	GameManager.show_comparison.connect(_update_comparison)
	
	_update_avatar_stats()
	
	var	buttons = {
		"helmet": helmet_button,
		"breastplate": breastplate_button,
		"gloves": gloves_button,
		"greaves": greaves_button,
		"shoes": shoes_button,
		"weapon": weapon_button
	}
	
	for	slot in buttons:
		buttons[slot].gui_input.connect(_on_slot_input.bind(slot))

func	_on_slot_input(event: InputEvent, slot: String) -> void:
	if	not event is InputEventMouseButton or not event.pressed:
		return
	
	match event.button_index:
		MOUSE_BUTTON_RIGHT:
			unequip_item(slot)
		MOUSE_BUTTON_LEFT:
			print_debug("Opening Equipment Menu for:", slot)
			equipment_menu.show_menu(slot)

func	unequip_item(slot: String) -> void:
	GameManager.unequip_item(slot)
	var	button = get_node(slot.capitalize() + "Button")
	if	button:
		button.icon = null

func	_update_avatar_stats() -> void:
	var	attack_power := int(GameManager.calculate_base_attack())
	var	flat_defense := int(GameManager.calculate_total_flat_defense())
	
	defense_label.text = "Defense: %d" % flat_defense
	strength_label.text = "Power: %d" % attack_power
	
	print_debug("Updated Avatar Stats - Attack Power:", attack_power, "Flat Defense:", flat_defense)

func	_update_comparison(text: String, position: Vector2 = Vector2.ZERO) -> void:
	if	not is_instance_valid(comparison_panel) or not is_instance_valid(comparison_label):
		print_debug("Error: ComparisonPanel or ComparisonLabel not found in AvatarMenu!")
		return
	
	if	text.strip_edges().is_empty():
		comparison_panel.hide()
		return
	
	comparison_label.text = text
	comparison_panel.global_position = position
	comparison_panel.show()
	
	print_debug("Comparison Label Text Set:", text, "Position:", position)
