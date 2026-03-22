extends Node3D
## Procedural suburb generator using Kenney asset packs.
## Builds roads, houses, trees, props, NPCs, and world boundaries.

# ========== KENNEY MODEL PRELOADS ==========
# Suburban buildings (21 types)
var building_scenes: Array[PackedScene] = []
var tree_scenes: Array[PackedScene] = []
var fence_scenes: Array[PackedScene] = []
var driveway_scenes: Array[PackedScene] = []

# ========== MATERIALS ==========
var mat_road: StandardMaterial3D
var mat_road_line: StandardMaterial3D
var mat_sidewalk: StandardMaterial3D
var mat_grass: StandardMaterial3D
var mat_mailbox: StandardMaterial3D
var mat_mailbox_post: StandardMaterial3D
var mat_trash_can: StandardMaterial3D
var mat_ramp: StandardMaterial3D
var mat_boundary_fence: StandardMaterial3D
var mat_boundary_post: StandardMaterial3D

const NPC_SCENE = preload("res://scenes/npc/npc.tscn")

func _ready() -> void:
	_load_kenney_models()
	_init_materials()
	_build_world()
	_spawn_npcs()

# ========== MODEL LOADING ==========
func _load_kenney_models() -> void:
	# Load all building types (a through u)
	var letters = "abcdefghijklmnopqrstu"
	for letter in letters:
		var path = "res://assets/kenney/suburban/building-type-%s.glb" % letter
		if ResourceLoader.exists(path):
			building_scenes.append(load(path))

	# Trees
	for tree_name in ["tree-large", "tree-small"]:
		var path = "res://assets/kenney/suburban/%s.glb" % tree_name
		if ResourceLoader.exists(path):
			tree_scenes.append(load(path))

	# Fences
	for fence_name in ["fence", "fence-low", "fence-1x2", "fence-1x3"]:
		var path = "res://assets/kenney/suburban/%s.glb" % fence_name
		if ResourceLoader.exists(path):
			fence_scenes.append(load(path))

	# Driveways
	for dw_name in ["driveway-short", "driveway-long"]:
		var path = "res://assets/kenney/suburban/%s.glb" % dw_name
		if ResourceLoader.exists(path):
			driveway_scenes.append(load(path))

	print("Loaded: %d buildings, %d trees, %d fences, %d driveways" % [
		building_scenes.size(), tree_scenes.size(),
		fence_scenes.size(), driveway_scenes.size()
	])

# ========== MATERIALS ==========
func _make_mat(color: Color, roughness: float = 0.8) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

func _init_materials() -> void:
	mat_road = _make_mat(Color(0.25, 0.25, 0.27), 0.95)
	mat_road_line = _make_mat(Color(0.96, 0.83, 0.26), 0.8)
	mat_sidewalk = _make_mat(Color(0.78, 0.76, 0.71), 0.9)
	mat_grass = _make_mat(Color(0.32, 0.58, 0.28), 0.95)
	mat_mailbox = _make_mat(Color(0.133, 0.333, 0.733), 0.7)
	mat_mailbox_post = _make_mat(Color(0.545, 0.455, 0.333), 0.8)
	mat_trash_can = _make_mat(Color(0.2, 0.38, 0.2), 0.7)
	mat_ramp = _make_mat(Color(1.0, 0.8, 0.0), 0.6)
	mat_boundary_fence = _make_mat(Color(0.6, 0.6, 0.6, 0.7), 0.5)
	mat_boundary_fence.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_boundary_post = _make_mat(Color(0.4, 0.4, 0.4), 0.6)

# ========== HELPERS ==========
func _add_mesh(parent: Node3D, mesh: Mesh, material: StandardMaterial3D, pos := Vector3.ZERO, rot := Vector3.ZERO, shadow := true) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = MeshInstance3D.SHADOW_CASTING_SETTING_ON if shadow else MeshInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

func _add_static_collider(parent: Node3D, shape: Shape3D, pos := Vector3.ZERO) -> StaticBody3D:
	var sb = StaticBody3D.new()
	sb.position = pos
	var col = CollisionShape3D.new()
	col.shape = shape
	sb.add_child(col)
	parent.add_child(sb)
	return sb

