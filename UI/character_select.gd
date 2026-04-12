extends CanvasLayer

# Root Node: CanvasLayer
# Path: /UI/character_select.gd

# 1. Drag your kineticmech.tres (and others) into this list in the Inspector
@export var available_mechs: Array[PlayerResource] = []

@onready var mech_title = %MechTitle
@onready var mech_visual = %MechVisual
@onready var stat_list = %StatList
@onready var prev_button = %PrevButton
@onready var next_button = %NextButton
@onready var start_button = %StartButton

var current_index: int = 0

func _ready() -> void:
	# Initial UI update
	update_selection()

func update_selection() -> void:
	if available_mechs.is_empty():
		print("Character Select: No mechs found in the available_mechs array!")
		return
		
	var mech = available_mechs[current_index]
	
	# Update Visuals
	mech_title.text = mech.character_name
	
	# Assign SpriteFrames and play the correct "default" animation
	if mech.sprite_frames:
		mech_visual.sprite_frames = mech.sprite_frames
		if mech_visual.sprite_frames.has_animation("default"):
			mech_visual.play("default") 
	
	# Update Upgraded Stats
	display_upgraded_stats(mech)

func display_upgraded_stats(mech: PlayerResource) -> void:
	# 1. Clear placeholder labels
	for child in stat_list.get_children():
		child.queue_free()
		
	# 2. Loop through ALL stats defined in your ProgressionManager
	for stat_name in ProgressionManager.META_UPGRADES.keys():
		var base_val = 0.0
		
		# Map known base stats from the PlayerResource
		if stat_name == "Max Health": 
			base_val = mech.max_health
		elif stat_name == "Move Speed": 
			base_val = mech.movement_speed
		# All other stats (Armor, Magnet, etc.) will start at a base of 0.0
		
		# Calculate final stat including Meta-Progression
		var bonus = ProgressionManager.get_stat_bonus(stat_name, mech.character_name)
		var final_val = base_val + bonus
		
		# 3. Create and add a new label for the stat
		var label = Label.new()
		label.text = stat_name + ": " + str(final_val)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat_list.add_child(label)

# --- EDITOR CONNECTED SIGNALS ---

func _on_prev_button_pressed() -> void:
	current_index = (current_index - 1 + available_mechs.size()) % available_mechs.size()
	update_selection()

func _on_next_button_pressed() -> void:
	current_index = (current_index + 1) % available_mechs.size()
	update_selection()

func _on_start_button_pressed() -> void:
	# Transition to the world
	get_tree().change_scene_to_file("res://Levels/world.tscn")
