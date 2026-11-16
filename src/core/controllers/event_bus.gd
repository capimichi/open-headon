class_name EventBusController
extends Node

## EventBus: Central event broker facilitating decoupled inter-module communication.

# --- Game Lifecycle Events ---
signal game_started(mode: int)
signal game_paused(is_paused: bool)
signal game_over(winner_id: int)

# --- Ship Lifecycle & State Events ---
signal ship_spawned(player_id: int, position: Vector2)
signal ship_docked(player_id: int, is_docked: bool)
signal ship_shield_changed(player_id: int, current: int, max_val: int)
signal ship_fuel_changed(player_id: int, current: int, max_val: int)
signal ship_ammo_changed(player_id: int, weapon_slot: int, current: int)
signal ship_destroyed(player_id: int, killer_id: int)

# --- Combat Events ---
signal projectile_fired(player_id: int, weapon_id: int, origin: Vector2, velocity: Vector2)
signal damage_applied(target_id: int, attacker_id: int, damage_amount: int)
signal explosion_occurred(position: Vector2, radius: float)

# --- Match & Environment Events ---
signal level_loaded(level_id: int)
signal star_spawned(position: Vector2)
signal star_collected(player_id: int, points: int)
signal score_updated(player_id: int, new_score: int)

# --- Audio Events ---
signal play_sfx_requested(sfx_name: String, position: Vector2)
