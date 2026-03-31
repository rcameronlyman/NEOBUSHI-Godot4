extends Node2D

# 1. Drag your moon_level.tres into this slot in the Inspector
@export var current_level: LevelResource

@onready var level_container: Node2D = $LevelContainer
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	load_level()

func load_level() -> void:
	if current_level and current_level.map_scene:
		# Create an instance of the map from your Resource
		var map_instance = current_level.map_scene.instantiate()
		
		# Put it in the container so it stays in the background
		level_container.add_child(map_instance)
		
		# Apply the zoom value defined in the level resource to the player's camera
		if player and player.has_node("Camera2D"):
			player.get_node("Camera2D").zoom = current_level.camera_zoom
			
		print("Successfully loaded: ", current_level.level_name)
	else:
		push_warning("No level resource assigned to the World!")
