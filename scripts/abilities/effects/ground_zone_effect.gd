class_name GroundZoneEffect
extends RefCounted
## params: radius, duration, status, status_duration, conductive


static func execute(caster: Combatant, aim: Vector2, ab: AbilityData) -> bool:
	var offset := (aim - caster.global_position).limit_length(ab.max_range)
	var pos := caster.global_position + offset
	pos = pos.clamp(caster.bounds.position, caster.bounds.end)
	var zone := GroundZone.new()
	zone.setup(ab)
	caster.get_parent().add_child(zone)
	zone.global_position = pos
	return true
