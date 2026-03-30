extends Node2D

@export var data: WeaponResource
var current_level: int = 1

@onready var cooldown_timer = $Timer

func _ready() -> void:
	if data:
		start_weapon()

func start_weapon() -> void:
	# Fetch the cooldown for the current level from our Resource
	var cd = data.get_stat("cooldown", current_level)
	cooldown_timer.wait_time = cd
	cooldown_timer.start()

func _on_timer_timeout() -> void:
	fire()
	# Update cooldown in case the weapon leveled up
	var cd = data.get_stat("cooldown", current_level)
	cooldown_timer.wait_time = cd

func fire() -> void:
	# 1. Package the stats from our Resource into a Dictionary for the projectile
	var stats = {
		"damage": data.get_stat("damage", current_level),
		"speed": data.get_stat("speed", current_level),
		"pierce": data.get_stat("pierce", current_level),
		"bounce": data.get_stat("bounce", current_level)
	}
	
	# 2. Check how many projectiles we should fire
	var count = int(data.get_stat("projectiles", current_level))
	
	for i in range(count):
		spawn_projectile(stats)

func spawn_projectile(stats: Dictionary) -> void:
	# 3. Create the bullet from the scene saved in our Resource
	if not data.projectile_scene:
		return
		
	var bullet = data.projectile_scene.instantiate()
	
	# 4. Add bullet to the main scene (not as a child of the player)
	get_tree().root.add_child(bullet)
	
	# 5. Position and aim
	bullet.global_position = global_position
	var fire_direction = Vector2.RIGHT.rotated(global_rotation)
	
	# 6. Push the data into the bullet
	bullet.setup(stats, fire_direction)
