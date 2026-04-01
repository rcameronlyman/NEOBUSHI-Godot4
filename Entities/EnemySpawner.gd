extends Node2D

@export var enemy_scene: PackedScene
@export var enemy_data: EnemyResource
@export var spawn_rate: float = 2.0

@export_group("Spawn Ranges")
@export var min_distance: float = 700.0  # Just outside a standard 1080p view
@export var max_distance: float = 1000.0

@onready var timer = $Timer

func _ready() -> void:
	timer.wait_time = spawn_rate
	timer.start()

func _on_timer_timeout() -> void:
	spawn_enemy()

func spawn_enemy() -> void:
	if not enemy_scene or not enemy_data:
		return
	
	# 1. Calculate a random position in a "Donut" shape around the player
	var spawn_pos = get_random_spawn_position()
	
	# 2. Instantiate and place the enemy
	var enemy_instance = enemy_scene.instantiate()
	enemy_instance.data = enemy_data
	
	# We use get_parent().add_child() so enemies aren't "stuck" to the player's movement
	get_tree().current_scene.add_child(enemy_instance)
	enemy_instance.global_position = spawn_pos

func get_random_spawn_position() -> Vector2:
	# Pick a random angle (0 to 360 degrees)
	var angle = randf() * 2 * PI
	# Pick a random distance between our min and max
	var distance = randf_range(min_distance, max_distance)
	
	# Convert polar coordinates (angle/distance) to a 2D vector
	var direction = Vector2(cos(angle), sin(angle))
	var offset = direction * distance
	
	# Add the offset to the current player position
	return global_position + offset
