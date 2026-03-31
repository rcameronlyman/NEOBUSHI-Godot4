extends Resource
class_name LevelResource

@export_group("Level Info")
@export var level_name: String = "New Level"
@export var camera_zoom: Vector2 = Vector2(0.5, 0.5) 

@export_group("Level Layout")
# This will hold the physical scene with the ground and navigation map
@export var map_scene: PackedScene
