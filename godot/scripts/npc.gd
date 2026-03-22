extends CharacterBody3D

enum NPCType { DAD_WASHING_CAR, KID_ON_BIKE, DOG, WALKING_NEIGHBOR, MOM_GARDENING }
enum AIState { IDLE, WALKING, FLEEING }

@export var npc_type: NPCType = NPCType.WALKING_NEIGHBOR

## Uses Config values: npc_walk_speed, npc_flee_speed, npc_flee_distance, npc_hit_flash_time, player_gravity

var ai_state: AIState = AIState.IDLE
var move_direction: Vector3 = Vector3.ZERO
var idle_timer: float = 0.0
var walk_timer: float = 0.0
var flee_from: Vector3 = Vector3.ZERO
var hit_flash_timer: float = 0.0
var home_position: Vector3 = Vector3.ZERO

# Visual
var body_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var hat_mesh: MeshInstance3D

# Colors per type
const TYPE_COLORS = {
	NPCType.DAD_WASHING_CAR: Color(0.2, 0.4, 0.7),      # blue polo
	NPCType.KID_ON_BIKE: Color(1.0, 0.3, 0.3),           # red shirt
	NPCType.DOG: Color(0.6, 0.4, 0.2),                    # brown
	NPCType.WALKING_NEIGHBOR: Color(0.4, 0.7, 0.3),       # green shirt
	NPCType.MOM_GARDENING: Color(0.8, 0.3, 0.6),          # pink
}

const TYPE_SCALES = {
	NPCType.DAD_WASHING_CAR: Vector3(1, 1.1, 1),          # tall
	NPCType.KID_ON_BIKE: Vector3(0.8, 0.75, 0.8),         # small kid
	NPCType.DOG: Vector3(0.5, 0.4, 0.7),                   # low and long
	NPCType.WALKING_NEIGHBOR: Vector3(1, 1, 1),            # normal
	NPCType.MOM_GARDENING: Vector3(0.9, 0.95, 0.9),       # slightly smaller
}

func _ready() -> void:
	home_position = global_position
	_build_visual()
	_start_idle()

func _build_visual() -> void:
	var color = TYPE_COLORS.get(npc_type, Color.WHITE)
	var npc_scale = TYPE_SCALES.get(npc_type, Vector3.ONE)

	var mat_body = StandardMaterial3D.new()
	mat_body.albedo_color = color
	mat_body.roughness = 0.7

	var mat_skin = StandardMaterial3D.new()
	mat_skin.albedo_color = Color(1, 0.85, 0.7)
	mat_skin.roughness = 0.7

	if npc_type == NPCType.DOG:
		# Dog: elongated body, no head/hat distinction
		var dog_body = BoxMesh.new()
		dog_body.size = Vector3(0.3, 0.25, 0.5) * npc_scale
		body_mesh = MeshInstance3D.new()
		body_mesh.mesh = dog_body
		body_mesh.material_override = mat_body
		body_mesh.position.y = 0.25
		add_child(body_mesh)

		# Dog head
		var dog_head_mesh = BoxMesh.new()
		dog_head_mesh.size = Vector3(0.2, 0.2, 0.2) * npc_scale
		head_mesh = MeshInstance3D.new()
		head_mesh.mesh = dog_head_mesh
		head_mesh.material_override = mat_body
		head_mesh.position = Vector3(0, 0.3, -0.3) * npc_scale
		add_child(head_mesh)

		# Tail
		var tail_mesh_res = BoxMesh.new()
		tail_mesh_res.size = Vector3(0.06, 0.2, 0.06)
		var tail = MeshInstance3D.new()
		tail.mesh = tail_mesh_res
		tail.material_override = mat_body
		tail.position = Vector3(0, 0.35, 0.3) * npc_scale
		tail.rotation.x = -0.5
		add_child(tail)
	else:
		# Humanoid: torso, head, hat
		var torso_mesh = BoxMesh.new()
		torso_mesh.size = Vector3(0.35, 0.45, 0.25) * npc_scale
		body_mesh = MeshInstance3D.new()
		body_mesh.mesh = torso_mesh
		body_mesh.material_override = mat_body
		body_mesh.position.y = 0.55 * npc_scale.y
		body_mesh.cast_shadow = MeshInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(body_mesh)

		# Legs
		var leg_mesh = BoxMesh.new()
		leg_mesh.size = Vector3(0.3, 0.35, 0.22) * npc_scale
		var legs = MeshInstance3D.new()
		legs.mesh = leg_mesh
		var mat_pants = StandardMaterial3D.new()
		mat_pants.albedo_color = Color(0.25, 0.25, 0.35)
		mat_pants.roughness = 0.8
		legs.material_override = mat_pants
		legs.position.y = 0.2 * npc_scale.y
		add_child(legs)

		var head_mesh_res = BoxMesh.new()
		head_mesh_res.size = Vector3(0.25, 0.25, 0.25) * npc_scale
		head_mesh = MeshInstance3D.new()
		head_mesh.mesh = head_mesh_res
		head_mesh.material_override = mat_skin
		head_mesh.position.y = 0.9 * npc_scale.y
		head_mesh.cast_shadow = MeshInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(head_mesh)

		# Hat or hair based on type
		if npc_type == NPCType.DAD_WASHING_CAR:
			var cap = CylinderMesh.new()
			cap.top_radius = 0.16
			cap.bottom_radius = 0.18
			cap.height = 0.1
			hat_mesh = MeshInstance3D.new()
			hat_mesh.mesh = cap
			var mat_hat = StandardMaterial3D.new()
			mat_hat.albedo_color = Color(0.8, 0.2, 0.2)
			hat_mesh.material_override = mat_hat
			hat_mesh.position.y = 1.05 * npc_scale.y
			add_child(hat_mesh)
		elif npc_type == NPCType.MOM_GARDENING:
			var sun_hat = CylinderMesh.new()
			sun_hat.top_radius = 0.25
			sun_hat.bottom_radius = 0.22
			sun_hat.height = 0.08
			hat_mesh = MeshInstance3D.new()
			hat_mesh.mesh = sun_hat
			var mat_hat = StandardMaterial3D.new()
			mat_hat.albedo_color = Color(0.9, 0.85, 0.5)
			hat_mesh.material_override = mat_hat
			hat_mesh.position.y = 1.05 * npc_scale.y
			add_child(hat_mesh)

