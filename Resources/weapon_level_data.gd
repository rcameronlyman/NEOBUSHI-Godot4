extends Resource
class_name WeaponLevelData

@export_multiline var level_description: String = "Upgrade details here..."

@export_group("Stat Changes")
@export var damage_add: float = 0.0
@export var cooldown_add: float = 0.0 # Use negative numbers (e.g., -0.05) to fire faster
@export var projectile_add: int = 0
@export var bounce_add: int = 0 # To handle your Level 5, 7, and 8 requests
