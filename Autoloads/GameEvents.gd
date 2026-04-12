extends Node

# Progression & Leveling
signal xp_gained(current_xp: int, next_level_xp: int)
signal level_up(current_player_level: int)

# Upgrade System
signal display_upgrade_choices(choices: Array[UpgradeResource])
signal update_inventory_ui(current_weapons: Array, current_passives: Array)
signal upgrade_applied(upgrade: UpgradeResource)

# Combat & Objectives (Used by MoonDirector)
signal enemy_died(position: Vector2, xp_value: int)
signal wall_damaged(current_hp: float, max_hp: float)
signal wall_destroyed()
signal objective_updated(description: String, progress_percentage: float)
signal request_spawn_intensity(multiplier: float)

# Game State Signals
signal player_died
