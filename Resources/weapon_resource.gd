extends Resource
class_name WeaponResource

@export_group("Visuals")
@export var weapon_name: String = "New Weapon"
@export var weapon_rank: String = "C" # C, B, A, or S
@export var icon: Texture2D
@export var projectile_scene: PackedScene

@export_group("Base Stats")
@export var base_damage: float = 10.0
@export var base_cooldown: float = 1.0
@export var base_speed: float = 600.0
@export var base_pierce: int = 1
@export var base_projectiles: int = 1
@export var base_bounce: int = 0
@export var base_clip_size: int = 10
@export var base_reload_time: float = 2.0
@export var base_spread: float = 15.0
@export var base_rotation_speed: float = 3.0

@export_group("Progression")
@export var levels: Array[WeaponLevelData] = []
@export var fusion_partner_id: String = "" # Set this to the weapon_name of the required partner
@export var fusion_result: WeaponResource # The S-Tier/Epic weapon resource created via fusion

# This helper will calculate our actual stats by adding up the levels
func get_stat(stat_name: String, level: int) -> float:
	var total = get("base_" + stat_name)
	
	# Loop through the upgrades.
	# Level 1 = 0 upgrades, Level 2 = Index 0, Level 3 = Index 0 & 1, etc.
	for i in range(level - 1):
		if i < levels.size():
			var level_data = levels[i]
			total += level_data.get(stat_name + "_add")
			
	return total
