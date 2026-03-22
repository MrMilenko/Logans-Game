extends Node3D

enum State { DRIVING, ON_FOOT }

var current_state: State = State.DRIVING
var go_kart: VehicleBody3D
var player: CharacterBody3D
var player_visual: Node3D
var chase_camera: Camera3D
var hud: CanvasLayer
var world: Node3D
var paintball_gun: Node3D

func _ready() -> void:
	# Build the world
	world = load("res://scenes/world/world.tscn").instantiate()
	add_child(world)

	# Spawn go-kart
	go_kart = load("res://scenes/vehicles/go_kart.tscn").instantiate()
	go_kart.position = Vector3(0, 2, 15)
	add_child(go_kart)

	# Spawn player (starts disabled, inside cart)
	player = load("res://scenes/player/player.tscn").instantiate()
	player.position = Vector3(0, -100, 0)
	player.set_physics_process(false)
	player.visible = false
	add_child(player)

	# Create paintball gun (lives on the player visual, hidden when driving)
	paintball_gun = load("res://scenes/weapons/paintball_gun.tscn").instantiate()
	paintball_gun.visible = false

	# Get references
	player_visual = go_kart.get_node("PlayerVisual")
	player_visual.add_child(paintball_gun)
	player.paintball_gun = paintball_gun
	chase_camera = $ChaseCamera
	hud = $HUD

func _physics_process(delta: float) -> void:
	# Handle interact (enter/exit vehicle)
	if Input.is_action_just_pressed("interact"):
		if current_state == State.DRIVING:
			_exit_vehicle()
		elif current_state == State.ON_FOOT:
			var dist = player.global_position.distance_to(go_kart.global_position)
			if dist < Config.player_enter_exit_radius:
				_enter_vehicle()

	# Handle reset
	if Input.is_action_just_pressed("reset"):
		if current_state == State.DRIVING:
			go_kart.position = Vector3(0, 2, 15)
			go_kart.rotation = Vector3.ZERO
			go_kart.linear_velocity = Vector3.ZERO
			go_kart.angular_velocity = Vector3.ZERO
		else:
			player.position = Vector3(0, 2, 15)
			player.velocity = Vector3.ZERO

func _process(delta: float) -> void:
	# Update camera
	_update_camera(delta)

	# Update HUD
	if hud:
		var speed = go_kart.linear_velocity.length() if go_kart else 0.0
		var drifting = go_kart.is_drifting if go_kart else false
		var near_vehicle = false
		if current_state == State.ON_FOOT and player and go_kart:
			near_vehicle = player.global_position.distance_to(go_kart.global_position) < Config.player_enter_exit_radius
		var ammo = paintball_gun.ammo if paintball_gun else 0
		hud.update_hud(current_state == State.DRIVING, speed, drifting, near_vehicle, ammo)

func _update_camera(delta: float) -> void:
	if not chase_camera:
		return

	var target: Node3D
	var is_on_foot = current_state == State.ON_FOOT
	var is_drifting = false

	if is_on_foot:
		target = player
	else:
		target = go_kart
		if go_kart and "is_drifting" in go_kart:
			is_drifting = go_kart.is_drifting

	if not target:
		return

	if is_on_foot:
		# Orbit camera controlled by player_controller
		var desired_xform = player.get_camera_transform()
		chase_camera.global_position = chase_camera.global_position.lerp(desired_xform.origin, Config.cam_follow_smooth)
		# Always look at the player
		chase_camera.look_at(player.global_position + Vector3(0, Config.cam_orbit_height, 0))
		chase_camera.fov = lerpf(chase_camera.fov, Config.cam_fov_normal, Config.cam_fov_smooth)
	else:
		var offset = Config.cam_offset_driving
		var look_ahead = Config.cam_look_ahead_driving
		var smooth_pos = Config.cam_smooth_pos_drift if is_drifting else Config.cam_smooth_pos
		var smooth_look = Config.cam_smooth_look

		# Desired position behind target
		var desired_pos = target.global_transform.basis * offset + target.global_position
		chase_camera.global_position = chase_camera.global_position.lerp(desired_pos, smooth_pos)

		# Look-at target
		var desired_look = target.global_transform.basis * look_ahead + target.global_position
		var current_look = chase_camera.global_position + chase_camera.global_transform.basis * Vector3(0, 0, -1) * 10
		var look_target = current_look.lerp(desired_look, smooth_look)
		chase_camera.look_at(look_target)

		# FOV
		var target_fov = Config.cam_fov_drift if is_drifting else Config.cam_fov_normal
		chase_camera.fov = lerpf(chase_camera.fov, target_fov, Config.cam_fov_smooth)

func _exit_vehicle() -> void:
	current_state = State.ON_FOOT

	# Compute exit position (to the right of the cart)
	var cart_right = go_kart.global_transform.basis.x
	var exit_pos = go_kart.global_position + cart_right * Config.player_exit_offset
	exit_pos.y = go_kart.global_position.y + 0.5

	# Move player visual from cart to player
	if player_visual and player_visual.get_parent() == go_kart:
		var vis = player_visual
		go_kart.remove_child(vis)
		player.get_node("VisualRoot").add_child(vis)
		vis.position = Vector3.ZERO
		vis.rotation = Vector3.ZERO

	# Enable player
	player.global_position = exit_pos
	player.rotation.y = go_kart.rotation.y + PI / 2
	player.velocity = Vector3.ZERO
	player.set_physics_process(true)
	player.visible = true

	# Disable cart input (it keeps physics but no engine force)
	go_kart.player_driving = false

	# Initialize camera yaw to match cart facing
	player.cam_yaw = go_kart.rotation.y + PI

	# Capture mouse for camera control
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Enable gun
	paintball_gun.visible = true
	paintball_gun.enabled = true

func _enter_vehicle() -> void:
	current_state = State.DRIVING

	# Move player visual back to cart
	if player_visual:
		var vis = player_visual
		if vis.get_parent():
			vis.get_parent().remove_child(vis)
		go_kart.add_child(vis)
		vis.position = Vector3(0, 0, 0.15)
		vis.rotation = Vector3.ZERO

	# Disable player
	player.set_physics_process(false)
	player.visible = false
	player.global_position = Vector3(0, -100, 0)

	# Enable cart input
	go_kart.player_driving = true

	# Release mouse for driving
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Disable gun
	paintball_gun.visible = false
	paintball_gun.enabled = false
