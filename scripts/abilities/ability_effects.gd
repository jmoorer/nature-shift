class_name AbilityEffects
extends RefCounted
## Effect registry: maps AbilityData.effect ids to reusable implementations.


## `caster` is a Combatant (2D, aim: Vector2) or Combatant3D (3D, aim: Vector3).
static func execute(effect_id: String, caster: Node, aim: Variant, ability: AbilityData) -> bool:
	var is_3d := caster is Node3D
	match effect_id:
		"projectile":
			return ProjectileEffect3D.execute(caster, aim, ability) if is_3d else ProjectileEffect.execute(caster, aim, ability)
		"ground_zone":
			return GroundZoneEffect3D.execute(caster, aim, ability) if is_3d else GroundZoneEffect.execute(caster, aim, ability)
	push_error("Unknown ability effect: %s" % effect_id)
	return false
