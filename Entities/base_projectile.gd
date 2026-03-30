extends Area2D

@export var damage: float = 0.0
@export var speed: float = 0.0
@export var pierce: int = 0
@export var bounce: int = 0

var direction: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	# Move the projectile forward based on the data it was given
	position += direction * speed * delta

# This is the "Data-Driven" handoff
# The Weapon Scene will call this as soon as it spawns the bullet
func setup(stats: Dictionary, start_direction: Vector2):
	damage = stats.get("damage", 0.0)
	speed = stats.get("speed", 0.0)
	pierce = stats.get("pierce", 0)
	bounce = stats.get("bounce", 0)
	direction = start_direction
	
	# Rotate the bullet to face where it is flying
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	# Check if the thing we hit is an enemy with a health system
	if body.has_method("take_damage"):
		body.take_damage(damage)
		handle_collision()

func handle_collision():
	if pierce > 0:
		pierce -= 1
	elif bounce > 0:
		# We will add "Find New Target" logic here later
		bounce -= 1
	else:
		# No pierce or bounce left? Delete the bullet
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	# Crucial for performance: delete bullets that fly off-camera
	queue_free()
