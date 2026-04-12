extends Node

# Root Node: Node
# Path: /Autoloads/progression_manager.gd

# Drag all your upgrade_XXX.tres files into this list in the Inspector
@export var all_upgrades: Array[UpgradeResource] = []

# Assign your starting weapon upgrade here (e.g., upgrade_minigun.tres)
@export var starting_weapon: UpgradeResource

# --- META PROGRESSION BANKING ---
var total_meta_xp: int = 0    # Permanent global bank balance 
var pending_meta_xp: int = 0  # XP earned in current run (at risk) 

# --- PERMANENT MECH UPGRADES ---
# Structure: { "Mech Name": { "stat_id": level_int } }
# Example: { "Kinetic Mech": { "Max Health": 2, "Move Speed": 1 } }
var meta_upgrade_levels: Dictionary = {}

# --- MASTER META UPGRADE DICTIONARY ---
# Defines the rules for every permanent upgrade in the game. 
# Added "bonus" values to define numerical impact per level.
const META_UPGRADES = {
	"Max Health": { "max_level": 5, "base_cost": 50, "cost_multiplier": 1.5, "bonus": 25.0 },
	"Move Speed": { "max_level": 3, "base_cost": 100, "cost_multiplier": 2.0, "bonus": 50.0 },
	"Armor Plating": { "max_level": 3, "base_cost": 100, "cost_multiplier": 2.0, "bonus": 5.0 },
	"Greased Bearings": { "max_level": 3, "base_cost": 75, "cost_multiplier": 1.5, "bonus": 10.0 },
	"Nano Bots": { "max_level": 3, "base_cost": 150, "cost_multiplier": 2.0, "bonus": 2.0 },
	"Range": { "max_level": 3, "base_cost": 100, "cost_multiplier": 1.8, "bonus": 100.0 },
	"Magnet": { "max_level": 3, "base_cost": 50, "cost_multiplier": 1.5, "bonus": 50.0 },
	"Neural Overclock": { "max_level": 3, "base_cost": 200, "cost_multiplier": 2.5, "bonus": 0.1 },
	"Pilot Mode": { "max_level": 3, "base_cost": 500, "cost_multiplier": 3.0, "bonus": 1.0 },
	"Reroll": { "max_level": 3, "base_cost": 150, "cost_multiplier": 2.0, "bonus": 1.0 },
	"Blacklist": { "max_level": 3, "base_cost": 150, "cost_multiplier": 2.0, "bonus": 1.0 }
}

# Storage for the items the player has already collected
var current_weapons: Array[UpgradeResource] = []
var current_passives: Array[UpgradeResource] = []

# Track the integer level of each weapon
var weapon_levels: Dictionary = {}

func _ready() -> void:
	# 1. Initialize the inventory with the starting weapon if assigned
	if starting_weapon:
		current_weapons.append(starting_weapon)
		weapon_levels[starting_weapon.upgrade_id] = 1 # Starting weapon is Level 1
		
	# 2. Connect to the level_up signal from GameEvents
	GameEvents.level_up.connect(_on_level_up)
	
	# 3. NEW: Listen for the player's death to secure the pending XP!
	if GameEvents.has_signal("player_died"):
		GameEvents.player_died.connect(commit_pending_xp)

# --- BANKING LOGIC ---

func add_pending_xp(amount: int) -> void:
	# Called every time an XP gem is collected 
	pending_meta_xp += amount

func commit_pending_xp() -> void:
	# 1. Move pending XP into the permanent bank
	total_meta_xp += pending_meta_xp
	print("META BANK: Committed ", pending_meta_xp, " XP. New Total Balance: ", total_meta_xp)
	pending_meta_xp = 0
	
	# 2. LINKING THE SAVE SYSTEM: Trigger the permanent save to disk 
	if get_tree().root.has_node("SaveManager"):
		get_tree().root.get_node("SaveManager").save_game()

func clear_pending_xp() -> void:
	# Called on "Retry" or "Quit" to forfeit current progress 
	print("META BANK: Forfeited ", pending_meta_xp, " XP.")
	pending_meta_xp = 0

# --- META UPGRADE LOGIC ---

# Helper function to calculate current cost based on level
func get_upgrade_cost(stat_name: String, current_level: int) -> int:
	if not META_UPGRADES.has(stat_name):
		return 999999 # Failsafe
		
	var base = META_UPGRADES[stat_name]["base_cost"]
	var multi = META_UPGRADES[stat_name]["cost_multiplier"]
	
	# Compounding cost formula (e.g., Level 0 = base, Level 1 = base * multi)
	return int(base * pow(multi, current_level))

# Calculates the total bonus for a specific stat based on Mech and meta-level
func get_stat_bonus(stat_name: String, mech_name: String) -> float:
	if not meta_upgrade_levels.has(mech_name):
		return 0.0
	
	var levels_dict = meta_upgrade_levels[mech_name]
	var current_lvl = levels_dict.get(stat_name, 0)
	
	if META_UPGRADES.has(stat_name):
		return current_lvl * META_UPGRADES[stat_name]["bonus"]
	return 0.0

# NEW: Refunds Meta XP for a specific mech and clears its stat levels. 
func reset_mech_upgrades(mech_name: String) -> void:
	if not meta_upgrade_levels.has(mech_name):
		return
		
	var total_refund: int = 0
	var upgrades = meta_upgrade_levels[mech_name]
	
	# Calculate total spent on this specific mech
	for stat_name in upgrades:
		var lvl = upgrades[stat_name]
		for i in range(lvl):
			total_refund += get_upgrade_cost(stat_name, i)
	
	# Refund the bank and clear the specific mech's levels
	total_meta_xp += total_refund
	meta_upgrade_levels[mech_name] = {}
	
	print("META BANK: Reset ", mech_name, ". Refunded: ", total_refund, " XP.")
	
	if get_tree().root.has_node("SaveManager"):
		get_tree().root.get_node("SaveManager").save_game()

# --- IN-RUN PROGRESSION LOGIC ---

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
	
	# Filter the upgrade pool to remove maxed out weapons
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
