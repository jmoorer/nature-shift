class_name Arena3D
extends Node3D
## Floor, walls, lights and sky. Collision layer 1 = world.

var bounds := Rect2(-20, -12, 40, 24)  # XZ plane


func _ready() -> void:
	_box(Vector3(bounds.size.x, 1.0, bounds.size.y), Vector3(0, -0.5, 0), Color(0.17, 0.19, 0.22), true)
	var x := bounds.position.x
	while x <= bounds.end.x + 0.01:
		_box(Vector3(0.06, 0.02, bounds.size.y), Vector3(x, 0.01, 0), Color(1, 1, 1, 0.08), false)
		x += 4.0
	var z := bounds.position.y
	while z <= bounds.end.y + 0.01:
		_box(Vector3(bounds.size.x, 0.02, 0.06), Vector3(0, 0.01, z), Color(1, 1, 1, 0.08), false)
		z += 4.0
	var wall := Color(0.32, 0.33, 0.4)
	var t := 0.6
	var cx := bounds.get_center().x
	var cz := bounds.get_center().y
	_box(Vector3(bounds.size.x + t * 2, 3.0, t), Vector3(cx, 1.5, bounds.position.y - t / 2), wall, true)
	_box(Vector3(bounds.size.x + t * 2, 3.0, t), Vector3(cx, 1.5, bounds.end.y + t / 2), wall, true)
	_box(Vector3(t, 3.0, bounds.size.y), Vector3(bounds.position.x - t / 2, 1.5, cz), wall, true)
	_box(Vector3(t, 3.0, bounds.size.y), Vector3(bounds.end.x + t / 2, 1.5, cz), wall, true)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60, 30, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.1, 0.16)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.55, 0.7)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _box(size: Vector3, pos: Vector3, color: Color, solid: bool) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.material_override = Visuals.mat(color)
	m.position = pos
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		body.add_child(cs)
		body.position = pos
		add_child(body)
		m.position = Vector3.ZERO
		body.add_child(m)
	else:
		add_child(m)
