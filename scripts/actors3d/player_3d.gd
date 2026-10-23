class_name Player3D
extends Combatant3D
## Third-person, mouse-aimed player. Body yaw follows the camera yaw; abilities
## aim at the point under the screen-centre crosshair.

const DASH_TIME := 0.16
const DASH_SPEED := 17.0
const DASH_COOLDOWN := 0.8
const MOUSE_SENS := 0.0025

var caster: AbilityCaster
var speed := 6.5
var accel := 60.0
var dash_cooldown_left := 0.0
var camera: Camera3D
var _pitch: Node3D
var _hvel := Vector3.ZERO
var _dash_left := 0.0
var _dash_dir := Vector3.ZERO
var _skip_cast := false


func _ready() -> void:
	faction = "player"
	radius = 0.45
	height = 1.8
	max_health = 100.0
	body_color = Color(0.35, 0.85, 0.5)
	super()
	_pitch = Node3D.new()
	_pitch.position.y = 1.6
	_pitch.rotation.x = -0.25
	add_child(_pitch)
	var arm := SpringArm3D.new()
	arm.spring_length = 5.0
	arm.margin = 0.3
	arm.collision_mask = 1
	arm.add_excluded_object(get_rid())
	_pitch.add_child(arm)
	camera = Camera3D.new()
	camera.h_offset = 0.9
	camera.fov = 70.0
	arm.add_child(camera)
	camera.make_current()


func equip(abilities: Array) -> void:
	caster = AbilityCaster.new(self, abilities)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * MOUSE_SENS
		_pitch.rotation.x = clampf(_pitch.rotation.x - event.relative.y * MOUSE_SENS, -1.1, 0.35)
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_skip_cast = true


func _process(delta: float) -> void:
	if caster:
		caster.tick(delta)
	dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
	super(delta)


## World point under the crosshair (floor/wall hit, or far along the ray).
func get_aim_point() -> Vector3:
	var vp := get_viewport()
	if vp == null or camera == null or not camera.is_inside_tree():
		return global_position + facing * 10.0
	var c := vp.get_visible_rect().size / 2.0
	var origin := camera.project_ray_origin(c)
	var normal := camera.project_ray_normal(c)
	var q := PhysicsRayQueryParameters3D.create(origin, origin + normal * 120.0)
	q.exclude = [get_rid()]
	q.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position if hit else origin + normal * 120.0


func _act(delta: float) -> void:
	facing = Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var wish := basis * Vector3(input.x, 0.0, input.y)

	if _dash_left > 0.0:
		_dash_left -= delta
		_hvel = _dash_dir * DASH_SPEED
		if _dash_left <= 0.0:
			health.invulnerable = false
	else:
		_hvel = _hvel.move_toward(wish * speed, accel * delta)
		if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0.0:
			_dash_dir = wish.normalized() if wish != Vector3.ZERO else facing
			_dash_left = DASH_TIME
			dash_cooldown_left = DASH_COOLDOWN
			health.invulnerable = true
	_move(delta, _hvel)

	if _skip_cast:
		_skip_cast = false
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	for slot in 2:
		if Input.is_action_just_pressed("ability_%d" % (slot + 1)):
			cast(slot, get_aim_point())


func cast(slot: int, aim: Vector3) -> String:
	var result := caster.cast(slot, aim)
	if result == "cooldown":
		var name: String = caster.slots[slot].display_name
		get_tree().call_group("hud", "toast", "%s: %.1fs left" % [name, caster.cooldown_left(slot)], Color(1.0, 0.5, 0.4))
	return result


func _stunned(delta: float) -> void:
	_dash_left = 0.0
	health.invulnerable = false
	_hvel = Vector3.ZERO
	_move(delta, Vector3.ZERO)
