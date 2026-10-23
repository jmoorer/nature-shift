class_name Combatant3D
extends CharacterBody3D
## 3D counterpart of Combatant. Origin is at the feet; gameplay distances are
## measured on the XZ plane. Subclasses implement _act and may override _stunned.

signal died

@export var faction := "neutral"
@export var radius := 0.5
@export var height := 1.8
@export var max_health := 100.0
@export var body_color := Color.WHITE

var health: Health
var status: StatusController
var bounds := Rect2(-20, -12, 40, 24)  # XZ plane
var facing := Vector3(0, 0, -1)
## False in headless tests: body is outside a physics space, so integrate by hand.
var use_physics := true
var _flash := 0.0
var _body: MeshInstance3D
var _mat: StandardMaterial3D
var _wet_shell: MeshInstance3D
var _label: Label3D


func _ready() -> void:
	health = Health.new(max_health)
	status = StatusController.new()
	health.died.connect(func(): died.emit())
	add_to_group("combatants")
	_build_visuals()


func flat_pos() -> Vector2:
	return Vector2(global_position.x, global_position.z)


func _build_visuals() -> void:
	var col := CollisionShape3D.new()
	var cs := CapsuleShape3D.new()
	cs.radius = radius
	cs.height = height
	col.shape = cs
	col.position.y = height / 2.0
	add_child(col)

	_body = MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = radius
	cm.height = height
	_body.mesh = cm
	_body.position.y = height / 2.0
	_mat = Visuals.mat(body_color)
	_body.material_override = _mat
	add_child(_body)

	var nose := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.22, 0.22, 0.5)
	nose.mesh = bm
	nose.material_override = Visuals.mat(Color(0.1, 0.1, 0.1))
	nose.position = Vector3(0, height * 0.72, -radius)
	add_child(nose)

	_wet_shell = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius * 1.5
	sm.height = radius * 3.0
	_wet_shell.mesh = sm
	_wet_shell.material_override = Visuals.mat(Color(0.3, 0.6, 1.0, 0.3), 0.0, true)
	_wet_shell.position.y = height / 2.0
	_wet_shell.visible = false
	add_child(_wet_shell)

	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.pixel_size = 0.006
	_label.font_size = 48
	_label.outline_size = 10
	_label.position.y = height + 0.55
	add_child(_label)


func _process(delta: float) -> void:
	status.tick(delta)
	_flash = maxf(0.0, _flash - delta * 5.0)
	if not health.is_dead():
		if status.has(Statuses.STUNNED):
			_stunned(delta)
		else:
			_act(delta)
	_refresh_visuals()


func _act(_delta: float) -> void:
	pass


func _stunned(_delta: float) -> void:
	pass


## Apply horizontal velocity + gravity and move, keeping the body inside bounds.
func _move(delta: float, horizontal: Vector3) -> void:
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= 25.0 * delta
	if use_physics:
		move_and_slide()
	else:
		global_position += velocity * delta
	global_position.x = clampf(global_position.x, bounds.position.x + radius, bounds.end.x - radius)
	global_position.z = clampf(global_position.z, bounds.position.y + radius, bounds.end.y - radius)


func _face(dir: Vector3) -> void:
	dir.y = 0.0
	if dir.length() > 0.01:
		facing = dir.normalized()
		rotation.y = atan2(-facing.x, -facing.z)


## kind: "lightning", "shock", "melee" - feedback colour only.
func receive_damage(amount: float, kind: String = "") -> void:
	var dealt := health.take_damage(amount)
	if dealt <= 0.0:
		if health.invulnerable and not health.is_dead():
			_float_text("Dodged", Color(0.7, 1.0, 0.7))
		return
	_flash = 1.0
	var col := Color(1.0, 0.95, 0.3) if kind in ["lightning", "shock"] else Color(1.0, 0.4, 0.4)
	_float_text(str(roundi(dealt)), col)


func _float_text(text: String, col: Color) -> void:
	var ft := FloatingText3D.new()
	ft.setup(text, col)
	get_parent().add_child(ft)
	ft.global_position = global_position + Vector3(randf_range(-0.3, 0.3), height + 0.9, 0)


func _refresh_visuals() -> void:
	var dead := health.is_dead()
	var base := Color(0.3, 0.3, 0.3) if dead else body_color
	_mat.albedo_color = base.lerp(Color.WHITE, clampf(_flash, 0.0, 1.0))
	_wet_shell.visible = not dead and status.has(Statuses.WET)
	_label.visible = not dead
	var tags := ""
	if status.has(Statuses.WET):
		tags += "WET "
	if status.has(Statuses.STUNNED):
		tags += "STUNNED"
	_label.text = "%d/%d\n%s" % [ceili(health.current), roundi(health.max_health), tags]
	_label.modulate = Color(1.0, 0.95, 0.4) if status.has(Statuses.STUNNED) else Color.WHITE
