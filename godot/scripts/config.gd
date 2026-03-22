extends Node
## Central configuration for all game tuning values.
## Accessible globally as Config.property_name

# ========== CART PHYSICS ==========
## Core vehicle mass and speed limits
var cart_mass: float = 50.0
var cart_max_speed: float = 80.0
var cart_max_engine_force: float = 600.0
var cart_max_reverse_force: float = 200.0
var cart_max_steer_angle: float = 0.5

## Drift — threshold speed for drift detection
var drift_threshold: float = 8.0

## Damping
var angular_damping: float = 2.5
var linear_damping: float = 0.15
var steer_torque_multiplier: float = 0.8  # active steering force

## Anti-flip
var anti_flip_torque: float = 10.0
var anti_flip_threshold: float = 0.4

# ========== SUSPENSION ==========
var suspension_stiffness: float = 30.0
var suspension_compression: float = 2.0
var suspension_relaxation: float = 3.5
var suspension_rest_length: float = 0.35
var suspension_max_travel: float = 0.3
var suspension_max_force: float = 6000.0

# ========== WHEEL ==========
var wheel_radius: float = 0.22
var wheel_friction_slip: float = 1.5

# ========== CAMERA — DRIVING ==========
var cam_offset_driving := Vector3(0, 3.5, 8)
var cam_look_ahead_driving := Vector3(0, 1.0, -4)
var cam_smooth_pos: float = 0.08
var cam_smooth_look: float = 0.12
var cam_smooth_pos_drift: float = 0.025
var cam_fov_normal: float = 65.0
var cam_fov_drift: float = 72.0
var cam_fov_smooth: float = 0.08

# ========== CAMERA — ON FOOT ==========
var cam_orbit_distance: float = 6.0
var cam_orbit_height: float = 1.5
var cam_pitch_min: float = -1.2  # look up limit
var cam_pitch_max: float = 0.3   # look down limit
var cam_mouse_sensitivity: float = 0.003
var cam_stick_sensitivity: float = 3.0
var cam_follow_smooth: float = 0.25

# ========== PLAYER — ON FOOT ==========
var player_run_speed: float = 12.0
var player_jump_impulse: float = 8.0
var player_gravity: float = 15.0
var player_enter_exit_radius: float = 3.5
var player_exit_offset: float = 2.0
var player_spawn_position := Vector3(0, 2, 15)

# ========== PAINTBALL GUN ==========
var paintball_fire_rate: float = 0.15   # seconds between shots
var paintball_muzzle_speed: float = 30.0
var paintball_upward_arc: float = 3.0
var paintball_start_ammo: int = 50
var paintball_max_ammo: int = 99
var paintball_knockback: float = 8.0

# ========== SPLATS ==========
var splat_max_count: int = 50
var splat_lifetime: float = 7.0      # seconds before fade starts
var splat_fade_duration: float = 3.0
var splat_size: float = 0.5

# ========== WORLD GENERATION ==========
var world_block_size: float = 40.0
var world_grid_size: int = 3
var world_road_width: float = 8.0
var world_sidewalk_width: float = 2.0
var world_sidewalk_height: float = 0.12

# ========== NPC ==========
var npc_walk_speed: float = 3.0
var npc_flee_speed: float = 8.0
var npc_flee_distance: float = 20.0
var npc_hit_flash_time: float = 0.4

# ========== HUD ==========
var hud_mph_multiplier: float = 2.5  # converts internal speed to display MPH
