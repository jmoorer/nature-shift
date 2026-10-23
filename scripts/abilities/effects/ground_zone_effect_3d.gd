class_name GroundZoneEffect3D
extends RefCounted
## 3D version of GroundZoneEffect. Pool lands on the floor under the aim point.


static func execute(caster: Combatant3D, aim: Vector3, ab: AbilityData) -> bool:
	var offset := Vector3(aim.x - caster.global_position.x, 0.0, aim.z - caster.global_position.z).limit_length(ab.max_range)
	var pos := caster.global_position + offset
	pos.x = clampf(pos.x, caster.bounds.position.x, caster.bounds.end.x)
	pos.z = clampf(pos.z, caster.bounds.position.y, caster.bounds.end.y)
	pos.y = 0.0
	var zone := GroundZone3D.new()
	zone.setup(ab)
	caster.get_parent().add_child(zone)
	zone.global_position = pos
	return true
