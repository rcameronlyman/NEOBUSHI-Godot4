extends Node

@export_group("Spawning Targets")
@export var elite_scene: PackedScene
@export var base_location: Node2D

enum MissionPhase { ATTRITION, BREACH, INTERIOR, ERADICATION, SHOWDOWN }
var current_phase: MissionPhase = MissionPhase.ATTRITION

var total_kills: int = 0
var phase_1_kill_goal: int = 500
var base_swarm_total: int = 200
var base_swarm_remaining: int = 200
var elite_spawned: bool = false

func _ready() -> void:
	GameEvents.enemy_died.connect(_on_enemy_died)
	GameEvents.wall_damaged.connect(_on_wall_damaged)
	GameEvents.wall_destroyed.connect(_on_wall_destroyed)
	
	# Initialize Phase 1
	GameEvents.objective_updated.emit("Phase 1: Thin out Forces", 0.0)

func _on_enemy_died(_position: Vector2, _xp: int) -> void:
	total_kills += 1
	
	match current_phase:
		MissionPhase.ATTRITION:
			var progress = float(total_kills) / phase_1_kill_goal * 100.0
			GameEvents.objective_updated.emit("Phase 1: Thin out Forces", progress)
			
			if total_kills >= phase_1_kill_goal:
				start_phase_2()
				
		MissionPhase.INTERIOR:
			base_swarm_remaining -= 1
			var progress = 100.0 - (float(base_swarm_remaining) / base_swarm_total * 100.0)
			GameEvents.objective_updated.emit("Phase 3: Clear the Interior", progress)
			
			# Elite spawns when 75% are killed (25% remaining)
			if not elite_spawned and base_swarm_remaining <= (base_swarm_total * 0.25):
				spawn_elite()
				
			if base_swarm_remaining <= 0 and elite_spawned:
				start_phase_4()

func _on_wall_damaged(_current_hp: float, _max_hp: float) -> void:
	if current_phase == MissionPhase.BREACH:
		# Tell the EnemySpawner to crank up the heat
		GameEvents.request_spawn_intensity.emit(2.0)

func _on_wall_destroyed() -> void:
	if current_phase == MissionPhase.BREACH:
		start_phase_3()

func start_phase_2() -> void:
	current_phase = MissionPhase.BREACH
	total_kills = 0 # Reset if you need specific generic tracking later
	GameEvents.objective_updated.emit("Phase 2: Destroy the Base", 0.0)

func start_phase_3() -> void:
	current_phase = MissionPhase.INTERIOR
	# Return the main exterior swarm to normal
	GameEvents.request_spawn_intensity.emit(1.0) 
	base_swarm_remaining = base_swarm_total
	GameEvents.objective_updated.emit("Phase 3: Clear the Interior", 0.0)

func spawn_elite() -> void:
	elite_spawned = true
	print("Elite Spawned!")
	
	if not elite_scene:
		push_warning("No Elite Scene assigned to Moon Director!")
		return
		
	var elite_instance = elite_scene.instantiate()
	
	# Add to the current scene so it isn't stuck to the Director
	get_tree().current_scene.add_child(elite_instance)
	
	# Spawn it at the base location if assigned, otherwise slightly offset from the player
	if base_location:
		elite_instance.global_position = base_location.global_position
	else:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			elite_instance.global_position = player.global_position + Vector2(500, 500)

func start_phase_4() -> void:
	current_phase = MissionPhase.ERADICATION
	GameEvents.objective_updated.emit("Phase 4: Eradicate Remaining Forces", 0.0)
