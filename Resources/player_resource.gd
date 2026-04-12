extends Resource
class_name PlayerResource

@export_group("Visuals")
@export var character_name: String = "Hero"
@export var sprite_frames: SpriteFrames # Changed to SpriteFrames for multiple animations

@export_group("Stats")
@export var max_health: float = 100.0
@export var movement_speed: float = 300.0
@export var acceleration: float = 800.0
@export var friction: float = 4000.0

# --- DYNAMIC STAT CALCULATORS ---
# These functions calculate the final value by adding the base stat to the Meta Upgrade bonus.

func get_final_max_health() -> float:
	return max_health + ProgressionManager.get_stat_bonus("Max Health", character_name)

func get_final_move_speed() -> float:
	return movement_speed + ProgressionManager.get_stat_bonus("Move Speed", character_name)

func get_nanobot_regen_rate() -> float:
	return ProgressionManager.get_stat_bonus("Nano Bots", character_name)

func get_xp_multiplier() -> float:
	# Base multiplier is 1.0 (100% normal XP). Overclock adds to this.
	return 1.0 + ProgressionManager.get_stat_bonus("Neural Overclock", character_name)

func get_magnet_bonus() -> float:
	return ProgressionManager.get_stat_bonus("Magnet", character_name)

# --- WEAPON MODIFIERS ---
# Weapons will be able to call these directly to get their bonuses

func get_bonus_weapon_range() -> float:
	return ProgressionManager.get_stat_bonus("Range", character_name)

func get_bonus_aim_speed() -> float:
	return ProgressionManager.get_stat_bonus("Greased Bearings", character_name)
