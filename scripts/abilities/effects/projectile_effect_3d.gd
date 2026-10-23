class_name ProjectileEffect3D
extends RefCounted
## 3D version of ProjectileEffect. Flies flat on the XZ plane at chest height.


static func execute(caster: Combatant3D, aim: Vector3, ab: AbilityData) -> bool:
	var dir := Vector3(aim.x - caster.global_position.x, 0.0, aim.z - caster.global_position.z)
	if dir.length() < 0.5:
		dir = caster.facing
	dir = dir.normalized()
	var bolt := Bolt3D.new()
	bolt.setup(caster, dir, ab)
	caster.get_parent().add_child(bolt)
	bolt.global_position = caster.global_position + dir * (caster.radius + 0.4) + Vector3(0, caster.height * 0.6, 0)
	return true