# ========== WORLD BUILDING ==========
func _build_world() -> void:
	var block_size := Config.world_block_size
	var grid_size := Config.world_grid_size
	var road_width := Config.world_road_width
	var sw_width := Config.world_sidewalk_width
	var sw_height := Config.world_sidewalk_height
	var world_size := block_size * grid_size + road_width
	var half_world := world_size / 2.0

	_build_ground(world_size, half_world)
	_build_roads(grid_size, block_size, road_width, world_size, half_world)
	_build_blocks(grid_size, block_size, road_width, sw_width, sw_height, half_world)
	_build_props(grid_size, block_size, road_width, sw_width, sw_height, world_size, half_world)
	_build_ramps(block_size)
	_build_fences(grid_size, block_size, road_width, sw_height, half_world)
	_build_world_boundaries(half_world, world_size)

func _build_ground(world_size: float, half_world: float) -> void:
	var ground_mesh = PlaneMesh.new()
	ground_mesh.size = Vector2(world_size + 40, world_size + 40)
	_add_mesh(self, ground_mesh, mat_grass)

	var ground_shape = BoxShape3D.new()
	ground_shape.size = Vector3(world_size + 40, 0.2, world_size + 40)
	_add_static_collider(self, ground_shape, Vector3(0, -0.1, 0))

func _build_roads(grid_size: int, block_size: float, road_width: float, world_size: float, half_world: float) -> void:
	for i in range(grid_size + 1):
		var pos_v = -half_world + road_width / 2.0 + i * block_size

		# Horizontal road
		var h_road = PlaneMesh.new()
		h_road.size = Vector2(world_size + 20, road_width)
		_add_mesh(self, h_road, mat_road, Vector3(0, 0.01, pos_v))

		# Center line
		var h_line = PlaneMesh.new()
		h_line.size = Vector2(world_size + 20, 0.15)
		_add_mesh(self, h_line, mat_road_line, Vector3(0, 0.02, pos_v), Vector3.ZERO, false)

		# Vertical road
		var v_road = PlaneMesh.new()
		v_road.size = Vector2(road_width, world_size + 20)
		_add_mesh(self, v_road, mat_road, Vector3(pos_v, 0.01, 0))

		var v_line = PlaneMesh.new()
		v_line.size = Vector2(0.15, world_size + 20)
		_add_mesh(self, v_line, mat_road_line, Vector3(pos_v, 0.02, 0), Vector3.ZERO, false)

func _build_blocks(grid_size: int, block_size: float, road_width: float, sw_width: float, sw_height: float, half_world: float) -> void:
	var inner_size = block_size - road_width

	for bx in range(grid_size):
		for bz in range(grid_size):
			var block_x = -half_world + road_width + bx * block_size
			var block_z = -half_world + road_width + bz * block_size

			# Sidewalk
			var sw_mesh = PlaneMesh.new()
			sw_mesh.size = Vector2(inner_size + sw_width * 2, inner_size + sw_width * 2)
			_add_mesh(self, sw_mesh, mat_sidewalk, Vector3(block_x + inner_size / 2.0, sw_height, block_z + inner_size / 2.0))

			# Inner grass
			var ig_mesh = PlaneMesh.new()
			ig_mesh.size = Vector2(inner_size - sw_width * 2, inner_size - sw_width * 2)
			_add_mesh(self, ig_mesh, mat_grass, Vector3(block_x + inner_size / 2.0, sw_height + 0.01, block_z + inner_size / 2.0))

			# Center park area with trees
			var center = Vector3(block_x + inner_size / 2.0, sw_height, block_z + inner_size / 2.0)
			for t in range(randi_range(2, 4)):
				var tree_pos = center + Vector3(randf_range(-6, 6), 0, randf_range(-4, 4))
				_spawn_tree(tree_pos)

			# Planter in center (if Kenney planter available)
			var planter_path = "res://assets/kenney/suburban/planter.glb"
			if ResourceLoader.exists(planter_path):
				var planter = load(planter_path).instantiate()
				planter.position = center
				planter.scale = Vector3(5.0, 5.0, 5.0)
				add_child(planter)

			# Houses on 2 opposite sides only (avoids center overlap)
			# North and south sides of each block
			var houses_per_side = 2  # fewer but bigger with Kenney models
			var lot_width = inner_size / houses_per_side

			for side in [0, 1]:  # south and north only
				for h in range(houses_per_side):
					_spawn_house(block_x, block_z, inner_size, lot_width, side, h, sw_width, sw_height)

