class_name Bolt3D
extends Node3D
## 3D Bolt: same reaction rules as bolt.gd, distances on the XZ plane.

var velocity := Vector3.ZERO
var ability: AbilityData
var shooter: Combatant3D
var hit_radius := 0.25
var _life := 1.0
var _zones_hit := []
var _done := false


func setup(from: Combatant3D, dir: Vector3, ab: AbilityData) -> void:
	shooter = from
	ability = ab
	velocity = dir * ab.params.speed
	_life = ab.max_range / ab.params.speed


func _ready() -> void:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = hit_radius
	s.height = hit_radius * 2.0
	m.mesh = s
	m.material_override = Visuals.mat(Color(1.0, 0.95, 0.4), 4.0, true)
	add_child(m)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.95, 0.4)
	l.omni_range = 4.0
	add_child(l)


func _process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	if _done:
		return
	global_position += velocity * delta
	_life -= delta
	var flat := Vector2(global_position.x, global_position.z)
	for z in get_tree().get_nodes_in_group("zones"):
		if z.conductive and not z.shocked and not _zones_hit.has(z) and z.contains(global_position):
			_zones_hit.append(z)
			_electrify(z)
	for c in get_tree().get_nodes_in_group("combatants"):
		if c.faction != shooter.faction and not c.health.is_dead() \
				and flat.distance_to(c.flat_pos()) <= c.radius + hit_radius:
			_hit(c)
			return
	if _life <= 0.0 or not shooter.bounds.has_point(flat):
		_done = true
		get_tree().call_group("hud", "toast", "%s missed" % ability.display_name, Color(0.7, 0.7, 0.7))
		queue_free()


func _hit(target: Combatant3D) -> void:
	_done = true
	var dmg: float = ability.params.damage
	var wet := target.status.has(Statuses.WET)
	if wet:
		dmg *= ability.params.get("wet_multiplier", 1.0)
	target.receive_damage(dmg, "lightning")
	if wet:
		for z in get_tree().get_nodes_in_group("zones"):
			if z.contains(target.global_position):
				_electrify(z)
	queue_free()


func _electrify(zone: GroundZone3D) -> void:
	zone.electrify(ability.params.conduct_damage, ability.params.conduct_stun)
