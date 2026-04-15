extends Node2D

# Root Node: Node2D
# Path: /Entities/EnemySpawner.gd

@export var enemy_scene: PackedScene
@export var enemy_data: EnemyResource

## Base settings (will be overwritten by LevelResource if mission_started is received)
@export var spawn_interval: float = 2.0 

@export_group("Spawn Ranges")
@export var min_distance: float = 700.0  
@export var max_distance: float = 1000.0

@onready var timer = $Timer

# Tracks the multiplier sent by the MoonDirector
var current_intensity: float = 1.0

func _ready() -> void:
	# Ensure the random number generator is properly seeded
	randomize()
	
	# 1. Listen for the mission setup to get data-driven values [cite: 13, 2026-03-30]
	GameEvents.mission_started.connect(_on_mission_started)
	
	# 2. Listen for intensity changes from the Director [cite: 1, 2026-03-30]
	GameEvents.request_spawn_intensity.connect(_on_intensity_requested)
	
	# Set the initial timer speed and start
	update_timer_speed()
	timer.start()

func _on_mission_started(level_resource: LevelResource) -> void:
	# 3. Apply level-specific data from the resource [cite: 13, 2026-03-30]
	spawn_interval = level_resource.base_spawn_interval
	min_distance = level_resource.spawn_min_distance
	max_distance = level_resource.spawn_max_distance
	
	# Recalculate timer immediately with the new base interval
	update_timer_speed()
	print("SPAWNER: Data received for ", level_resource.level_name)

func _on_intensity_requested(intensity: float) -> void:
	# Update internal tracker and recalculate the clock speed [cite: 1]
	current_intensity = intensity
	update_timer_speed()

func update_timer_speed() -> void:
	# MATH: Base Interval / Intensity = New Wait Time. [cite: 1]
	# (e.g. 2.0s interval / 2.0 intensity = 1.0s wait time)
	timer.wait_time = max(0.1, spawn_interval / current_intensity)

func _on_timer_timeout() -> void:
	spawn_enemy()

func spawn_enemy() -> void:
	if not enemy_scene or not enemy_data:
		return
	
	# Calculate a random position in a "Donut" shape around the player
	var spawn_pos = get_random_spawn_position()
	
	# Instantiate and place the enemy
	var enemy_instance = enemy_scene.instantiate()
	enemy_instance.data = enemy_data
	
	# Add to scene root so enemies don't move with the player's parent node
	get_tree().current_scene.add_child(enemy_instance)
	enemy_instance.global_position = spawn_pos

func get_random_spawn_position() -> Vector2:
	# Pick a random angle (0 to 360 degrees) using TAU for a perfect circle
	var angle = randf() * TAU
	
	# Pick a random distance between our min and max
	var distance = randf_range(min_distance, max_distance)
	
	# Use Vector2.from_angle for robust directional vector creation
	var direction = Vector2.from_angle(angle)
	var offset = direction * distance
	
	# Add the offset to the current spawner position (Player center)
	return global_position + offset
