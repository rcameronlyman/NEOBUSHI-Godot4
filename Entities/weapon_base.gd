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
	# 1. Find the target first!
	var target = get_closest_target()
	
	# If there are no enemies in the circle, don't shoot
	if not target:
		return

	# 2. Package the stats from our Resource into a Dictionary for the projectile
	var stats = {
		"damage": data.get_stat("damage", current_level),
		"speed": data.get_stat("speed", current_level),
		"pierce": data.get_stat("pierce", current_level),
		"bounce": data.get_stat("bounce", current_level)
	}
	
	# 3. Check how many projectiles we should fire
	var count = int(data.get_stat("projectiles", current_level))
	
	for i in range(count):
		# Pass the target into the spawn function
		spawn_projectile(stats, target)

func spawn_projectile(stats: Dictionary, target: Node2D) -> void:
	# 4. Create the bullet from the scene saved in our Resource
	if not data.projectile_scene:
		return
		
	var bullet = data.projectile_scene.instantiate()
	
	# 5. Add bullet to the main scene (not as a child of the player)
	get_tree().root.add_child(bullet)
	
	# 6. Position and aim
	bullet.global_position = global_position
	
	# Calculate the exact direction from the weapon to the targeted enemy
	var fire_direction = global_position.direction_to(target.global_position)
	
	# 7. Push the data into the bullet
	bullet.setup(stats, fire_direction)

func get_closest_target() -> Node2D:
	# Get all physics bodies currently inside our TargetingArea
	var bodies = $TargetingArea.get_overlapping_bodies()
	
	var closest_target: Node2D = null
	var closest_distance: float = INF
	
	for body in bodies:
		# We identify enemies using the same method your projectiles use
		if body.has_method("take_damage"):
			# distance_squared_to is faster for the computer to calculate than distance_to
			var distance = global_position.distance_squared_to(body.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_target = body
				
	return closest_target
