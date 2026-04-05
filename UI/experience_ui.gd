extends Control

# Grab the nodes we just spent all that time making look good
@onready var progress_bar = $XPProgressBar
@onready var level_label = $LevelLabel

func _ready() -> void:
	# 1. Connect to the global brain of the game
	GameEvents.xp_gained.connect(_on_xp_gained)
	GameEvents.level_up.connect(_on_level_up)
	
	# 2. Set the starting visual state
	level_label.text = "1"
	progress_bar.value = 0

func _on_xp_gained(current_xp: float, next_level_xp: float) -> void:
	# 3. Calculate the percentage for the progress bar (0 to 100)
	var target_value = (current_xp / next_level_xp) * 100.0
	
	# 4. Use a 'Tween' to make the yellow pie slice fill up smoothly instead of instantly snapping
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", target_value, 0.25).set_trans(Tween.TRANS_SINE)

func _on_level_up(new_level: int) -> void:
	# 5. Update the number in the middle
	level_label.text = str(new_level)
	
	# 6. Empty the yellow pie slice for the new level
	progress_bar.value = 0
