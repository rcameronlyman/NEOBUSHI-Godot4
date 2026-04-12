extends CanvasLayer

# Root Node: CanvasLayer
# Path: /UI/game_over_ui.gd

func _ready() -> void:
	# Hide the menu immediately on load
	hide()
	
	# Connect to the global death signal to trigger this menu
	GameEvents.player_died.connect(_on_player_died)

func _on_player_died() -> void:
	# Show the UI and pause the game engine
	show()
	get_tree().paused = true

func _on_retry_button_pressed() -> void:
	# Forfeit pending XP when retrying after a death
	ProgressionManager.clear_pending_xp()
	
	# Unpause before reloading or the new scene will start frozen
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	# Forfeit pending XP when quitting back to the main menu after a death
	ProgressionManager.clear_pending_xp()
	
	# Reset pause state and return to the main menu scene
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")
