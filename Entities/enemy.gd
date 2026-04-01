extends CharacterBody2D

@export var data: EnemyResource

@onready var sprite = $Sprite2D
@onready var nav_agent = $NavigationAgent2D

var player = null
var current_health: float

func _ready() -> void:
	# 1. Initialize stats and visuals from the Resource
	if data:
		current_health = data.health
		if data.sprite_texture:
			sprite.texture = data.sprite_texture
	
	# 2. Find the player using the existing group logic
	player = get_tree().get_first_node_in_group("player")
	
	# 3. Setup Navigation 
	nav_agent.path_desired_distance = 20.0
	nav_agent.target_desired_distance = 20.0

func _physics_process(_delta: float) -> void:
	if not player or not data:
		return
		
	# 4. Use NavigationAgent2D to find the path to the player 
	nav_agent.target_position = player.global_position
	
	if nav_agent.is_navigation_finished():
		return

	# 5. Calculate movement using the Resource speed
	var next_path_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	
	velocity = direction * data.speed
	
	# 6. Visuals: Flip the sprite based on movement 
	if direction.x < 0:
		sprite.flip_h = true
	elif direction.x > 0:
		sprite.flip_h = false
		
	move_and_slide()

# 7. Combat logic: How the enemy takes damage 
func take_damage(amount: float):
	current_health -= amount
	if current_health <= 0:
		die()

func die():
	# Emit the death signal to the Global Bus for the Director to hear
	GameEvents.enemy_died.emit(global_position, data.xp_value)
	queue_free()

# 8. How the enemy deals damage
func _on_damage_area_body_entered(body: Node2D) -> void:
	if body == player and body.has_method("take_damage"):
		body.take_damage(data.damage)
