class_name Player
extends Combatant

const DASH_TIME := 0.16
const DASH_SPEED := 680.0
const DASH_COOLDOWN := 0.8

var caster: AbilityCaster
var speed := 240.0
var accel := 2600.0
var velocity := Vector2.ZERO
var dash_cooldown_left := 0.0
var _dash_left := 0.0
var _dash_dir := Vector2.ZERO


func _ready() -> void:
	faction = "player"
	radius = 16.0
	max_health = 100.0
	body_color = Color(0.35, 0.85, 0.5)
	super()


func equip(abilities: Array) -> void:
	caster = AbilityCaster.new(self, abilities)


func _process(delta: float) -> void:
	if caster:
		caster.tick(delta)
	dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
	super(delta)


func _act(delta: float) -> void:
	var aim := get_global_mouse_position()
	if aim.distance_to(global_position) > 1.0:
		facing = (aim - global_position).normalized()
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if _dash_left > 0.0:
		_dash_left -= delta
		velocity = _dash_dir * DASH_SPEED
		if _dash_left <= 0.0:
			health.invulnerable = false
	else:
		velocity = velocity.move_toward(input * speed, accel * delta)
		if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0.0:
			_dash_dir = input if input != Vector2.ZERO else facing
			_dash_left = DASH_TIME
			dash_cooldown_left = DASH_COOLDOWN
			health.invulnerable = true
	global_position = (global_position + velocity * delta).clamp(bounds.position + Vector2.ONE * radius, bounds.end - Vector2.ONE * radius)

	for slot in 2:
		if Input.is_action_just_pressed("ability_%d" % (slot + 1)):
			cast(slot, aim)


func cast(slot: int, aim: Vector2) -> String:
	var result := caster.cast(slot, aim)
	var name: String = caster.slots[slot].display_name if slot < caster.slots.size() else "?"
	match result:
		"cooldown":
			get_tree().call_group("hud", "toast", "%s: %.1fs left" % [name, caster.cooldown_left(slot)], Color(1.0, 0.5, 0.4))
	return result


func _stunned(_delta: float) -> void:
	_dash_left = 0.0
	health.invulnerable = false
	velocity = Vector2.ZERO
