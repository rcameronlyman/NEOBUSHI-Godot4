extends CharacterBody2D

# This now holds the character's stats and art
@export var data: PlayerResource

var current_health: float
var current_xp: int = 0
var current_level: int = 1
var next_level_xp: int = 100

func _ready() -> void:
	if data:
		current_health = data.max_health
	
	# Emit initial XP state for future UI
	GameEvents.xp_gained.emit(current_xp, next_level_xp)
	
	# Connect the magnet area via code
	if has_node("MagnetArea"):
		$MagnetArea.area_entered.connect(_on_magnet_area_entered)
	
	# Connect to the global upgrade signal
	GameEvents.upgrade_applied.connect(_on_upgrade_applied)

func _physics_process(delta: float) -> void:
	if not data:
		return
		
	# 1. Get the direction from the Input Map
	var input_axis = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# 2. Movement Logic (Using the Resource values)
	if input_axis != Vector2.ZERO:
		var target_speed = data.movement_speed
		var current_accel = data.acceleration
		
		# Mech "Power Brake" Logic
		if $AnimatedSprite2D.frame == 8:
			target_speed = 0
			current_accel = 5000
			
		velocity = velocity.move_toward(input_axis * target_speed, current_accel * delta)
	else:
		# Apply friction from resource
		velocity = velocity.move_toward(Vector2.ZERO, data.friction * delta)
	
	# 3. Animation Logic
	handle_animations(input_axis)
	
	# 4. Apply movement
	move_and_slide()

func handle_animations(axis: Vector2) -> void:
	if not data:
		return
		
	# Flip sprite based on horizontal movement
	if axis.x < 0:
		$AnimatedSprite2D.flip_h = true
	elif axis.x > 0:
		$AnimatedSprite2D.flip_h = false
	
	# Play if moving, reset to frame 0 if still
	if axis != Vector2.ZERO:
		$AnimatedSprite2D.play("default")
	else:
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.frame = 0

func take_damage(amount: float) -> void:
	current_health -= amount
	if current_health <= 0:
		die()

func die() -> void:
	set_physics_process(false)

# --- PROGRESSION LOGIC ---

func gain_xp(amount: int) -> void:
	current_xp += amount
	
	# Loop in case multiple levels are gained at once
	while current_xp >= next_level_xp:
		level_up()
	
	# Update UI with final progress
	GameEvents.xp_gained.emit(current_xp, next_level_xp)

func level_up() -> void:
	current_level += 1
	current_xp -= next_level_xp
	next_level_xp = int(next_level_xp * 1.5)
	
	# Signal the ProgressionManager to trigger the upgrade menu
	GameEvents.level_up.emit(current_level)

func _on_upgrade_applied(upgrade: UpgradeResource) -> void:
	if upgrade.is_weapon:
		# Locate the Minigun on the Left Shoulder socket
		var weapon = $Shoulder_Socket_L/WeaponBase
		
		# Verify names match before incrementing the level
		if weapon and weapon.data.weapon_name == upgrade.weapon_data.weapon_name:
			weapon.current_level += 1
			print("Upgraded: ", weapon.data.weapon_name, " to Level ", weapon.current_level)

# --- MAGNET LOGIC ---

func _on_magnet_area_entered(area: Area2D) -> void:
	if area.has_method("magnetize"):
		area.magnetize(self)