func _spawn_house(block_x: float, block_z: float, inner_size: float, lot_width: float, side: int, h: int, sw_width: float, sw_height: float) -> void:
	var setback = sw_width + 6.0  # enough room for 7x scaled Kenney models
	var lot_offset = (h + 0.5) * lot_width
	var hx: float
	var hz: float
	var rot_y: float = 0.0

	match side:
		0:  # south
			hx = block_x + lot_offset; hz = block_z + inner_size - setback; rot_y = PI
		1:  # north
			hx = block_x + lot_offset; hz = block_z + setback; rot_y = 0
		2:  # west
			hx = block_x + setback; hz = block_z + lot_offset; rot_y = PI / 2
		3:  # east
			hx = block_x + inner_size - setback; hz = block_z + lot_offset; rot_y = -PI / 2

	# Spawn Kenney building model (random type)
	if building_scenes.size() > 0:
		var building = building_scenes[randi() % building_scenes.size()].instantiate()
		building.position = Vector3(hx, sw_height, hz)
		building.rotation.y = rot_y
		# Kenney buildings are ~1.3 units wide, lots are ~7-10 units
		# Scale 7x to fill lots properly
		building.scale = Vector3(7.0, 7.0, 7.0)
		add_child(building)

		# Generate collision from mesh — find the first MeshInstance3D and create trimesh
		var collision_added = false
		for child in building.get_children():
			if child is MeshInstance3D and child.mesh and not collision_added:
				var static_body = StaticBody3D.new()
				static_body.position = Vector3(hx, sw_height, hz)
				static_body.rotation.y = rot_y
				static_body.scale = Vector3(7.0, 7.0, 7.0)
				var col = CollisionShape3D.new()
				# Use convex shape for better performance than trimesh
				var shape = child.mesh.create_convex_shape()
				col.shape = shape
				static_body.add_child(col)
				add_child(static_body)
				collision_added = true
		if not collision_added:
			# Fallback box
			var col_shape = BoxShape3D.new()
			col_shape.size = Vector3(9.0, 6.0, 7.0)
			_add_static_collider(self, col_shape, Vector3(hx, sw_height + 3.0, hz))
	else:
		# Fallback: procedural box house
		_spawn_procedural_house(hx, hz, sw_height, lot_width, rot_y)

	# Tree in front yard
	if randf() > 0.3:
		var tx = hx + randf_range(-lot_width * 0.3, lot_width * 0.3)
		var tz = hz
		match side:
			0: tz = hz + randf_range(3, 5)
			1: tz = hz - randf_range(3, 5)
			2: tx = hx - randf_range(3, 5); tz = hz + randf_range(-2, 2)
			3: tx = hx + randf_range(3, 5); tz = hz + randf_range(-2, 2)
		_spawn_tree(Vector3(tx, sw_height, tz))

	# Driveway
	if driveway_scenes.size() > 0 and randf() > 0.4:
		var dw = driveway_scenes[randi() % driveway_scenes.size()].instantiate()
		dw.position = Vector3(hx, sw_height + 0.01, hz)
		dw.rotation.y = rot_y
		dw.scale = Vector3(5.0, 5.0, 5.0)
		add_child(dw)

func _spawn_procedural_house(hx: float, hz: float, sw_height: float, lot_width: float, rot_y: float) -> void:
	## Fallback if Kenney models aren't loaded
	var house_width = lot_width * 0.7
	var house_height = randf_range(3.5, 5.5)
	var house_depth = randf_range(4, 6)
	var colors = [Color(0.94, 0.90, 0.83), Color(0.71, 0.83, 0.91), Color(0.96, 0.90, 0.64),
				  Color(0.91, 0.71, 0.71), Color(0.77, 0.91, 0.71), Color(0.91, 0.84, 0.94)]
	var house_mat = _make_mat(colors[randi() % colors.size()])

	var group = Node3D.new()
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(house_width, house_height, house_depth)
	_add_mesh(group, body_mesh, house_mat, Vector3(0, house_height / 2.0, 0))

	var roof_mesh = CylinderMesh.new()
	roof_mesh.top_radius = 0.0
	roof_mesh.bottom_radius = house_width * 0.75
	roof_mesh.height = house_height * 0.4
	roof_mesh.radial_segments = 4
	_add_mesh(group, roof_mesh, _make_mat(Color(0.545, 0.271, 0.075), 0.85),
		Vector3(0, house_height + house_height * 0.2, 0), Vector3(0, PI / 4, 0))

	group.position = Vector3(hx, sw_height, hz)
	group.rotation.y = rot_y
	add_child(group)

	var total_height = house_height + house_height * 0.4
	var col_shape = BoxShape3D.new()
	col_shape.size = Vector3(house_width, total_height, house_depth)
	_add_static_collider(self, col_shape, Vector3(hx, sw_height + total_height / 2.0, hz))

