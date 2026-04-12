extends CanvasLayer

# Root Node: CanvasLayer
# Path: /UI/pause_menu.gd

func _ready() -> void:
	hide()

func _input(event: InputEvent) -> void:
	# "ui_cancel" is the default Godot action for the ESC key
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	var new_pause_state = !get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state

func _on_resume_button_pressed() -> void:
	toggle_pause()

func _on_retry_button_pressed() -> void:
	# Forfeit pending XP on Retry
	ProgressionManager.clear_pending_xp()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_options_button_pressed() -> void:
	print("Options menu not yet implemented.")

func _on_end_run_button_pressed() -> void:
	# Commit pending XP to the global bank on End Run
	ProgressionManager.commit_pending_xp()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")

func _on_quit_button_pressed() -> void:
	# Forfeit pending XP if the player quits the application entirely
	ProgressionManager.clear_pending_xp()
	get_tree().quit()
