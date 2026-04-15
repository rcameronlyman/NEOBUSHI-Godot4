extends Node2D

# 1. Drag your moon_level.tres into this slot in the Inspector
@export var current_level: LevelResource

@onready var level_container: Node2D = $LevelContainer
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	load_level()

func load_level() -> void:
	if current_level:
		# --- EXISTING MAP LOGIC ---
		if current_level.map_scene:
			var map_instance = current_level.map_scene.instantiate()
			level_container.add_child(map_instance)
			
			if player and player.has_node("Camera2D"):
				player.get_node("Camera2D").zoom = current_level.camera_zoom
		
		# --- EXISTING MODULAR DIRECTOR LOGIC ---
		if current_level.director_scene:
			var director = current_level.director_scene.instantiate()
			$DirectorContainer.add_child(director)
			
			# Pass the resource data to the director brain
			if "level_data" in director:
				director.level_data = current_level
		
		# --- NEW: BROADCAST MISSION DATA ---
		# This signal tells nodes like the EnemySpawner to configure themselves
		GameEvents.mission_started.emit(current_level)
				
		print("Successfully loaded: ", current_level.level_name)
	else:
		push_warning("No level resource assigned to the World!")
