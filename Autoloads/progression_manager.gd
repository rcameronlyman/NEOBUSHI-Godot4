extends Node

# Drag all your upgrade_XXX.tres files into this list in the Inspector
@export var all_upgrades: Array[UpgradeResource] = []

# NEW: Assign your starting weapon upgrade here (e.g., upgrade_minigun.tres)
@export var starting_weapon: UpgradeResource

# Storage for the items the player has already collected
var current_weapons: Array[UpgradeResource] = []
var current_passives: Array[UpgradeResource] = []

func _ready() -> void:
	# 1. Initialize the inventory with the starting weapon if assigned
	if starting_weapon:
		current_weapons.append(starting_weapon)
		
	# 2. Connect to the level_up signal from GameEvents
	GameEvents.level_up.connect(_on_level_up)

func _on_level_up(_current_player_level: int) -> void:
	# 1. Pause the game 
	get_tree().paused = true
	
	# 2. Update the Inventory UI with the current collected gear 
	GameEvents.update_inventory_ui.emit(current_weapons, current_passives)
	
	# 3. Pick 3 random upgrades
	var choices = get_random_upgrades(3)
	
	# 4. Tell the UI to show these choices 
	GameEvents.display_upgrade_choices.emit(choices)

func get_random_upgrades(count: int) -> Array[UpgradeResource]:
	# Prevent errors if the upgrade pool is empty
	if all_upgrades.is_empty():
		return []
		
	var potential_upgrades = all_upgrades.duplicate()
	potential_upgrades.shuffle()
	
	var selected: Array[UpgradeResource] = []
	var actual_count = min(count, potential_upgrades.size()) 
	
	for i in range(actual_count):
		selected.append(potential_upgrades[i])
		
	return selected

# This function is called by your Upgrade Buttons when clicked 
func add_upgrade(upgrade: UpgradeResource) -> void:
	if upgrade.is_weapon:
		# Only add to the visual list if we don't already have this weapon [cite: 443]
		var already_owned = false
		for owned in current_weapons:
			if owned.upgrade_id == upgrade.upgrade_id:
				already_owned = true
				break
		
		if not already_owned:
			current_weapons.append(upgrade)
	else:
		# Only add to the visual list if we don't already have this passive [cite: 443]
		var already_owned = false
		for owned in current_passives:
			if owned.upgrade_id == upgrade.upgrade_id:
				already_owned = true
				break
		
		if not already_owned:
			current_passives.append(upgrade)
	
	# Refresh the HUD so the icon appears in the slot immediately [cite: 442]
	GameEvents.update_inventory_ui.emit(current_weapons, current_passives)
	
	# Tell the game to apply the upgrade's effects (handles the player-side level up) [cite: 442]
	if GameEvents.has_signal("upgrade_applied"):
		GameEvents.upgrade_applied.emit(upgrade)
	
	# Unpause the game after the selection is finished 
	get_tree().paused = false
