extends CanvasLayer
## HUD display — speed, drift indicator, ammo, crosshair, vehicle prompt, controls.

@onready var speed_label: Label = $SpeedLabel
@onready var mph_label: Label = $MphLabel
@onready var drift_label: Label = $DriftLabel
@onready var controls_label: Label = $ControlsLabel
@onready var vehicle_prompt: Label = $VehiclePrompt
@onready var crosshair: Label = $Crosshair
@onready var ammo_label: Label = $AmmoLabel

func update_hud(is_driving: bool, speed: float, is_drifting: bool, near_vehicle: bool, ammo: int = 0) -> void:
	if is_driving:
		speed_label.visible = true
		mph_label.visible = true
		speed_label.text = str(int(abs(speed) * Config.hud_mph_multiplier))
		drift_label.visible = is_drifting
		controls_label.text = "WASD / Left Stick — Steer\nW/S / RT/LT — Gas/Brake\nSPACE / A — Drift\nE / Y — Exit Cart"
		vehicle_prompt.visible = false
		crosshair.visible = false
		ammo_label.visible = false
	else:
		speed_label.visible = false
		mph_label.visible = false
		drift_label.visible = false
		controls_label.text = "WASD / Left Stick — Move\nSPACE / A — Jump\nLMB / RT — Shoot\nRight Stick — Aim\nE / Y — Enter Cart"
		vehicle_prompt.visible = near_vehicle
		crosshair.visible = true
		ammo_label.visible = true
		ammo_label.text = "PAINTBALLS: " + str(ammo)
