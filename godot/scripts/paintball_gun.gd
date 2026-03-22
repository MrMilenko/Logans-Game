extends Node3D
## Paintball gun — handles firing, ammo, and empty-click feedback.

const PAINTBALL_SCENE = preload("res://scenes/weapons/paintball.tscn")

var ammo: int = 50
var fire_cooldown: float = 0.0
var empty_click_cooldown: float = 0.0

# Cache the gun body material for flash restore
var _default_gun_mat: StandardMaterial3D
var _flash_gun_mat: StandardMaterial3D

func _ready() -> void:
	ammo = Config.paintball_start_ammo

	_default_gun_mat = StandardMaterial3D.new()
	_default_gun_mat.albedo_color = Color(0.3, 0.3, 0.8)
	_default_gun_mat.roughness = 0.5
	_default_gun_mat.metallic = 0.2

	_flash_gun_mat = StandardMaterial3D.new()
	_flash_gun_mat.albedo_color = Color(1, 0.2, 0.2)
	_flash_gun_mat.roughness = 0.5

func _process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	empty_click_cooldown = maxf(0.0, empty_click_cooldown - delta)

var enabled: bool = false

func fire(direction: Vector3, origin: Vector3) -> bool:
	if not enabled or fire_cooldown > 0.0:
		return false

	if ammo <= 0:
		# Empty click — flash gun red
		if empty_click_cooldown <= 0:
			empty_click_cooldown = 0.3
			var gun_body = get_node_or_null("GunBody")
			if gun_body:
				gun_body.material_override = _flash_gun_mat
				get_tree().create_timer(0.15).timeout.connect(func():
					if gun_body:
						gun_body.material_override = _default_gun_mat
				)
		return false

	fire_cooldown = Config.paintball_fire_rate
	ammo -= 1

	var paintball = PAINTBALL_SCENE.instantiate()
	get_tree().root.add_child(paintball)
	paintball.global_position = origin + direction * 0.8 + Vector3(0, 0.7, 0)
	paintball.linear_velocity = direction.normalized() * Config.paintball_muzzle_speed + Vector3(0, Config.paintball_upward_arc, 0)

	return true

func refill(amount: int = 50) -> void:
	ammo = mini(ammo + amount, Config.paintball_max_ammo)
