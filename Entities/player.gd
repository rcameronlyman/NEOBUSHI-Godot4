extends CharacterBody2D

# This creates the slot in the Inspector for your .tres file
@export var movement_data : MovementData

func _physics_process(delta: float) -> void:
	# 1. Get the direction from the Input Map
	var input_axis = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# 2. Movement Logic (with High-Force Braking)
	if input_axis != Vector2.ZERO:
		var target_speed = movement_data.max_speed
		var current_accel = movement_data.acceleration
		
		# If we hit the 'pause' frame (8), use a massive force to stop the slide
		if $AnimatedSprite2D.frame == 8:
			target_speed = 0 # Aim for a total stop
			current_accel = 5000 # Override 800 with a "Power Brake"
			
		velocity = velocity.move_toward(input_axis * target_speed, current_accel * delta)
	else:
		# Apply heavy friction (4000) when keys are released
		velocity = velocity.move_toward(Vector2.ZERO, movement_data.friction * delta)
	
	# 3. Animation Logic
	handle_animations(input_axis)
	
	# 4. Apply movement
	move_and_slide()

func handle_animations(axis: Vector2) -> void:
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
