extends CanvasLayer

# Root Node: CanvasLayer
# Path: /UI/hangar.gd

# 1. Drag your kineticmech.tres into this list in the Inspector
@export var available_mechs: Array[PlayerResource] = []
# NEW: Tell the Hangar what UI row to spawn
@export var stat_row_scene: PackedScene 

# Use Unique Names (%) to prevent "null instance" errors if nodes move
@onready var bank_display = %BankDisplay
@onready var selection_page = %SelectionPage
@onready var upgrade_page = %UpgradePage
@onready var mech_list = %MechList
@onready var mech_title = %MechTitle
@onready var stat_list = %StatList 
@onready var reset_button = %ResetButton # Reference to our new button

var selected_mech: PlayerResource = null

func _ready() -> void:
	# Update the Meta XP display
	update_bank_ui()
	
	# Clear placeholder buttons
	for child in mech_list.get_children():
		child.queue_free()
		
	create_mech_buttons()
	
	# Connect the Reset Button signal
	reset_button.pressed.connect(_on_reset_button_pressed)
	
	# Initial visibility
	selection_page.show()
	upgrade_page.hide()

func update_bank_ui() -> void:
	# Reference the global balance from your ProgressionManager
	bank_display.text = "META XP: " + str(ProgressionManager.total_meta_xp)

func create_mech_buttons() -> void:
	for mech_data in available_mechs:
		if not mech_data: continue
		
		var btn = Button.new()
		btn.text = mech_data.character_name
		btn.custom_minimum_size = Vector2(200, 100)
		btn.pressed.connect(_on_mech_selected.bind(mech_data))
		mech_list.add_child(btn)

func _on_mech_selected(mech_data: PlayerResource) -> void:
	selected_mech = mech_data
	
	# If this line previously errored, Unique Names will fix it
	mech_title.text = mech_data.character_name
	
	# Ensure this mech has a save profile in our dictionary
	var m_name = selected_mech.character_name
	if not ProgressionManager.meta_upgrade_levels.has(m_name):
		ProgressionManager.meta_upgrade_levels[m_name] = {}
		
	# Populate the upgrade list for this specific mech
	populate_upgrades()
	
	selection_page.hide()
	upgrade_page.show()

# --- THE UPGRADE SPAWNER ---
func populate_upgrades() -> void:
	# 1. Clear any old rows
	for child in stat_list.get_children():
		child.queue_free()
		
	var m_name = selected_mech.character_name
	var mech_profile = ProgressionManager.meta_upgrade_levels[m_name]
	
	# 2. Loop through the Master Dictionary in the ProgressionManager
	for stat_name in ProgressionManager.META_UPGRADES.keys():
		var max_lvl = ProgressionManager.META_UPGRADES[stat_name]["max_level"]
		
		# Get current level (default to 0 if they haven't upgraded it yet)
		var current_lvl = mech_profile.get(stat_name, 0)
		
		# Get the cost based on the compounding formula
		var cost = ProgressionManager.get_upgrade_cost(stat_name, current_lvl)
		
		# 3. Spawn the row and set it up
		var row = stat_row_scene.instantiate()
		stat_list.add_child(row)
		
		row.init_row(stat_name, current_lvl, max_lvl, cost, ProgressionManager.total_meta_xp)
		
		# 4. Listen for when the player clicks "Purchase"
		row.purchase_requested.connect(_on_purchase_requested)

# --- THE PURCHASE LOGIC ---
func _on_purchase_requested(stat_name: String, cost: int) -> void:
	if ProgressionManager.total_meta_xp >= cost:
		# 1. Deduct the XP
		ProgressionManager.total_meta_xp -= cost
		
		# 2. Increase the stat level
		var m_name = selected_mech.character_name
		var current_lvl = ProgressionManager.meta_upgrade_levels[m_name].get(stat_name, 0)
		ProgressionManager.meta_upgrade_levels[m_name][stat_name] = current_lvl + 1
		
		# 3. Save the game immediately so progress isn't lost
		if get_tree().root.has_node("SaveManager"):
			get_tree().root.get_node("SaveManager").save_game()
			
		# 4. Refresh the UI to show the new bank balance and next level costs
		update_bank_ui()
		populate_upgrades()
	else:
		print("Hangar: Not enough XP!")

# --- NEW: THE RESET LOGIC ---
func _on_reset_button_pressed() -> void:
	if selected_mech:
		# Call the targeted reset we built in ProgressionManager
		ProgressionManager.reset_mech_upgrades(selected_mech.character_name)
		
		# Refresh the UI labels and purchase rows
		update_bank_ui()
		populate_upgrades()
		print("Hangar: Upgrades reset for ", selected_mech.character_name)

func _on_back_button_pressed() -> void:
	selected_mech = null
	upgrade_page.hide()
	selection_page.show()

func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")
