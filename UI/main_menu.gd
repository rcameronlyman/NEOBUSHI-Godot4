extends Control

# Root Node: Control
# Path: /UI/main_menu.gd

func _on_new_game_button_pressed() -> void:
	# Transition to Character Select per the Master Doc flow
	get_tree().change_scene_to_file("res://UI/character_select.tscn")

func _on_continue_button_pressed() -> void:
	# Placeholder for loading existing save data
	print("Continue pressed.")

func _on_hangar_button_pressed() -> void:
	# Transition to the Hangar Meta-Progression menu
	get_tree().change_scene_to_file("res://UI/hangar.tscn")

func _on_options_button_pressed() -> void:
	print("Options pressed.")

func _on_unlocks_button_pressed() -> void:
	print("Unlocks pressed.")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
