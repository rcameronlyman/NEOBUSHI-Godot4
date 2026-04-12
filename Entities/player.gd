extends CharacterBody2D

# This now holds the character's stats and art
@export var data: PlayerResource

var current_health: float
var current_xp: int = 0
var current_level: int = 1
var next_level_xp: int = 100

# --- CACHED FINAL STATS ---
var final_max_health: float
var final_move_speed: float
var nanobot_regen_rate: float
var xp_multiplier: float

# NEW: This links the code to the HealthBar node you created
@onready var health_bar = $HealthBar

func _ready() -> void:
	if data:
		# 1. Fetch all upgraded stats dynamically from the Smart Resource!
		final_max_health = data.get_final_max_health()
		final_move_speed = data.get_final_move_speed()
		nanobot_regen_rate = data.get_nanobot_regen_rate()
		xp_multiplier = data.get_xp_multiplier()
		
		# Apply Health
		current_health = final_max_health
		
		# Initialize the health bar values based on your Resource
		if health_bar:
			health_bar.max_value = final_max_health
			health_bar.value = current_health
			
		# Apply Magnet Bonus
		if has_node("MagnetArea/CollisionShape2D"):
			var shape = $MagnetArea/CollisionShape2D.shape as CircleShape2D
			if shape:
				shape.radius += data.get_magnet_bonus()
			
		# Dynamically load the SpriteFrames from the Resource
		if data.sprite_frames:
			$AnimatedSprite2D.sprite_frames = data.sprite_frames
			$AnimatedSprite2D.play("default")
	
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
		
	# --- NANOBOT REGENERATION ---
	# Heals the player over time if they are hurt, up to their max health
	if nanobot_regen_rate > 0.0 and current_health < final_max_health and current_health > 0:
		current_health += nanobot_regen_rate * delta
		current_health = min(current_health, final_max_health)
		if health_bar:
			health_bar.value = current_health
		
	# 1. Get the direction from the Input Map
	var input_axis = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# 2. Movement Logic (Using the CACHED speed value)
	if input_axis != Vector2.ZERO:
		var target_speed = final_move_speed
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

# --- COMBAT LOGIC ---

func take_damage(amount: float) -> void:
	current_health -= amount
	
	# NEW: Update the visual health bar every time damage is taken
	if health_bar:
		health_bar.value = current_health
	
	# This allows you to see every hit in the output console
	print("OUCH! Player took ", amount, " damage. Health left: ", current_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	# NEW: Hide the health bar when dead so it doesn't float over the "corpse"
	if health_bar:
		health_bar.hide()
		
	print("!!! GAME OVER - PLAYER HAS DIED !!!")
	
	# Stop the walking animation and turn the player red
	$AnimatedSprite2D.stop()
	$AnimatedSprite2D.modulate = Color(1, 0, 0, 0.6) 
	
	# Emit the global death signal to trigger the UI system
	GameEvents.player_died.emit()
	
	set_physics_process(false)

# --- PROGRESSION LOGIC ---

func gain_xp(amount: int) -> void:
	# --- NEURAL OVERCLOCK INTEGRATION ---
	# Multiply the incoming XP by the Overclock bonus
	var final_amount = int(amount * xp_multiplier)
	
	# --- META XP INTEGRATION ---
	ProgressionManager.add_pending_xp(final_amount)
	
	current_xp += final_amount
	
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
