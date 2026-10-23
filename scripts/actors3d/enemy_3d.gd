class_name Enemy3D
extends Combatant3D
## 3D melee chaser, same state machine as Enemy.

enum State { CHASE, WINDUP, RECOVER }

var target: Combatant3D
var speed := 3.2
var trigger_range := 1.3
var hit_range := 2.4
var windup_time := 0.7
var recover_time := 0.8
var damage := 18.0
var state := State.CHASE
var _timer := 0.0
var _tele_outline: MeshInstance3D
var _tele_fill: MeshInstance3D


func _ready() -> void:
	faction = "enemy"
	radius = 0.7
	height = 2.2
	max_health = 120.0
	body_color = Color(0.85, 0.35, 0.3)
	super()
	_tele_outline = _disc(Color(1.0, 0.25, 0.25, 0.25))
	_tele_fill = _disc(Color(1.0, 0.25, 0.25, 0.5))


func _disc(col: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = hit_range
	c.bottom_radius = hit_range
	c.height = 0.04
	m.mesh = c
	m.material_override = Visuals.mat(col, 0.0, true)
	m.position.y = 0.05
	m.visible = false
	add_child(m)
	return m


func _act(delta: float) -> void:
	if target == null or target.health.is_dead():
		_move(delta, Vector3.ZERO)
		return
	var to := target.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	_face(to)
	var hvel := Vector3.ZERO
	match state:
		State.CHASE:
			if dist <= trigger_range + target.radius:
				state = State.WINDUP
				_timer = windup_time
			else:
				hvel = facing * speed
		State.WINDUP:
			_timer -= delta
			if _timer <= 0.0:
				if dist <= hit_range + target.radius:
					target.receive_damage(damage, "melee")
				state = State.RECOVER
				_timer = recover_time
		State.RECOVER:
			_timer -= delta
			if _timer <= 0.0:
				state = State.CHASE
	_move(delta, hvel)


func _stunned(delta: float) -> void:
	state = State.RECOVER
	_timer = 0.3
	_move(delta, Vector3.ZERO)


func _refresh_visuals() -> void:
	super()
	var winding := state == State.WINDUP and not health.is_dead()
	_tele_outline.visible = winding
	_tele_fill.visible = winding
	if winding:
		var p := clampf(1.0 - _timer / windup_time, 0.02, 1.0)
		_tele_fill.scale = Vector3(p, 1.0, p)
