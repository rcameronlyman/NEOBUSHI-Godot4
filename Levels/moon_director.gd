extends Node

# Root Node: Node
# Path: /Levels/moon_director.gd

@export_group("Mission Config")
## Drag the Moon's LevelResource here to get the 15-minute limit
@export var level_data: LevelResource 
## Drag your mission_intro_ui.tscn here
@export var intro_splash_scene: PackedScene

@export_group("Spawning Targets")
@export var elite_scene: PackedScene
@export var base_location: Node2D

@export_group("Time Scaling")
## How much the intensity increases every 60 seconds
@export var intensity_gain_per_minute: float = 0.1

enum MissionPhase { ATTRITION, BREACH, INTERIOR, ERADICATION, SHOWDOWN, TIME_UP }
var current_phase: MissionPhase = MissionPhase.ATTRITION

var total_kills: int = 0
var phase_1_kill_goal: int = 500
var base_swarm_total: int = 200
var base_swarm_remaining: int = 200
var elite_spawned: bool = false

# --- SCALING & TIMER VARIABLES ---
var time_elapsed: float = 0.0
var time_intensity: float = 1.0
var phase_intensity: float = 1.0
var is_mission_active: bool = true

func _ready() -> void:
	# 1. Connect signals
	GameEvents.enemy_died.connect(_on_enemy_died)
	GameEvents.wall_damaged.connect(_on_wall_damaged)
	GameEvents.wall_destroyed.connect(_on_wall_destroyed)
	
	# 2. Trigger the Intro Splash Screen
	if intro_splash_scene:
		var splash = intro_splash_scene.instantiate()
		add_child(splash)
		# Pass the level data so the UI knows what text to display
		if "level_resource" in splash:
			splash.level_resource = level_data
	
	# 3. Initialize Phase 1 data
	GameEvents.objective_updated.emit("Phase 1: Thin out Forces", 0.0)

func _process(delta: float) -> void:
	if not is_mission_active:
		return
		
	# 1. Track total time spent in the level
	time_elapsed += delta
	
	# 2. Calculate and broadcast remaining time for the UI
	if level_data:
		var max_seconds = level_data.time_limit_minutes * 60.0
		var time_remaining = max(0.0, max_seconds - time_elapsed)
		
		# Broadcast to the UI (UI handles the formatting and the red color shift)
		GameEvents.time_updated.emit(time_remaining)
		
		# Check if the mission clock has run out
		if time_remaining <= 0.0:
			on_time_limit_reached()
	
	# 3. Handle original Intensity Scaling 
	var new_time_intensity = 1.0 + (floor(time_elapsed / 60.0) * intensity_gain_per_minute)
	
	if new_time_intensity != time_intensity:
		time_intensity = new_time_intensity
		sync_intensity()

func on_time_limit_reached() -> void:
	is_mission_active = false
	current_phase = MissionPhase.TIME_UP
	print("MOON MISSION: Time limit reached!")
	# Signal the end of the run to the global event bus
	GameEvents.time_limit_reached.emit()

## Combines phase-specific heat with the passage of time 
func sync_intensity() -> void:
	var total_intensity = phase_intensity * time_intensity
	GameEvents.request_spawn_intensity.emit(total_intensity)

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
			
			if not elite_spawned and base_swarm_remaining <= (base_swarm_total * 0.25):
				spawn_elite()
				
			if base_swarm_remaining <= 0 and elite_spawned:
				start_phase_4()

func _on_wall_damaged(_current_hp: float, _max_hp: float) -> void:
	if current_phase == MissionPhase.BREACH:
		phase_intensity = 2.0
		sync_intensity()

func _on_wall_destroyed() -> void:
	if current_phase == MissionPhase.BREACH:
		start_phase_3()

func start_phase_2() -> void:
	current_phase = MissionPhase.BREACH
	total_kills = 0
	GameEvents.objective_updated.emit("Phase 2: Destroy the Base", 0.0)

func start_phase_3() -> void:
	current_phase = MissionPhase.INTERIOR
	phase_intensity = 1.0
	sync_intensity() 
	
	base_swarm_remaining = base_swarm_total
	GameEvents.objective_updated.emit("Phase 3: Clear the Interior", 0.0)

func spawn_elite() -> void:
	elite_spawned = true
	
	if not elite_scene:
		push_warning("No Elite Scene assigned to Moon Director!")
		return
		
	var elite_instance = elite_scene.instantiate()
	get_tree().current_scene.add_child(elite_instance)
	
	if base_location:
		elite_instance.global_position = base_location.global_position

func start_phase_4() -> void:
	current_phase = MissionPhase.ERADICATION
	GameEvents.objective_updated.emit("Phase 4: Eradicate Remaining Forces", 0.0)
