class_name Bolt
extends Node2D
## Fast projectile. Stops on the first enemy-faction combatant it touches.
## Reaction rules (the Water + Lightning prototype interaction):
##  - passing through a conductive zone electrifies that zone
##  - hitting a Wet target deals extra damage and electrifies any zone it stands in

var velocity := Vector2.ZERO
var ability: AbilityData
var shooter: Combatant
var hit_radius := 8.0
var _life := 1.0
var _zones_hit := []
var _done := false


func setup(from: Combatant, dir: Vector2, ab: AbilityData) -> void:
	shooter = from
	ability = ab
	velocity = dir * ab.params.speed
	_life = ab.max_range / ab.params.speed


func _process(delta: float) -> void:
	step(delta)
	queue_redraw()


func step(delta: float) -> void:
	if _done:
		return
	global_position += velocity * delta
	_life -= delta
	for z in get_tree().get_nodes_in_group("zones"):
		if z.conductive and not z.shocked and not _zones_hit.has(z) and z.contains(global_position):
			_zones_hit.append(z)
			_electrify(z)
	for c in get_tree().get_nodes_in_group("combatants"):
		if c.faction != shooter.faction and not c.health.is_dead() \
				and global_position.distance_to(c.global_position) <= c.radius + hit_radius:
			_hit(c)
			return
	if _life <= 0.0 or not shooter.bounds.has_point(global_position):
		_done = true
		get_tree().call_group("hud", "toast", "%s missed" % ability.display_name, Color(0.7, 0.7, 0.7))
		queue_free()


func _hit(target: Combatant) -> void:
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


func _electrify(zone: GroundZone) -> void:
	zone.electrify(ability.params.conduct_damage, ability.params.conduct_stun)


func _draw() -> void:
	var tail := -velocity.normalized() * 26.0
	draw_line(tail, Vector2.ZERO, Color(1.0, 0.95, 0.4, 0.6), 5.0)
	draw_circle(Vector2.ZERO, hit_radius, Color(1.0, 1.0, 0.6))
