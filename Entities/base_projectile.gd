extends Area2D

@export var damage: float = 0.0
@export var speed: float = 0.0
@export var pierce: int = 0
@export var bounce: int = 0

var direction: Vector2 = Vector2.RIGHT
var last_hit_target: Node2D = null # Prevent bouncing back into the same enemy instantly

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func setup(stats: Dictionary, start_direction: Vector2):
	damage = stats.get("damage", 0.0)
	speed = stats.get("speed", 0.0)
	pierce = stats.get("pierce", 0)
	bounce = stats.get("bounce", 0)
	direction = start_direction
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	# FIX: Now it explicitly checks if the target is an enemy!
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		# Ensure we don't hit the exact same enemy we just bounced off of
		if body == last_hit_target: return
		
		body.take_damage(damage)
		last_hit_target = body
		handle_collision(body)

func handle_collision(current_enemy: Node2D):
	if pierce > 0:
		pierce -= 1
		# Pierce keeps going straight, so we do nothing to the direction
	elif bounce > 0:
		bounce -= 1
		find_new_target(current_enemy)
	else:
		queue_free()

func find_new_target(ignore_target: Node2D):
	var enemies = get_tree().get_nodes_in_group("enemies") # Ensure your enemy nodes are in a group called "enemies"
	var closest_enemy: Node2D = null
	var min_dist = INF
	
	for enemy in enemies:
		if enemy == ignore_target: continue
		
		var dist = global_position.distance_to(enemy.global_position)
		# Only bounce to enemies within a reasonable "search" range (e.g., 400 pixels)
		if dist < min_dist and dist < 400.0:
			min_dist = dist
			closest_enemy = enemy
			
	if closest_enemy:
		# Update the bullet to fly toward the new victim
		direction = global_position.direction_to(closest_enemy.global_position)
		rotation = direction.angle()
	else:
		# If no other enemies are nearby, just let the bullet die or fly off
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