func _spawn_tree(pos: Vector3) -> void:
	if tree_scenes.size() > 0:
		var tree = tree_scenes[randi() % tree_scenes.size()].instantiate()
		tree.position = pos
		tree.scale = Vector3(4.0, 4.0, 4.0) * randf_range(0.8, 1.3)
		tree.rotation.y = randf() * TAU
		add_child(tree)

		# Trunk collision
		var trunk_shape = CylinderShape3D.new()
		trunk_shape.radius = 0.3
		trunk_shape.height = 3.0
		_add_static_collider(self, trunk_shape, pos + Vector3(0, 1.5, 0))
	else:
		# Fallback procedural tree
		var trunk_height = randf_range(1.5, 3.0)
		var canopy_radius = randf_range(1.2, 2.0)
		var trunk_mesh = CylinderMesh.new()
		trunk_mesh.top_radius = 0.15; trunk_mesh.bottom_radius = 0.2; trunk_mesh.height = trunk_height
		_add_mesh(self, trunk_mesh, _make_mat(Color(0.42, 0.26, 0.15), 0.9), pos + Vector3(0, trunk_height / 2.0, 0))

		var canopy_mesh = CylinderMesh.new()
		canopy_mesh.top_radius = 0.0; canopy_mesh.bottom_radius = canopy_radius; canopy_mesh.height = canopy_radius * 2
		_add_mesh(self, canopy_mesh, _make_mat(Color(0.18, 0.49, 0.18), 0.9), pos + Vector3(0, trunk_height + canopy_radius * 0.7, 0))

		var trunk_shape = CylinderShape3D.new()
		trunk_shape.radius = 0.2; trunk_shape.height = trunk_height
		_add_static_collider(self, trunk_shape, pos + Vector3(0, trunk_height / 2.0, 0))

func _build_props(grid_size: int, block_size: float, road_width: float, sw_width: float, sw_height: float, world_size: float, half_world: float) -> void:
	for i in range(grid_size + 1):
		var road_pos = -half_world + road_width / 2.0 + i * block_size
		for j in range(8):
			var along = -half_world + 10 + j * (world_size / 8.0)
			if randf() > 0.4:
				_spawn_mailbox(Vector3(road_pos + road_width / 2.0 + sw_width * 0.6, sw_height, along))
			if randf() > 0.5:
				_spawn_trash_can(Vector3(along, sw_height, road_pos + road_width / 2.0 + sw_width * 0.6))

func _spawn_mailbox(pos: Vector3) -> void:
	var rb = RigidBody3D.new()
	rb.mass = 3.0
	rb.linear_damp = 0.15
	rb.angular_damp = 0.15
	rb.position = pos + Vector3(0, 0.65, 0)

	var post_mesh = CylinderMesh.new()
	post_mesh.top_radius = 0.06; post_mesh.bottom_radius = 0.06; post_mesh.height = 1.0
	_add_mesh(rb, post_mesh, mat_mailbox_post, Vector3(0, -0.15, 0))

	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.4, 0.3, 0.25)
	_add_mesh(rb, box_mesh, mat_mailbox, Vector3(0, 0.4, 0))

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.4, 1.3, 0.25)
	col.shape = shape
	rb.add_child(col)
	add_child(rb)

func _spawn_trash_can(pos: Vector3) -> void:
	var rb = RigidBody3D.new()
	rb.mass = 2.0
	rb.linear_damp = 0.15
	rb.angular_damp = 0.15
	rb.position = pos + Vector3(0, 0.4, 0)

	var can_mesh = CylinderMesh.new()
	can_mesh.top_radius = 0.25; can_mesh.bottom_radius = 0.3; can_mesh.height = 0.8
	can_mesh.radial_segments = 12
	_add_mesh(rb, can_mesh, mat_trash_can)

	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.3; shape.height = 0.8
	col.shape = shape
	rb.add_child(col)
	add_child(rb)

