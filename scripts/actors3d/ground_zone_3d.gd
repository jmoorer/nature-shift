class_name GroundZone3D
extends Node3D
## 3D GroundZone: same rules (see ground_zone.gd), distances on the XZ plane.

var radius := 2.8
var remaining := 6.0
var status_id := Statuses.WET
var status_duration := 3.0
var conductive := true
var color := Color(0.25, 0.55, 1.0)
var shocked := false
var _fade := 0.0
var _mesh: MeshInstance3D
var _mat: StandardMaterial3D


func setup(ab: AbilityData) -> void:
	radius = ab.params.radius
	remaining = ab.params.duration
	status_id = ab.params.status
	status_duration = ab.params.status_duration
	conductive = ab.params.get("conductive", false)
	color = ab.color


func _ready() -> void:
	add_to_group("zones")
	_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.06
	_mesh.mesh = cyl
	_mesh.position.y = 0.04
	_mat = Visuals.mat(Color(color, 0.45), 0.6, true)
	_mesh.material_override = _mat
	add_child(_mesh)


func contains(p: Vector3) -> bool:
	return Vector2(global_position.x, global_position.z).distance_to(Vector2(p.x, p.z)) <= radius


func occupants() -> Array:
	var out := []
	for c in get_tree().get_nodes_in_group("combatants"):
		if not c.health.is_dead() and contains(c.global_position):
			out.append(c)
	return out


func tick(delta: float) -> void:
	if shocked:
		_fade -= delta
		if _fade <= 0.0:
			queue_free()
		return
	remaining -= delta
	if remaining <= 0.0:
		queue_free()
		return
	for c in occupants():
		c.status.apply(status_id, status_duration)


## Shocks every Wet occupant. Returns how many were hit (0 if not conductive or spent).
func electrify(damage: float, stun: float) -> int:
	if not conductive or shocked:
		return 0
	shocked = true
	_fade = 0.4
	var hits := 0
	for c in occupants():
		if c.status.has(Statuses.WET):
			c.receive_damage(damage, "shock")
			c.status.apply(Statuses.STUNNED, stun)
			hits += 1
	get_tree().call_group("hud", "toast", "CONDUCTED! %d shocked" % hits if hits > 0 else "Pool shocked - nobody inside", Color(1.0, 0.9, 0.3))
	return hits


func _process(delta: float) -> void:
	tick(delta)
	if _mat == null:
		return
	if shocked:
		_mat.albedo_color = Color(1.0, 0.95, 0.3, 0.8 * clampf(_fade / 0.4, 0.0, 1.0))
		_mat.emission = Color(1.0, 0.95, 0.3)
		_mat.emission_energy_multiplier = 3.0
	else:
		_mesh.visible = remaining > 1.5 or int(remaining * 6.0) % 2 == 0
