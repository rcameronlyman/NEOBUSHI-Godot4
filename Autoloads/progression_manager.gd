extends Node

# Drag all your upgrade_XXX.tres files into this list in the Inspector
@export var all_upgrades: Array[UpgradeResource] = []

# Assign your starting weapon upgrade here (e.g., upgrade_minigun.tres)
@export var starting_weapon: UpgradeResource

# Storage for the items the player has already collected
var current_weapons: Array[UpgradeResource] = []
var current_passives: Array[UpgradeResource] = []

# NEW: Track the integer level of each weapon
var weapon_levels: Dictionary = {}

func _ready() -> void:
	# 1. Initialize the inventory with the starting weapon if assigned
	if starting_weapon:
		current_weapons.append(starting_weapon)
		weapon_levels[starting_weapon.upgrade_id] = 1 # Starting weapon is Level 1
		
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
	if all_upgrades.is_empty():
		return []
		
	var potential_upgrades: Array[UpgradeResource] = []
	
	# NEW: Filter the upgrade pool to remove maxed out weapons
	for upgrade in all_upgrades:
		if upgrade.is_weapon:
			var current_lvl = weapon_levels.get(upgrade.upgrade_id, 0)
			
			# Max Level = 1 (Base Stats) + Number of upgrades defined in the Tres file array
			var max_lvl = 1 + upgrade.weapon_data.levels.size()
			
			# Only add it to the pool if we haven't reached the max level
			if current_lvl < max_lvl:
				potential_upgrades.append(upgrade)
		else:
			# Passives don't have level caps yet, so always add them
			potential_upgrades.append(upgrade)
			
	# Shuffle and pick the exact amount needed
	potential_upgrades.shuffle()
	
	var selected: Array[UpgradeResource] = []
	var actual_count = min(count, potential_upgrades.size()) 
	
	for i in range(actual_count):
		selected.append(potential_upgrades[i])
		
	return selected

func add_upgrade(upgrade: UpgradeResource) -> void:
	if upgrade.is_weapon:
		var already_owned = false
		for owned in current_weapons:
			if owned.upgrade_id == upgrade.upgrade_id:
				already_owned = true
				break
		
		if not already_owned:
			current_weapons.append(upgrade)
			weapon_levels[upgrade.upgrade_id] = 1 # First time picking it up sets it to Level 1
		else:
			weapon_levels[upgrade.upgrade_id] += 1 # Level it up!
	else:
		var already_owned = false
		for owned in current_passives:
			if owned.upgrade_id == upgrade.upgrade_id:
				already_owned = true
				break
		
		if not already_owned:
			current_passives.append(upgrade)
	
	GameEvents.update_inventory_ui.emit(current_weapons, current_passives)
	
	if GameEvents.has_signal("upgrade_applied"):
		GameEvents.upgrade_applied.emit(upgrade)
	
	# --- THE FIX ---
	# 1. Force the viewport to drop whatever UI element it is holding onto
	get_viewport().gui_release_focus()
	
	# 2. Use set_deferred to unpause safely at the very end of the current frame
	get_tree().set_deferred("paused", false)
