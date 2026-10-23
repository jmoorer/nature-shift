extends SceneTree
## Headless 3D rule tests. Run:
##   godot --headless --path . -s tests/run_tests_3d.gd
## The world is process-disabled; bolts, zones and AI are stepped manually.

const BOLT := "res://data/abilities/3d/lightning_bolt.tres"
const POOL := "res://data/abilities/3d/water_pool.tres"

var _fails := 0
var _checks := 0
var _world: Node3D


func _initialize() -> void:
	await process_frame  # root is still busy setting up during _initialize
	_test_cooldowns()
	_test_pool_range_and_wet()
	_test_bolt_dry()
	_test_bolt_wet_bonus()
	_test_conduct_shocks_only_wet_occupants()
	_test_wet_outside_pool_not_conducted()
	_test_player_in_pool_is_shocked()
	_test_pool_consumed()
	_test_height_ignored()
	_test_enemy_interrupt_and_dodge()
	_test_main_scene_smoke()
	print("%d checks, %d failed" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


func check(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_fails += 1
		print("FAIL: ", label)


func _fresh() -> void:
	if _world:
		_world.free()
	_world = Node3D.new()
	_world.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(_world)


func _player(pos := Vector3.ZERO) -> Player3D:
	var p := Player3D.new()
	p.use_physics = false
	_world.add_child(p)
	p.global_position = pos
	p.equip([load(BOLT), load(POOL)])
	return p


func _enemy(pos: Vector3, target: Combatant3D = null) -> Enemy3D:
	var e := Enemy3D.new()
	e.use_physics = false
	e.target = target
	_world.add_child(e)
	e.global_position = pos
	return e


func _zone_at(pos: Vector3) -> GroundZone3D:
	var z := GroundZone3D.new()
	z.setup(load(POOL))
	_world.add_child(z)
	z.global_position = pos
	return z


func _children_of(type_check: Callable) -> Array:
	return _world.get_children().filter(type_check)


func _fire_bolt(from: Player3D, to: Vector3) -> void:
	check(from.cast(0, to) == "ok", "bolt cast ok")
	var bolts := _children_of(func(n): return n is Bolt3D)
	var bolt: Bolt3D = bolts[bolts.size() - 1]
	for i in 400:
		if bolt.is_queued_for_deletion():
			return
		bolt.step(1.0 / 60.0)


func _test_cooldowns() -> void:
	_fresh()
	var p := _player()
	check(p.cast(0, Vector3(10, 0, 0)) == "ok", "first cast ok")
	check(p.cast(0, Vector3(10, 0, 0)) == "cooldown", "second cast blocked")
	p.caster.tick(1.0)
	check(p.cast(0, Vector3(10, 0, 0)) == "ok", "cast ok after cooldown")
	check(p.cast(1, Vector3(5, 0, 0)) == "ok" and p.cast(1, Vector3(5, 0, 0)) == "cooldown", "pool own cooldown")


func _test_pool_range_and_wet() -> void:
	_fresh()
	var p := _player(Vector3(-10, 0, 0))
	var inside := _enemy(Vector3(0, 0, 0))
	var outside := _enemy(Vector3(0, 0, 9))
	p.cast(1, Vector3(30, 0, 0))  # far beyond range
	var z: GroundZone3D = _children_of(func(n): return n is GroundZone3D)[0]
	check(absf(z.global_position.x - 0.0) < 0.01, "pool clamped to max range 10 (x=%s)" % z.global_position.x)
	z.tick(0.1)
	check(inside.status.has(Statuses.WET), "occupant becomes wet")
	check(not outside.status.has(Statuses.WET), "non-occupant dry")


func _test_bolt_dry() -> void:
	_fresh()
	var p := _player(Vector3(-10, 0, 0))
	var e := _enemy(Vector3(0, 0, 0))
	_fire_bolt(p, Vector3(0, 0, 0))
	check(is_equal_approx(e.health.current, e.health.max_health - 14.0), "dry hit = 14 (got %s)" % e.health.current)
	check(not e.status.has(Statuses.STUNNED), "dry hit no stun")


func _test_bolt_wet_bonus() -> void:
	_fresh()
	var p := _player(Vector3(-10, 0, 0))
	var e := _enemy(Vector3(0, 0, 0))
	e.status.apply(Statuses.WET, 3.0)
	_fire_bolt(p, Vector3(0, 0, 0))
	check(is_equal_approx(e.health.current, e.health.max_health - 21.0), "wet hit x1.5 (got %s)" % e.health.current)


func _test_conduct_shocks_only_wet_occupants() -> void:
	_fresh()
	var p := _player(Vector3(-12, 0, 0))
	var z := _zone_at(Vector3(0, 0, 0))
	var in_pool := _enemy(Vector3(0.8, 0, 0))
	var out_pool := _enemy(Vector3(0, 0, 7))
	z.tick(0.1)
	out_pool.status.apply(Statuses.WET, 3.0)
	_fire_bolt(p, Vector3(0, 0, 0))
	check(in_pool.health.current < in_pool.health.max_health - 14.0, "conduct adds damage (got %s)" % in_pool.health.current)
	check(in_pool.status.has(Statuses.STUNNED), "conduct stuns")
	check(is_equal_approx(out_pool.health.current, out_pool.health.max_health), "wet enemy outside pool untouched")


func _test_wet_outside_pool_not_conducted() -> void:
	_fresh()
	var p := _player(Vector3(-12, 0, 0))
	var z := _zone_at(Vector3(0, 0, 8))
	var e := _enemy(Vector3(0, 0, 0))
	e.status.apply(Statuses.WET, 3.0)
	_fire_bolt(p, Vector3(0, 0, 0))
	check(not z.shocked and not e.status.has(Statuses.STUNNED), "lingering Wet outside pool: bonus only")


func _test_player_in_pool_is_shocked() -> void:
	_fresh()
	var p := _player(Vector3(0, 0, 0))
	var z := _zone_at(Vector3(0, 0, 0))
	var e := _enemy(Vector3(1.8, 0, 0))
	z.tick(0.1)
	_fire_bolt(p, Vector3(1.8, 0, 0))
	check(p.health.current < p.health.max_health, "standing in own pool shocks you (hp %s)" % p.health.current)


func _test_pool_consumed() -> void:
	_fresh()
	var p := _player(Vector3(-12, 0, 0))
	var z := _zone_at(Vector3(0, 0, 0))
	_enemy(Vector3(0, 0, 0))
	z.tick(0.1)
	_fire_bolt(p, Vector3(0, 0, 0))
	check(z.shocked, "pool shocked")
	z.tick(0.5)
	check(z.is_queued_for_deletion(), "shocked pool collapses")
	check(z.electrify(40.0, 1.0) == 0, "spent pool not reusable")


func _test_height_ignored() -> void:
	_fresh()
	var p := _player(Vector3(-12, 0, 0))
	var e := _enemy(Vector3(0, 0, 0))
	_fire_bolt(p, Vector3(0, 6, 0))  # aim point high above target: still flat-aimed
	check(e.health.current < e.health.max_health, "aim height does not make the bolt miss")


func _test_enemy_interrupt_and_dodge() -> void:
	_fresh()
	var p := _player(Vector3(0, 0, 0))
	var e := _enemy(Vector3(1.5, 0, 0), p)
	e._act(0.016)
	check(e.state == Enemy3D.State.WINDUP, "enemy windup in range")
	e.status.apply(Statuses.STUNNED, 1.0)
	e._stunned(0.016)
	check(e.state == Enemy3D.State.RECOVER, "stun cancels windup")
	e.state = Enemy3D.State.WINDUP
	e._timer = 0.001
	p.health.invulnerable = true
	e._act(0.016)
	check(p.health.current == p.health.max_health, "invulnerable player dodges swing")
	e.state = Enemy3D.State.WINDUP
	e._timer = 0.001
	p.health.invulnerable = false
	e._act(0.016)
	check(p.health.current == p.health.max_health - e.damage, "swing hits otherwise")


func _test_main_scene_smoke() -> void:
	_fresh()
	var main: Node = load("res://scenes/main_3d.tscn").instantiate()
	root.add_child(main)
	await process_frame
	check(main.player != null and main.enemy != null and main.hud != null, "3D encounter builds")
	check(main.player.camera != null, "camera rig built")
	main.player.cast(1, Vector3(-5, 0, 0))
	for i in 20:
		await process_frame
	main.queue_free()
