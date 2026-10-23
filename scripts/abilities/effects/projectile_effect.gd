class_name ProjectileEffect
extends RefCounted
## params: speed, damage, wet_multiplier, conduct_damage, conduct_stun


static func execute(caster: Combatant, aim: Vector2, ab: AbilityData) -> bool:
	var dir := aim - caster.global_position
	if dir.length() < 1.0:
		dir = caster.facing
	dir = dir.normalized()
	var bolt := Bolt.new()
	bolt.setup(caster, dir, ab)
	caster.get_parent().add_child(bolt)
	bolt.global_position = caster.global_position + dir * (caster.radius + 6.0)
	return true
