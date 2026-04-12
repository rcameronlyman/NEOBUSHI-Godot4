extends Area2D

@export var damage: float = 0.0
@export var speed: float = 0.0
@export var pierce: int = 0
@export var bounce: int = 0

var direction: Vector2 = Vector2.RIGHT
var last_hit_target: Node2D = null

# --- NEW: Range tracking ---
var max_range: float = 1000.0 # Default fallback
var distance_traveled: float = 0.0

func _physics_process(delta: float) -> void:
	var move_step = speed * delta
	position += direction * move_step
	
	# --- NEW: Kill the bullet if it exceeds its max range ---
	distance_traveled += move_step
	if distance_traveled >= max_range:
		queue_free()

func setup(stats: Dictionary, start_direction: Vector2):
	damage = stats.get("damage", 0.0)
	speed = stats.get("speed", 0.0)
	pierce = stats.get("pierce", 0)
	bounce = stats.get("bounce", 0)
	
	# Pull the range limit from the dictionary (passed in from weaponbase)
	max_range = stats.get("max_range", 1000.0)
	
	direction = start_direction
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		if body == last_hit_target: return
		
		body.take_damage(damage)
		last_hit_target = body
		handle_collision(body)

func handle_collision(current_enemy: Node2D):
	if pierce > 0:
		pierce -= 1
	elif bounce > 0:
		bounce -= 1
		find_new_target(current_enemy)
	else:
		queue_free()

func find_new_target(ignore_target: Node2D):
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy: Node2D = null
	var min_dist = INF
	
	for enemy in enemies:
		if enemy == ignore_target: continue
		
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist and dist < 400.0:
			min_dist = dist
			closest_enemy = enemy
			
	if closest_enemy:
		direction = global_position.direction_to(closest_enemy.global_position)
		rotation = direction.angle()
	else:
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
