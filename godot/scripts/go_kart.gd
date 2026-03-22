extends VehicleBody3D
## Arcade vehicle physics — fast, responsive, fun at any speed.
## Prioritizes feel over realism. You should be able to turn at full speed.

var is_drifting: bool = false
var player_driving: bool = true
var current_steer: float = 0.0

@onready var wheel_fl: VehicleWheel3D = $WheelFL
@onready var wheel_fr: VehicleWheel3D = $WheelFR
@onready var wheel_rl: VehicleWheel3D = $WheelRL
@onready var wheel_rr: VehicleWheel3D = $WheelRR

func _ready() -> void:
	mass = Config.cart_mass
	linear_damp = Config.linear_damping
	angular_damp = Config.angular_damping

	# Rotate visual model to face correct direction
	var model_pivot = get_node_or_null("ModelPivot")
	if model_pivot:
		model_pivot.rotation.y = PI

	for wheel in [wheel_fl, wheel_fr, wheel_rl, wheel_rr]:
		wheel.wheel_radius = Config.wheel_radius
		wheel.suspension_stiffness = Config.suspension_stiffness
		wheel.damping_compression = Config.suspension_compression
		wheel.damping_relaxation = Config.suspension_relaxation
		wheel.wheel_rest_length = Config.suspension_rest_length
		wheel.suspension_max_force = Config.suspension_max_force
		wheel.suspension_travel = Config.suspension_max_travel
		wheel.wheel_friction_slip = Config.wheel_friction_slip

func _physics_process(delta: float) -> void:
	if not player_driving:
		wheel_rl.engine_force = 0
		wheel_rr.engine_force = 0
		wheel_fl.steering = 0
		wheel_fr.steering = 0
		for w in [wheel_fl, wheel_fr, wheel_rl, wheel_rr]:
			w.brake = 0.5
		return

	var throttle := Input.get_axis("brake_reverse", "accelerate")
	var steer_input := Input.get_axis("move_right", "move_left")
	var handbrake := Input.is_action_pressed("handbrake")

	# Current speed
	var local_vel = global_transform.basis.inverse() * linear_velocity
	var forward_speed = -local_vel.z
	var lateral_speed = local_vel.x
	var speed = linear_velocity.length()

	# === STEERING — instant, full control at all speeds ===
	current_steer = lerpf(current_steer, steer_input * Config.cart_max_steer_angle, 8.0 * delta)
	wheel_fl.steering = current_steer
	wheel_fr.steering = current_steer

	# === ENGINE — strong acceleration, gentle speed limit ===
	var engine_force_val: float = 0.0
	if throttle > 0:
		# Soft speed cap — doesn't brick the engine, just tapers off
		var power_curve = maxf(0.1, 1.0 - (speed / Config.cart_max_speed) * 0.7)
		engine_force_val = throttle * Config.cart_max_engine_force * power_curve
	elif throttle < 0:
		engine_force_val = throttle * Config.cart_max_reverse_force

	wheel_rl.engine_force = -engine_force_val / 2.0
	wheel_rr.engine_force = -engine_force_val / 2.0

	# === BRAKING ===
	if handbrake:
		wheel_rl.brake = 3.0
		wheel_rr.brake = 3.0
		wheel_fl.brake = 0.0
		wheel_fr.brake = 0.0
		# Loosen rear wheels for drift
		wheel_rl.wheel_friction_slip = 0.6
		wheel_rr.wheel_friction_slip = 0.6
	elif throttle == 0 and speed > 1.0:
		# Gentle coast brake
		for w in [wheel_fl, wheel_fr, wheel_rl, wheel_rr]:
			w.brake = 0.3
		wheel_rl.wheel_friction_slip = Config.wheel_friction_slip
		wheel_rr.wheel_friction_slip = Config.wheel_friction_slip
	else:
		for w in [wheel_fl, wheel_fr, wheel_rl, wheel_rr]:
			w.brake = 0.0
		wheel_rl.wheel_friction_slip = Config.wheel_friction_slip
		wheel_rr.wheel_friction_slip = Config.wheel_friction_slip

	# === DRIFT DETECTION ===
	is_drifting = (handbrake and speed > Config.drift_threshold) or \
		(absf(lateral_speed) > speed * 0.35 and speed > Config.drift_threshold)

	# === ACTIVE STEERING FORCE ===
	# Instead of fighting lateral velocity (old grip system),
	# directly apply a turning force. This makes steering feel the same
	# at any speed — like Mario Kart, not Gran Turismo.
	if absf(steer_input) > 0.1 and speed > 1.0:
		var turn_force = steer_input * Config.steer_torque_multiplier
		# Scale slightly with speed for natural feel, but cap it
		var speed_boost = minf(speed * 0.3, 8.0)
		apply_torque_impulse(Vector3(0, turn_force * speed_boost * delta, 0))

	# === LATERAL GRIP (gentle, doesn't overpower steering) ===
	# Only cancel SOME lateral slide to prevent infinite spinning
	if not handbrake:
		var right_dir = global_transform.basis.x
		var grip_force = -lateral_speed * 0.3 * delta * 30.0
		grip_force = clampf(grip_force, -8.0, 8.0)
		apply_central_impulse(right_dir * grip_force)
	else:
		# During handbrake, barely any grip — let it slide
		var right_dir = global_transform.basis.x
		var grip_force = -lateral_speed * 0.08 * delta * 30.0
		grip_force = clampf(grip_force, -4.0, 4.0)
		apply_central_impulse(right_dir * grip_force)

	# === ANTI-FLIP ===
	var up = global_transform.basis.y
	var tilt = acos(clampf(up.dot(Vector3.UP), -1.0, 1.0))
	if tilt > Config.anti_flip_threshold:
		var restore_axis = Vector3.UP.cross(up).normalized()
		apply_torque_impulse(restore_axis * -tilt * Config.anti_flip_torque * delta)
