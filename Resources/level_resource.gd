extends Resource
class_name LevelResource

@export_group("Level Info")
@export var level_name: String = "New Level"
@export var camera_zoom: Vector2 = Vector2(0.5, 0.5)
@export var time_limit_minutes: float = 15.0 

@export_group("Intro Splash")
## The text that appears on the intro splash screen (e.g., "THIN OUT THE ENEMY FORCES")
@export var intro_objective_title: String = "OBJECTIVE TITLE"

@export_group("Spawning Parameters")
## Seconds between spawns at the start of the mission (at 1.0 intensity)
@export var base_spawn_interval: float = 2.0
## Minimum distance from the player to spawn enemies
@export var spawn_min_distance: float = 700.0
## Maximum distance from the player to spawn enemies
@export var spawn_max_distance: float = 1000.0

@export_group("Level Layout")
@export var map_scene: PackedScene
## The specific mission director (brain) for this level
@export var director_scene: PackedScene
