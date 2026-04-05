extends Node2D

@export var data: WeaponResource

# --- TACTICAL TARGETING RANGES ---
@export var track_range: float = 800.0 # How far the gun looks for targets
@export var fire_range: float = 400.0  # How close they must be to shoot
@export var danger_zone: float = 150.0 # Enemies this close override everything else

var current_level: int = 1
var current_ammo: int = 0
var is_reloading: bool = false
var current_target: Node2D = null

@onready var cooldown_timer = $Timer
@onready var muzzle = $Muzzle
@onready var muzzle_flash = $Muzzle/MuzzleFlash

func _ready() -> void:
	if data:
		current_ammo = int(data.get_stat("clip_size", current_level))
		start_weapon()
	
	if muzzle_flash:
		muzzle_flash.hide()

func _physics_process(delta: float) -> void:
	var player_facing_dir = get_player_facing_dir()
	current_target = get_best_target(player_facing_dir)
	
	# Default to looking where the player is looking
	var target_angle = player_facing_dir.angle()
	
	if current_target:
		var target_vec = current_target.global_position - global_position
		target_angle = target_vec.angle()
	
	# --- BODY CLIPPING & HIGH ROAD LOGIC ---
	var wrapped_target = wrapf(target_angle, -PI, PI)
	
	# If facing Right, the "body" is between 90 (PI/2) and 180 (PI) degrees
	if player_facing_dir.x > 0 and wrapped_target > PI / 2:
		target_angle = -PI # Force it over the shoulder
	# If facing Left, the "body" is between 0 and 90 (PI/2) degrees
	elif player_facing_dir.x < 0 and wrapped_target > 0 and wrapped_target < PI / 2:
		target_angle = 0.0 # Force it over the shoulder

	# Smooth rotation
	var rot_speed = data.get_stat("rotation_speed", current_level)
	if rot_speed <= 0.0: rot_speed = 8.0 # Fallback so it doesn't freeze if data is missing
	
	rotation = lerp_angle(rotation, target_angle, rot_speed * delta)
	
	# --- UPRIGHT SPRITE LOGIC ---
	# If the gun is pointing generally left, flip the Y axis so the art isn't upside down
	if abs(wrapf(rotation, -PI, PI)) > PI / 2:
		scale.y = -1
	else:
		scale.y = 1

# --- THE NEW TACTICAL BRAIN ---
func get_best_target(player_dir: Vector2) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var best_target: Node2D = null
	
	var min_danger_dist = INF
	var best_path_score = -INF
	
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		
		# Ignore enemies outside the tracking range completely
		if dist > track_range:
			continue
			
		# 1. Self Defense: The Danger Zone Override
		if dist <= danger_zone:
			if dist < min_danger_dist:
				min_danger_dist = dist
				best_target = enemy
		
		# 2. Path Clearing: Only evaluate if there are no immediate threats
		elif min_danger_dist == INF:
			var dir_to_enemy = global_position.direction_to(enemy.global_position)
			
			# Dot Product gives a score from 1.0 (exact front) to -1.0 (exact back)
			var alignment = player_dir.dot(dir_to_enemy) 
			
			# Score combines alignment (highest priority) and distance
			var score = (alignment * 1000.0) - dist 
			
			if score > best_path_score:
				best_path_score = score
				best_target = enemy
				
	return best_target

# Helper function to get the player's movement/facing direction
func get_player_facing_dir() -> Vector2:
	if owner and "velocity" in owner and owner.velocity != Vector2.ZERO:
		return owner.velocity.normalized()
	elif owner and owner.has_node("AnimatedSprite2D"):
		return Vector2.LEFT if owner.get_node("AnimatedSprite2D").flip_h else Vector2.RIGHT
	return Vector2.RIGHT

# --- FIRING LOGIC ---
func start_weapon() -> void:
	var cd = data.get_stat("cooldown", current_level)
	cooldown_timer.wait_time = cd
	cooldown_timer.start()

func _on_timer_timeout() -> void:
	if is_reloading:
		finish_reload()
	else:
		fire()

func fire() -> void:
	if is_reloading:
		return

	# Only fire if we have a target AND it is within the fire_range
	if not current_target or global_position.distance_to(current_target.global_position) > fire_range:
		cooldown_timer.start(0.1) # Check again very quickly
		return
	
	# Prevent the gun from firing before it finishes rotating to face the target
	var aim_dir = Vector2.RIGHT.rotated(rotation)
	var target_dir = global_position.direction_to(current_target.global_position)
	if aim_dir.dot(target_dir) < 0.9: # Must be aimed within ~25 degrees of the target
		cooldown_timer.start(0.05)
		return

	# Visuals
	if muzzle_flash:
		muzzle_flash.show()
		get_tree().create_timer(0.05).timeout.connect(muzzle_flash.hide)

	var stats = {
		"damage": data.get_stat("damage", current_level),
		"speed": data.get_stat("speed", current_level),
		"pierce": int(data.get_stat("pierce", current_level)),
		"bounce": int(data.get_stat("bounce", current_level))
	}
	
	var count = int(data.get_stat("projectiles", current_level))
	var spread_degrees = data.get_stat("spread", current_level)
	var base_direction = global_transform.x.normalized()
	
	for i in range(count):
		var offset_angle = 0.0
		if count > 1:
			offset_angle = deg_to_rad((i - (count - 1) / 2.0) * spread_degrees)
		
		var final_direction = base_direction.rotated(offset_angle)
		spawn_projectile(stats, final_direction)
	
	current_ammo -= 1
	if current_ammo <= 0:
		start_reload()
	else:
		var cd = data.get_stat("cooldown", current_level)
		cooldown_timer.start(cd)

func start_reload() -> void:
	is_reloading = true
	var reload_time = data.get_stat("reload_time", current_level)
	cooldown_timer.start(reload_time)
	print("Minigun Reloading...")

func finish_reload() -> void:
	is_reloading = false
	current_ammo = int(data.get_stat("clip_size", current_level))
	var cd = data.get_stat("cooldown", current_level)
	cooldown_timer.start(cd)

func spawn_projectile(stats: Dictionary, direction: Vector2) -> void:
	if not data.projectile_scene:
		return
		
	var bullet = data.projectile_scene.instantiate()
	get_tree().root.add_child(bullet)
	
	bullet.global_position = muzzle.global_position
	bullet.setup(stats, direction)
