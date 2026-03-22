extends CharacterBody3D
## Fortnite-style third-person controller.
## Left stick/WASD: move relative to camera. Right stick/Mouse: orbit camera.
## RT/LMB: shoot in aim direction. Character auto-faces movement or aim.

var cam_yaw: float = 0.0
var cam_pitch: float = -0.3

var paintball_gun: Node3D = null
var is_shooting: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if not is_physics_processing():
		return
	if event is InputEventMouseMotion:
		cam_yaw -= event.relative.x * Config.cam_mouse_sensitivity
		cam_pitch -= event.relative.y * Config.cam_mouse_sensitivity
		cam_pitch = clampf(cam_pitch, Config.cam_pitch_min, Config.cam_pitch_max)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func get_cam_forward() -> Vector3:
	return Vector3(-sin(cam_yaw), 0, -cos(cam_yaw)).normalized()

func get_aim_direction() -> Vector3:
	return Vector3(
		-sin(cam_yaw) * cos(cam_pitch),
		sin(cam_pitch),
		-cos(cam_yaw) * cos(cam_pitch)
	).normalized()

func _physics_process(delta: float) -> void:
	# Right stick camera orbit
	var rs_x := Input.get_axis("aim_left", "aim_right")
	var rs_y := Input.get_axis("aim_up", "aim_down")
	if absf(rs_x) > 0.1:
		cam_yaw -= rs_x * Config.cam_stick_sensitivity * delta
	if absf(rs_y) > 0.1:
		cam_pitch += rs_y * Config.cam_stick_sensitivity * delta
		cam_pitch = clampf(cam_pitch, Config.cam_pitch_min, Config.cam_pitch_max)

	# Gravity
	if not is_on_floor():
		velocity.y -= Config.player_gravity * delta

	# Jump
	if Input.is_action_just_pressed("handbrake") and is_on_floor():
		velocity.y = Config.player_jump_impulse

	# Camera-relative movement
	var cam_fwd = get_cam_forward()
	var cam_right = Vector3(-cam_fwd.z, 0, cam_fwd.x)

	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	var move_dir = Vector3.ZERO
	if input_dir.length() > 0.1:
		input_dir = input_dir.normalized()
		move_dir = cam_fwd * input_dir.y + cam_right * input_dir.x
		move_dir = move_dir.normalized()

	velocity.x = move_dir.x * Config.player_run_speed
	velocity.z = move_dir.z * Config.player_run_speed

	# Character rotation
	is_shooting = Input.is_action_pressed("shoot") or Input.is_action_pressed("shoot_controller")

	if is_shooting:
		rotation.y = cam_yaw
	elif move_dir.length() > 0.1:
		# Face the direction we're moving (model forward is -Z, so add PI)
		var target_yaw = atan2(move_dir.x, move_dir.z) + PI
		rotation.y = lerp_angle(rotation.y, target_yaw, 0.15)

	move_and_slide()

	# Shooting
	if is_shooting and paintball_gun:
		paintball_gun.fire(get_aim_direction(), global_position)

	# Fall off world
	if global_position.y < -10:
		global_position = Config.player_spawn_position
		velocity = Vector3.ZERO

func get_camera_transform() -> Transform3D:
	## Returns the desired camera transform for the orbit camera.
	## Includes raycast collision to prevent clipping through walls.
	var pivot = global_position + Vector3(0, Config.cam_orbit_height, 0)
	var dist = Config.cam_orbit_distance

	var offset = Vector3(
		-sin(cam_yaw) * cos(cam_pitch) * -dist,
		sin(cam_pitch) * -dist + Config.cam_orbit_height,
		-cos(cam_yaw) * cos(cam_pitch) * -dist
	)

	var cam_pos = global_position + offset
	var look_target = pivot + Vector3(0, 0.5, 0)

	# Raycast to prevent camera clipping through walls
	var space_state = get_world_3d().direct_space_state
	if space_state:
		var query = PhysicsRayQueryParameters3D.create(pivot, cam_pos)
		query.exclude = [get_rid()]
		query.collision_mask = 1  # world geometry only
		query.hit_from_inside = true
		var result = space_state.intersect_ray(query)
		if result:
			# Pull camera to 80% of the way to the hit (leaves gap from wall)
			var hit_dist = pivot.distance_to(result.position)
			var full_dist = pivot.distance_to(cam_pos)
			if hit_dist < full_dist:
				var safe_ratio = maxf(0.2, (hit_dist - 0.5) / full_dist)
				cam_pos = pivot.lerp(cam_pos, safe_ratio)

	var xform = Transform3D()
	xform.origin = cam_pos
	xform = xform.looking_at(look_target)
	return xform
