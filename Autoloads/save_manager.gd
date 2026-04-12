extends Node

# Root Node: Node
# Path: /Autoloads/save_manager.gd

const SAVE_PATH = "user://neobushi_save.cfg"

func _ready() -> void:
	# Automatically attempt to load previous data when the game starts
	load_game()

func save_game() -> void:
	var config = ConfigFile.new()
	
	# 1. Save the global currency balance
	config.set_value("Progression", "total_meta_xp", ProgressionManager.total_meta_xp)
	
	# 2. Save the permanent mech stat levels
	config.set_value("Upgrades", "mech_stats", ProgressionManager.meta_upgrade_levels)
	
	# Write the file to the user's local application data (user://)
	var error = config.save(SAVE_PATH)
	if error != OK:
		print("SAVE SYSTEM: Error saving to ", SAVE_PATH)
	else:
		print("SAVE SYSTEM: Successfully saved all Meta progress.")

func load_game() -> void:
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)
	
	# If no save file exists (e.g., first-time boot), we stop here
	if error != OK:
		print("SAVE SYSTEM: No save found. Starting fresh.")
		return
		
	# 1. Load the banked XP
	ProgressionManager.total_meta_xp = config.get_value("Progression", "total_meta_xp", 0)
	
	# 2. Load the mech stat levels (defaults to empty dictionary if not found)
	ProgressionManager.meta_upgrade_levels = config.get_value("Upgrades", "mech_stats", {})
	
	print("SAVE SYSTEM: Data loaded successfully.")
