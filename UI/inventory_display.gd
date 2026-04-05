extends MarginContainer

@onready var weapon_row = %WeaponRow
@onready var passive_row = %PassiveRow

# We'll use these to keep track of the slot nodes we created
var weapon_slots = []
var passive_slots = []

func _ready():
	# Store the slots in arrays for easy access later
	weapon_slots = weapon_row.get_children()
	passive_slots = passive_row.get_children()
	
	# Connect to the signal that will trigger the visual update
	GameEvents.update_inventory_ui.connect(update_display)
	
	# Pull initial state from ProgressionManager so starting items appear immediately
	update_display(ProgressionManager.current_weapons, ProgressionManager.current_passives)

func update_display(weapons: Array, passives: Array):
	# Loop through weapon slots
	for i in range(weapon_slots.size()):
		if i < weapons.size():
			# This assumes your UpgradeResource has an 'icon' property
			weapon_slots[i].set_icon(weapons[i].icon)
		else:
			weapon_slots[i].set_icon(null)
			
	# Loop through passive slots
	for i in range(passive_slots.size()):
		if i < passives.size():
			passive_slots[i].set_icon(passives[i].icon)
		else:
			passive_slots[i].set_icon(null)
