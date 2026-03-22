extends RigidBody3D
## Paintball projectile — flies, splatters on impact, knocks stuff around.

const SPLAT_COLORS: Array[Color] = [
	Color(1, 0.2, 0.6),    # pink
	Color(0.2, 0.6, 1),    # blue
	Color(0.2, 1, 0.4),    # green
	Color(1, 0.9, 0.2),    # yellow
	Color(1, 0.5, 0.1),    # orange
	Color(0.7, 0.2, 1),    # purple
]

var paint_color: Color = Color.WHITE
var has_hit: bool = false

func _ready() -> void:
	paint_color = SPLAT_COLORS[randi() % SPLAT_COLORS.size()]

	var mesh_inst = $MeshInstance3D
	if mesh_inst:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = paint_color
		mat.roughness = 0.3
		mat.emission_enabled = true
		mat.emission = paint_color * 0.3
		mesh_inst.material_override = mat

	body_entered.connect(_on_body_entered)

	# Auto-delete after 3 seconds
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func _on_body_entered(body: Node) -> void:
	if has_hit:
		return
	has_hit = true

	var hit_pos = global_position if is_inside_tree() else position

	# Get contact normal from physics state
	var contact_normal = Vector3.UP
	var state = PhysicsServer3D.body_get_direct_state(get_rid())
	if state and state.get_contact_count() > 0:
		contact_normal = state.get_contact_local_normal(0)

	_spawn_splat(hit_pos, contact_normal)

	# Knockback on dynamic bodies
	if body is RigidBody3D:
		var dir = (body.global_position - hit_pos).normalized()
		body.apply_central_impulse(dir * Config.paintball_knockback)

	# Hit NPC — make them flee
	if body.has_method("flee"):
		body.flee(hit_pos)

	queue_free()

func _spawn_splat(hit_pos: Vector3, surface_normal: Vector3) -> void:
	var splat = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = Config.splat_size * (0.7 + randf() * 0.6)
	mesh.bottom_radius = mesh.top_radius
	mesh.height = 0.02
	mesh.radial_segments = 10
	splat.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = paint_color
	mat.roughness = 0.9
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	splat.material_override = mat

	get_tree().root.add_child(splat)
	splat.global_position = hit_pos

	# Orient splat to match the surface it hit
	if surface_normal.length() > 0.1:
		# Align the disc's Y-axis (up) with the surface normal
		var up = surface_normal.normalized()

		# Find a perpendicular vector for the basis
		var right: Vector3
		if absf(up.dot(Vector3.UP)) < 0.99:
			right = up.cross(Vector3.UP).normalized()
		else:
			right = up.cross(Vector3.FORWARD).normalized()
		var forward = right.cross(up).normalized()

		splat.global_transform.basis = Basis(right, up, forward)

		# Offset slightly from surface to prevent z-fighting
		splat.global_position += up * 0.02

	# Track splats for cleanup
	splat.add_to_group("splats")
	var splats = splat.get_tree().get_nodes_in_group("splats")
	while splats.size() > Config.splat_max_count:
		var oldest = splats[0]
		splats.remove_at(0)
		oldest.queue_free()

	# Fade and delete
	var tween = splat.create_tween()
	tween.tween_interval(Config.splat_lifetime)
	tween.tween_property(mat, "albedo_color:a", 0.0, Config.splat_fade_duration)
	tween.tween_callback(splat.queue_free)
