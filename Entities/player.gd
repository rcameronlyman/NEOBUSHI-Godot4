extends CharacterBody2D

# This now holds the character's stats and art
@export var data: PlayerResource

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