func _start_idle() -> void:
	ai_state = AIState.IDLE
	idle_timer = randf_range(1.5, 4.0)
	velocity.x = 0
	velocity.z = 0

func _start_walking() -> void:
	ai_state = AIState.WALKING

	if npc_type == NPCType.DOG:
		# Dogs wander more erratically
		var angle = randf() * TAU
		move_direction = Vector3(cos(angle), 0, sin(angle))
		walk_timer = randf_range(1.0, 3.0)
	elif npc_type == NPCType.DAD_WASHING_CAR or npc_type == NPCType.MOM_GARDENING:
		# Stationary types just pace near home
		var to_home = (home_position - global_position)
		to_home.y = 0
		if to_home.length() > 3.0:
			move_direction = to_home.normalized()
		else:
			var angle = randf() * TAU
			move_direction = Vector3(cos(angle), 0, sin(angle))
		walk_timer = randf_range(1.0, 2.0)
	else:
		# Walking neighbor / kid — walk along sidewalks
		var directions = [Vector3(1,0,0), Vector3(-1,0,0), Vector3(0,0,1), Vector3(0,0,-1)]
		move_direction = directions[randi() % 4]
		walk_timer = randf_range(2.0, 5.0)

func flee(from_pos: Vector3) -> void:
	ai_state = AIState.FLEEING
	flee_from = from_pos
	walk_timer = randf_range(3.0, 5.0)

	# Flash paint color on hit — visual feedback
	hit_flash_timer = 0.4
	if body_mesh:
		var flash_mat = StandardMaterial3D.new()
		flash_mat.albedo_color = Color(1, 0.3, 0.8)  # pink paint flash
		flash_mat.roughness = 0.5
		body_mesh.material_override = flash_mat

	# Small jump on hit (surprise!)
	velocity.y = 4.0

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= Config.player_gravity * delta

	match ai_state:
		AIState.IDLE:
			idle_timer -= delta
			velocity.x = move_toward(velocity.x, 0, 10 * delta)
			velocity.z = move_toward(velocity.z, 0, 10 * delta)
			if idle_timer <= 0:
				_start_walking()

		AIState.WALKING:
			walk_timer -= delta
			var spd = Config.npc_walk_speed * 1.5 if npc_type == NPCType.DOG else Config.npc_walk_speed
			if npc_type == NPCType.KID_ON_BIKE:
				spd = Config.npc_walk_speed * 2.0
			velocity.x = move_direction.x * spd
			velocity.z = move_direction.z * spd

			# Face movement direction
			if move_direction.length() > 0.1:
				rotation.y = atan2(move_direction.x, move_direction.z)

			# Don't wander too far from home
			var dist_from_home = (global_position - home_position).length()
			if dist_from_home > 20.0:
				move_direction = (home_position - global_position).normalized()
				move_direction.y = 0

			if walk_timer <= 0:
				_start_idle()

		AIState.FLEEING:
			walk_timer -= delta
			var away = (global_position - flee_from)
			away.y = 0
			if away.length() > 0.1:
				move_direction = away.normalized()
			velocity.x = move_direction.x * Config.npc_flee_speed
			velocity.z = move_direction.z * Config.npc_flee_speed

			if move_direction.length() > 0.1:
				rotation.y = atan2(move_direction.x, move_direction.z)

			if walk_timer <= 0 or (global_position - flee_from).length() > Config.npc_flee_distance:
				_start_idle()

	# Paint flash recovery — restore original color
	if hit_flash_timer > 0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0 and body_mesh:
			var color = TYPE_COLORS.get(npc_type, Color.WHITE)
			var restore_mat = StandardMaterial3D.new()
			restore_mat.albedo_color = color
			restore_mat.roughness = 0.7
			body_mesh.material_override = restore_mat

	move_and_slide()

	# Fall off world
	if global_position.y < -10:
		global_position = home_position + Vector3(0, 1, 0)
		velocity = Vector3.ZERO
		_start_idle()
