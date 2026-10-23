class_name Enemy
extends Combatant
## Basic melee chaser: approach, telegraphed swing, short recovery.
## Stun interrupts a windup. A well-timed dash (i-frames) dodges the swing.

enum State { CHASE, WINDUP, RECOVER }

var target: Combatant
var speed := 100.0
var trigger_range := 50.0
var hit_range := 64.0
var windup_time := 0.7
var recover_time := 0.8
var damage := 18.0
var state := State.CHASE
var _timer := 0.0


func _ready() -> void:
	faction = "enemy"
	radius = 22.0
	max_health = 120.0
	body_color = Color(0.85, 0.35, 0.3)
	super()


func _act(delta: float) -> void:
	if target == null or target.health.is_dead():
		return
	var to_target := target.global_position - global_position
	if to_target.length() > 1.0:
		facing = to_target.normalized()
	match state:
		State.CHASE:
			if to_target.length() <= trigger_range + target.radius:
				state = State.WINDUP
				_timer = windup_time
			else:
				global_position = (global_position + facing * speed * delta).clamp(bounds.position, bounds.end)
		State.WINDUP:
			_timer -= delta
			if _timer <= 0.0:
				if to_target.length() <= hit_range + target.radius:
					target.receive_damage(damage, "melee")
				state = State.RECOVER
				_timer = recover_time
		State.RECOVER:
			_timer -= delta
			if _timer <= 0.0:
				state = State.CHASE


func _stunned(_delta: float) -> void:
	state = State.RECOVER
	_timer = 0.3


func _draw_extra() -> void:
	if state == State.WINDUP:
		var p := 1.0 - _timer / windup_time
		draw_circle(Vector2.ZERO, hit_range, Color(1.0, 0.2, 0.2, 0.12 + 0.2 * p))
		draw_arc(Vector2.ZERO, hit_range * p, 0.0, TAU, 32, Color(1.0, 0.3, 0.3, 0.9), 3.0)
		draw_arc(Vector2.ZERO, hit_range, 0.0, TAU, 32, Color(1.0, 0.3, 0.3, 0.7), 2.0)
