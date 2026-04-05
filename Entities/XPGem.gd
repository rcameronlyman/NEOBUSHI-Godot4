extends Area2D

@export var elite_texture: Texture2D

var xp_value: int = 10
var target: Node2D = null
var current_speed: float = 0.0
var collection_threshold: float = 10.0 # Distance at which the gem is "absorbed"

func _ready() -> void:
	# Keep the physical collision as a backup
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if target:
		# 1. Calculate distance to player
		var dist = global_position.distance_to(target.global_position)
		
		# 2. Absorption Check: If we're close enough, just collect it
		if dist < collection_threshold:
			collect(target)
			return

		# 3. Movement Logic: Accelerate towards the player
		# Lowering acceleration slightly (from 1200 to 800) for a "lighter" feel
		current_speed += 900.0 * delta
		var direction = global_position.direction_to(target.global_position)
		
		# Move towards target, but don't overshoot
		var move_amount = current_speed * delta
		if move_amount > dist:
			move_amount = dist # Snap to target if move distance is larger than gap
			
		global_position += direction * move_amount

func setup(value: int) -> void:
	xp_value = value
	if xp_value >= 50:
		var scale_factor = 1.5 + (float(xp_value) / 500.0)
		scale = Vector2(scale_factor, scale_factor)
		if elite_texture:
			$Sprite2D.texture = elite_texture

func magnetize(pull_target: Node2D) -> void:
	target = pull_target

# We moved the collection logic to its own function to call it from two places
func collect(player: Node2D) -> void:
	if player.has_method("gain_xp"):
		player.gain_xp(xp_value)
		# Optional: Add a small "pop" sound or particle effect trigger here
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	collect(body)
