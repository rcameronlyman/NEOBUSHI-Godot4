extends Node2D

@export var data: WeaponResource

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
	# Keep track of the target every frame
	current_target = get_closest_target()
	
	if current_target and data:
		# Calculate the raw angle we need to face
		var target_vec = current_target.global_position - global_position
		var target_angle = target_vec.angle()
		
		# --- HIGH ROAD LOGIC ---
		# We force the gun to rotate through the negative (Up) arc when crossing sides
		# to avoid the gun passing through the character's body.
		if abs(rotation) < PI/2 and target_angle > PI/2:
			target_angle -= TAU
		elif abs(rotation) > PI/2 and target_angle > 0 and target_angle < PI/2:
			target_angle -= TAU
		
		var rot_speed = data.get_stat("rotation_speed", current_level)
		rotation = rotate_toward(rotation, target_angle, rot_speed * delta)
		
		# --- UPRIGHT SPRITE LOGIC ---
		# Flip the Y axis so the "top" of the gun remains on top when pointing Left.
		if abs(rotation) > PI/2:
			scale.y = -1
		else:
			scale.y = 1

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

	if not current_target:
		cooldown_timer.start(0.1)
		return
	
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

func get_closest_target() -> Node2D:
	var bodies = $TargetingArea.get_overlapping_bodies()
	var closest_target: Node2D = null
	var closest_distance: float = INF
	
	for body in bodies:
		if body.has_method("take_damage"):
			var distance = global_position.distance_squared_to(body.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_target = body
	return closest_target