func _build_ramps(block_size: float) -> void:
	_spawn_ramp(Vector3(0, 0.01, 0), 0)
	_spawn_ramp(Vector3(block_size * 0.8, 0.01, -block_size * 0.5), PI / 4)
	_spawn_ramp(Vector3(-block_size * 0.7, 0.01, block_size * 0.6), -PI / 3)

func _spawn_ramp(pos: Vector3, rot_y: float) -> void:
	var ramp = StaticBody3D.new()
	ramp.position = pos
	ramp.rotation.y = rot_y

	# Collision wedge
	var col = CollisionShape3D.new()
	var shape = ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array([
		Vector3(-1.5, 0, -1.5), Vector3(1.5, 0, -1.5),
		Vector3(1.5, 0, 1.5), Vector3(-1.5, 0, 1.5),
		Vector3(-1.5, 0.8, 1.5), Vector3(1.5, 0.8, 1.5),
	])
	col.shape = shape
	ramp.add_child(col)

	# Visual — use a simple box tilted as the ramp surface
	var ramp_mesh = BoxMesh.new()
	ramp_mesh.size = Vector3(3.0, 0.12, 3.4)
	var mi = MeshInstance3D.new()
	mi.mesh = ramp_mesh
	mi.material_override = mat_ramp
	mi.position = Vector3(0, 0.4, 0)
	mi.rotation.x = -0.26  # tilt to match wedge slope
	mi.cast_shadow = MeshInstance3D.SHADOW_CASTING_SETTING_ON
	ramp.add_child(mi)

	# Dark stripes
	var stripe_mat = _make_mat(Color(0.15, 0.15, 0.15), 0.7)
	for s in range(4):
		var stripe = MeshInstance3D.new()
		var stripe_mesh = BoxMesh.new()
		stripe_mesh.size = Vector3(2.8, 0.02, 0.1)
		stripe.mesh = stripe_mesh
		stripe.material_override = stripe_mat
		stripe.position = Vector3(0, 0.13 + s * 0.17, -0.9 + s * 0.6)
		stripe.rotation.x = -0.26
		ramp.add_child(stripe)

	add_child(ramp)

func _build_fences(grid_size: int, block_size: float, road_width: float, sw_height: float, half_world: float) -> void:
	var inner_size = block_size - road_width

	for bx in range(grid_size):
		for bz in range(grid_size):
			var bx_pos = -half_world + road_width + bx * block_size
			var bz_pos = -half_world + road_width + bz * block_size

			if randf() > 0.5:
				_spawn_fence(Vector3(bx_pos + inner_size * 0.33, sw_height, bz_pos + Config.world_sidewalk_width + 1), randf_range(3, 6))
			if randf() > 0.5:
				_spawn_fence(Vector3(bx_pos + inner_size * 0.67, sw_height, bz_pos + inner_size - Config.world_sidewalk_width - 1), randf_range(3, 6))

func _spawn_fence(pos: Vector3, length: float) -> void:
	if fence_scenes.size() > 0:
		# Use Kenney fence model
		var fence = fence_scenes[randi() % fence_scenes.size()].instantiate()
		fence.position = pos
		fence.scale = Vector3(4.0, 4.0, 4.0)
		add_child(fence)

		var col_shape = BoxShape3D.new()
		col_shape.size = Vector3(length, 1.0, 0.15)
		_add_static_collider(self, col_shape, pos + Vector3(0, 0.5, 0))
	else:
		# Fallback procedural fence
		var fence = StaticBody3D.new()
		fence.position = pos
		var rail_mesh = BoxMesh.new()
		rail_mesh.size = Vector3(length, 0.8, 0.08)
		_add_mesh(fence, rail_mesh, _make_mat(Color.WHITE, 0.8), Vector3(0, 0.4, 0))

		for fp in [-1, 1]:
			var post_mesh = BoxMesh.new()
			post_mesh.size = Vector3(0.08, 1.0, 0.08)
			_add_mesh(fence, post_mesh, _make_mat(Color.WHITE, 0.8), Vector3(fp * length / 2.0, 0.5, 0))

		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(length, 1.0, 0.15)
		col.shape = shape
		col.position.y = 0.5
		fence.add_child(col)
		add_child(fence)

