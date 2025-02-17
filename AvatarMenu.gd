
extends Panel

@onready var helmet_button = $HelmetButton
@onready var breastplate_button = $BreastplateButton
@onready var gloves_button = $GlovesButton
@onready var greaves_button = $GreavesButton
@onready var shoes_button = $ShoesButton
@onready var weapon_button = $WeaponButton

@onready var equipment_menu = $EquipmentMenu

func _ready():
	helmet_button.connect("pressed", Callable(self, "_on_slot_pressed").bind("helmet"))
	
	breastplate_button.connect("pressed", Callable(self, "_on_slot_pressed").bind("breastplate"))
	gloves_button.connect("pressed", Callable(self, "_on_slot_pressed").bind("gloves"))
	greaves_button.connect("pressed", Callable(self, "_on_slot_pressed").bind("greaves"))
	shoes_button.connect("pressed", Callable(self, "_on_slot_pressed").bind("shoes"))
	weapon_button.connect("pressed", Callable(self, "_on_slot_pressed").bind("weapon"))

func _on_slot_pressed(slot: String):
	equipment_menu.show_menu(slot)
