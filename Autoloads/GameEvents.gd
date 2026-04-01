extends Node

# --- PLAYER SIGNALS ---
signal health_changed(current_health, max_health)
signal xp_gained(current_xp, next_level_xp)
signal level_up(new_level)

# --- COMBAT SIGNALS ---
signal enemy_died(enemy_position, meta_xp_value)
signal objective_updated(description, progress)

# --- ENVIRONMENT & OBJECTIVES ---
signal wall_damaged(current_hp, max_hp)
signal wall_destroyed
signal boss_spawned
signal boss_died
signal timer_stopped

# --- SPAWNER CONTROL ---
signal request_spawn_intensity(multiplier)

# --- SYSTEM SIGNALS ---
signal mech_destroyed # This will trigger Pilot Mode later