func _build_world_boundaries(half_world: float, world_size: float) -> void:
	var wall_height := 5.0
	var boundary := half_world + 15.0

	# Invisible collision walls
	var sides = [
		Vector3(0, wall_height / 2.0, boundary),
		Vector3(0, wall_height / 2.0, -boundary),
		Vector3(boundary, wall_height / 2.0, 0),
		Vector3(-boundary, wall_height / 2.0, 0),
	]
	var sizes = [
		Vector3(boundary * 2, wall_height, 1.0),
		Vector3(boundary * 2, wall_height, 1.0),
		Vector3(1.0, wall_height, boundary * 2),
		Vector3(1.0, wall_height, boundary * 2),
	]

	for i in range(4):
		var wall = StaticBody3D.new()
		wall.position = sides[i]
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = sizes[i]
		col.shape = shape
		wall.add_child(col)
		add_child(wall)

	# Visible boundary fence
	var fence_height := 2.0
	var fence_positions = [
		[Vector3(0, fence_height / 2.0, boundary - 0.5), Vector3(boundary * 2, fence_height, 0.1)],
		[Vector3(0, fence_height / 2.0, -boundary + 0.5), Vector3(boundary * 2, fence_height, 0.1)],
		[Vector3(boundary - 0.5, fence_height / 2.0, 0), Vector3(0.1, fence_height, boundary * 2)],
		[Vector3(-boundary + 0.5, fence_height / 2.0, 0), Vector3(0.1, fence_height, boundary * 2)],
	]
	for fp in fence_positions:
		var fence_mesh = BoxMesh.new()
		fence_mesh.size = fp[1]
		_add_mesh(self, fence_mesh, mat_boundary_fence, fp[0])

	# Corner posts
	for cx in [-1, 1]:
		for cz in [-1, 1]:
			var post_mesh = CylinderMesh.new()
			post_mesh.top_radius = 0.1; post_mesh.bottom_radius = 0.12; post_mesh.height = fence_height + 0.5
			_add_mesh(self, post_mesh, mat_boundary_post,
				Vector3(cx * (boundary - 0.5), (fence_height + 0.5) / 2.0, cz * (boundary - 0.5)))

# ========== NPC SPAWNING ==========
func _spawn_npcs() -> void:
	var block_size := Config.world_block_size
	var grid_size := Config.world_grid_size
	var road_width := Config.world_road_width
	var world_size := block_size * grid_size + road_width
	var half_world := world_size / 2.0
	var sw_height := Config.world_sidewalk_height

	# Dads washing cars — near houses
	for bx in range(grid_size):
		for bz in range(grid_size):
			if randf() > 0.5:
				continue
			var pos = Vector3(
				-half_world + road_width + bx * block_size + randf_range(5, 25),
				sw_height + 0.1,
				-half_world + road_width + bz * block_size + randf_range(5, 25))
			_spawn_npc(pos, 0)  # DAD_WASHING_CAR

	# Moms gardening
	for i in range(4):
		_spawn_npc(Vector3(randf_range(-half_world + 15, half_world - 15), sw_height + 0.1,
			randf_range(-half_world + 15, half_world - 15)), 4)

	# Kids on bikes — on roads
	for i in range(5):
		var road_idx = randi() % (grid_size + 1)
		var road_pos = -half_world + road_width / 2.0 + road_idx * block_size
		var along = randf_range(-half_world + 10, half_world - 10)
		if randi() % 2 == 0:
			_spawn_npc(Vector3(road_pos + 2, sw_height + 0.1, along), 1)
		else:
			_spawn_npc(Vector3(along, sw_height + 0.1, road_pos + 2), 1)

	# Dogs roaming
	for i in range(6):
		_spawn_npc(Vector3(randf_range(-half_world + 10, half_world - 10), sw_height + 0.1,
			randf_range(-half_world + 10, half_world - 10)), 2)

	# Walking neighbors
	for i in range(8):
		_spawn_npc(Vector3(randf_range(-half_world + 10, half_world - 10), sw_height + 0.1,
			randf_range(-half_world + 10, half_world - 10)), 3)

func _spawn_npc(pos: Vector3, type_idx: int) -> void:
	var npc = NPC_SCENE.instantiate()
	npc.npc_type = type_idx
	npc.position = pos
	add_child(npc)
