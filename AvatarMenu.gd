
extends Panel

@onready var helmet_button = $HelmetButton
@onready var breastplate_button = $BreastplateButton
@onready var gloves_button = $GlovesButton
@onready var greaves_button = $GreavesButton
@onready var shoes_button = $ShoesButton
@onready var weapon_button = $WeaponButton
@onready var defense_label = $StatsBox/DefenseLabel
@onready var strength_label = $StatsBox/StrengthLabel
@onready var equipment_menu = $EquipmentMenu
@onready var comparison_label = $ComparisonLabel

func _ready():
	if GameManager:
		GameManager.connect("stats_updated", Callable(self, "_update_avatar_stats"))
		GameManager.connect("show_comparison", Callable(self, "_update_comparison"))
	else:
		print("ERROR: GameManager not found!")
		
	_update_avatar_stats()  # Initialize
	
	helmet_button.connect("pressed", Callable(self, "_on_slot_pressed").bind("helmet"))
	breastplate_button.connect("pressed", Callable(self, "_on_slot_pressed").bind("breastplate"))
	gloves_button.connect("pressed", Callable(self, "_on_slot_pressed").bind("gloves"))
	greaves_button.connect("pressed", Callable(self, "_on_slot_pressed").bind("greaves"))
	shoes_button.connect("pressed", Callable(self, "_on_slot_pressed").bind("shoes"))
	weapon_button.connect("pressed", Callable(self, "_on_slot_pressed").bind("weapon"))

func _update_avatar_stats():
	defense_label.text = "Defense: " + str(GameManager.player_defense)
	strength_label.text = "Strength: " + str(GameManager.player_strength)

func _on_slot_pressed(slot: String):
	equipment_menu.show_menu(slot)
	
func _update_comparison(text):
	comparison_label.text = text
