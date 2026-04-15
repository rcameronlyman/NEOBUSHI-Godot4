extends CanvasLayer

# Root Node: CanvasLayer
# Path: /UI/game_over_ui.gd

# Flag to track if the run ended via survival (Victory) or destruction (Death)
var is_victory: bool = false

func _ready() -> void:
	# Hide the menu immediately on load
	hide()
	
	# Connect to the global death signal to trigger this menu
	GameEvents.player_died.connect(_on_player_died)
	
	# NEW: Connect to the mission success signal
	if GameEvents.has_signal("time_limit_reached"):
		GameEvents.time_limit_reached.connect(_on_time_limit_reached)

func _on_time_limit_reached() -> void:
	# Set flag so retry/quit buttons know to keep the XP
	is_victory = true
	# Note: ProgressionManager will trigger the player_died signal immediately after this

func _on_player_died() -> void:
	# Show the UI and pause the game engine
	show()
	get_tree().paused = true
	
	# OPTIONAL: You can update a Title Label here to say "MISSION COMPLETE" if is_victory is true

func _on_retry_button_pressed() -> void:
	# Only forfeit pending XP if the player actually died
	if not is_victory:
		ProgressionManager.clear_pending_xp()
	
	# Unpause before reloading or the new scene will start frozen
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	# Only forfeit pending XP if the player actually died
	if not is_victory:
		ProgressionManager.clear_pending_xp()
	
	# Reset pause state and return to the main menu scene
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")
