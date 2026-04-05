extends Node2D

@export var enemy_scene: PackedScene
@export var enemy_data: EnemyResource
@export var spawn_rate: float = 2.0 # Base seconds between spawns

@export_group("Spawn Ranges")
@export var min_distance: float = 700.0  # Just outside a standard 1080p view
@export var max_distance: float = 1000.0

@onready var timer = $Timer

# Tracks the multiplier sent by the MoonDirector
var current_intensity: float = 1.0

func _ready() -> void:
	# 1. Listen for intensity changes from the Director
	GameEvents.request_spawn_intensity.connect(_on_intensity_requested)
	
	# 2. Set the initial timer speed
	update_timer_speed()
	timer.start()

func _on_intensity_requested(intensity: float) -> void:
	current_intensity = intensity
	update_timer_speed()

func update_timer_speed() -> void:
	# MATH: Base Rate / Intensity = New Wait Time.
	# At 1.0 intensity: 2.0s / 1.0 = 2.0s per spawn.
	# At 2.0 intensity: 2.0s / 2.0 = 1.0s per spawn (Twice as fast).
	# Every minute, as intensity grows, this number gets smaller.
	timer.wait_time = max(0.1, spawn_rate / current_intensity)

func _on_timer_timeout() -> void:
	spawn_enemy()

func spawn_enemy() -> void:
	if not enemy_scene or not enemy_data:
		return
	
	# Calculate a random position in a "Donut" shape around this Node
	var spawn_pos = get_random_spawn_position()
	
	# Instantiate and place the enemy
	var enemy_instance = enemy_scene.instantiate()
	enemy_instance.data = enemy_data
	
	# Add to scene root so enemies don't move with the player's parent node
	get_tree().current_scene.add_child(enemy_instance)
	enemy_instance.global_position = spawn_pos

func get_random_spawn_position() -> Vector2:
	# Pick a random angle (0 to 360 degrees)
	var angle = randf() * 2 * PI
	# Pick a random distance between our min and max
	var distance = randf_range(min_distance, max_distance)
	
	# Convert polar coordinates to a 2D vector offset
	var direction = Vector2(cos(angle), sin(angle))
	var offset = direction * distance
	
	# Add the offset to the current spawner position (Player center)
	return global_position + offset
