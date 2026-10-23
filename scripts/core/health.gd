class_name Health
extends RefCounted

signal damaged(amount: float)
signal died

var max_health: float
var current: float
var invulnerable := false


func _init(max_hp: float = 100.0) -> void:
	max_health = max_hp
	current = max_hp


func is_dead() -> bool:
	return current <= 0.0


## Returns damage actually dealt (0 when dead, invulnerable, or amount <= 0).
func take_damage(amount: float) -> float:
	if is_dead() or invulnerable or amount <= 0.0:
		return 0.0
	var dealt := minf(amount, current)
	current -= dealt
	damaged.emit(dealt)
	if current <= 0.0:
		died.emit()
	return dealt
