extends Resource
class_name WeaponResource

@export_group("Visuals")
@export var weapon_name: String = "New Weapon"
@export var icon: Texture2D
@export var projectile_scene: PackedScene

@export_group("Base Stats")
@export var base_damage: float = 10.0
@export var base_cooldown: float = 1.0
@export var base_speed: float = 600.0
@export var base_pierce: int = 1
@export var base_projectiles: int = 1
@export var base_bounce: int = 0

@export_group("Progression")
@export var levels: Array[WeaponLevelData] = []

# This helper will calculate our actual stats by adding up the levels
# Added 'level: int' to the arguments to fix the mismatch error
func get_stat(stat_name: String, level: int) -> float:
	var total = get("base_" + stat_name)
	
	# Loop through the upgrades. 
	# Level 1 = 0 upgrades, Level 2 = Index 0, Level 3 = Index 0 & 1, etc.
	for i in range(level - 1):
		if i < levels.size():
			var level_data = levels[i]
			total += level_data.get(stat_name + "_add")
			
	return total
