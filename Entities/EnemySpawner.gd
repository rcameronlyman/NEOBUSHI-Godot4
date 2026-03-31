extends Node2D

@export var enemy_scene: PackedScene
@export var enemy_data: EnemyResource
@export var spawn_rate: float = 2.0

@onready var timer = $Timer

func _ready() -> void:
	print("1. Spawner _ready fired.")
	timer.wait_time = spawn_rate
	timer.start()

func _on_timer_timeout() -> void:
	print("2. Timer timeout fired.")
	spawn_enemy()

func spawn_enemy() -> void:
	if not enemy_scene or not enemy_data:
		print("3. FAILED: Scene or Data is missing!")
		return
	
	var enemy_instance = enemy_scene.instantiate()
	enemy_instance.data = enemy_data
	enemy_instance.global_position = global_position
	get_parent().add_child(enemy_instance)
	print("3. SUCCESS: Enemy spawned at ", global_position)
