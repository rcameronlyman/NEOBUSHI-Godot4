extends Node

# Root Node: Node
# Path: /Autoloads/game_events.gd

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
signal time_updated(seconds: float) # Broadcasts the remaining mission time
signal time_limit_reached() # Broadcasts when the 15-minute clock hits zero

# Game State Signals
signal player_died
signal mission_started(level_resource: LevelResource) # NEW: Broadcasts all level settings to the game
