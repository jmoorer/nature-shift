class_name AbilityCaster
extends RefCounted
## Owns an actor's ability slots and cooldowns.

var owner_actor: Node
var slots: Array = []
var _cooldowns := {}


func _init(actor: Node, abilities: Array) -> void:
	owner_actor = actor
	slots = abilities


func tick(delta: float) -> void:
	for slot in _cooldowns.keys():
		_cooldowns[slot] = maxf(0.0, _cooldowns[slot] - delta)


func cooldown_left(slot: int) -> float:
	return _cooldowns.get(slot, 0.0)


## 0 = ready, 1 = just cast.
func cooldown_fraction(slot: int) -> float:
	var ab: AbilityData = slots[slot]
	return cooldown_left(slot) / ab.cooldown if ab.cooldown > 0.0 else 0.0


## Returns "ok", "cooldown", "empty" or "failed".
func cast(slot: int, aim: Variant) -> String:
	if slot >= slots.size():
		return "empty"
	if cooldown_left(slot) > 0.0:
		return "cooldown"
	var ab: AbilityData = slots[slot]
	if not AbilityEffects.execute(ab.effect, owner_actor, aim, ab):
		return "failed"
	_cooldowns[slot] = ab.cooldown
	return "ok"
