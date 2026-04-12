extends Node2D

@export var data: WeaponResource

# --- TACTICAL TARGETING RANGES (Base values) ---
@export var track_range: float = 800.0
@export var fire_range: float = 400.0 
@export var danger_zone: float = 180.0 

var current_level: int = 1
var current_ammo: int = 0
var is_reloading: bool = false
var current_target: Node2D = null

# --- NEW: Cached Meta Bonuses ---
var meta_range_bonus: float = 0.0
var meta_aim_bonus: float = 0.0

@onready var cooldown_timer = $Timer
@onready var muzzle = $Muzzle
@onready var muzzle_flash = $Muzzle/MuzzleFlash
@onready var gun_sprite = $GunSprite 

func _ready() -> void:
	# --- NEW: Fetch bonuses from the Player's Smart Resource ---
	if owner and "data" in owner and owner.data.has_method("get_bonus_weapon_range"):
		meta_range_bonus = owner.data.get_bonus_weapon_range()
		meta_aim_bonus = owner.data.get_bonus_aim_speed()
		
		# Apply Range bonus to tracking and firing ranges immediately
		track_range += meta_range_bonus
		fire_range += meta_range_bonus

	if data:
		current_ammo = int(data.get_stat("clip_size", current_level))
		start_weapon()
	
	if muzzle_flash:
		muzzle_flash.hide()

func _physics_process(delta: float) -> void:
	var player_facing_dir = get_player_facing_dir()
	current_target = get_best_target(player_facing_dir)
	
	var target_angle = player_facing_dir.angle()
	
	var is_in_danger: bool = false
	if is_instance_valid(current_target):
		var target_vec = current_target.global_position - global_position
		target_angle = target_vec.angle()
		if global_position.distance_to(current_target.global_position) <= danger_zone:
			is_in_danger = true
	
	if not is_in_danger:
		var wrapped_target = wrapf(target_angle, -PI, PI)
		if player_facing_dir.x > 0 and wrapped_target > PI / 2:
			target_angle = -PI 
		elif player_facing_dir.x < 0 and wrapped_target > 0 and wrapped_target < PI / 2:
			target_angle = 0.0 

	# --- MODIFIED: Apply Greased Bearings bonus to rotation speed ---
	var rot_speed = data.get_stat("rotation_speed", current_level)
	if rot_speed <= 0.0: rot_speed = 8.0 
	
	# Add the meta bonus to the base speed
	rot_speed += meta_aim_bonus 
	
	var final_rot_speed = rot_speed * 2.0 if is_in_danger else rot_speed
	
	rotation = lerp_angle(rotation, target_angle, final_rot_speed * delta)
	
	if abs(wrapf(rotation, -PI, PI)) > PI / 2:
		scale.y = -1
	else:
		scale.y = 1

func get_best_target(player_dir: Vector2) -> Node2D:
	if is_instance_valid(current_target):
		var d = global_position.distance_to(current_target.global_position)
		if d <= danger_zone:
			return current_target

	var enemies = get_tree().get_nodes_in_group("enemies")
	var best_target: Node2D = null
	var min_danger_dist = INF
	var best_path_score = -INF
	
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		
		if dist > track_range:
			continue
			
		if dist <= danger_zone:
			if dist < min_danger_dist:
				min_danger_dist = dist
				best_target = enemy
		
		elif min_danger_dist == INF:
			var dir_to_enemy = global_position.direction_to(enemy.global_position)
			var alignment = player_dir.dot(dir_to_enemy) 
			var score = (alignment * 300.0) - dist 
			
			if score > best_path_score:
				best_path_score = score
				best_target = enemy
				
	return best_target

func get_player_facing_dir() -> Vector2:
	if owner and "velocity" in owner and owner.velocity != Vector2.ZERO:
		return owner.velocity.normalized()
	elif owner and owner.has_node("AnimatedSprite2D"):
		return Vector2.LEFT if owner.get_node("AnimatedSprite2D").flip_h else Vector2.RIGHT
	return Vector2.RIGHT

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

	if not is_instance_valid(current_target) or global_position.distance_to(current_target.global_position) > fire_range:
		cooldown_timer.start(0.1) 
		return
	
	var aim_dir = Vector2.RIGHT.rotated(rotation)
	var target_dir = global_position.direction_to(current_target.global_position)
	
	var dist = global_position.distance_to(current_target.global_position)
	var aim_threshold = 0.9 if dist > danger_zone else 0.3
	
	if aim_dir.dot(target_dir) < aim_threshold: 
		cooldown_timer.start(0.05)
		return

	if gun_sprite:
		var tween = create_tween()
		tween.tween_property(gun_sprite, "position:x", -8.0, 0.04).set_trans(Tween.TRANS_QUINT)
		tween.tween_property(gun_sprite, "position:x", 0.0, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if muzzle_flash:
		muzzle_flash.show()
		get_tree().create_timer(0.05).timeout.connect(muzzle_flash.hide)

	# --- MODIFIED: Pass max_range directly into the bullet stats ---
	var stats = {
		"damage": data.get_stat("damage", current_level),
		"speed": data.get_stat("speed", current_level),
		"pierce": int(data.get_stat("pierce", current_level)),
		"bounce": int(data.get_stat("bounce", current_level)),
		"max_range": fire_range # The bullet will travel as far as the gun can "see"
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
