extends Resource
class_name WeaponLevelData

@export_multiline var level_description: String = "Upgrade details here..."

@export_group("Stat Changes")
@export var damage_add: float = 0.0
@export var cooldown_add: float = 0.0 # Use negative numbers (e.g., -0.05) to fire faster
@export var speed_add: float = 0.0 # Added to fix the 'Nil' addition crash
@export var projectiles_add: int = 0 # Renamed to plural to match 'base_projectiles'
@export var bounce_add: int = 0 
@export var pierce_add: int = 0
@export var clip_size_add: int = 0
@export var reload_time_add: float = 0.0 # Use negative numbers to reload faster
@export var spread_add: float = 0.0 # Degrees to separate split projectiles
@export var rotation_speed_add: float = 0.0
