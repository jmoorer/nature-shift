class_name GroundZone
extends Node2D
## Lasting floor area that applies a status to everyone standing in it.
## A conductive zone can be electrified once: it shocks every occupant that is
## Wet, then collapses.

var radius := 90.0
var remaining := 6.0
var status_id := Statuses.WET
var status_duration := 3.0
var conductive := true
var color := Color(0.25, 0.55, 1.0)
var shocked := false
var _fade := 0.0
var _total := 6.0


func setup(ab: AbilityData) -> void:
	radius = ab.params.radius
	remaining = ab.params.duration
	_total = remaining
	status_id = ab.params.status
	status_duration = ab.params.status_duration
	conductive = ab.params.get("conductive", false)
	color = ab.color


func _ready() -> void:
	add_to_group("zones")
	z_index = -5


func contains(p: Vector2) -> bool:
	return global_position.distance_to(p) <= radius


func occupants() -> Array:
	var out := []
	for c in get_tree().get_nodes_in_group("combatants"):
		if not c.health.is_dead() and contains(c.global_position):
			out.append(c)
	return out


func tick(delta: float) -> void:
	if shocked:
		_fade -= delta
		if _fade <= 0.0:
			queue_free()
		return
	remaining -= delta
	if remaining <= 0.0:
		queue_free()
		return
	for c in occupants():
		c.status.apply(status_id, status_duration)


## Shocks every Wet occupant. Returns how many were hit (0 if not conductive or spent).
func electrify(damage: float, stun: float) -> int:
	if not conductive or shocked:
		return 0
	shocked = true
	_fade = 0.4
	var hits := 0
	for c in occupants():
		if c.status.has(Statuses.WET):
			c.receive_damage(damage, "shock")
			c.status.apply(Statuses.STUNNED, stun)
			hits += 1
	get_tree().call_group("hud", "toast", "CONDUCTED! %d shocked" % hits if hits > 0 else "Pool shocked - nobody inside", Color(1.0, 0.9, 0.3))
	return hits


func _process(delta: float) -> void:
	tick(delta)
	queue_redraw()


func _draw() -> void:
	if shocked:
		var a := clampf(_fade / 0.4, 0.0, 1.0)
		draw_circle(Vector2.ZERO, radius, Color(1.0, 0.95, 0.3, 0.55 * a))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1.0, 1.0, 0.7, a), 4.0)
		return
	var blink := 1.0 if remaining > 1.5 else (0.5 + 0.5 * sin(remaining * 20.0))
	draw_circle(Vector2.ZERO, radius, Color(color, 0.28 * blink))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(color, 0.9 * blink), 3.0)
