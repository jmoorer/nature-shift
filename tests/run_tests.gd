extends SceneTree
## Headless rule tests. Run:
##   godot --headless --path . -s tests/run_tests.gd
## The world is process-disabled so every step is driven manually (deterministic).

var _fails := 0
var _checks := 0
var _world: Node2D


func _initialize() -> void:
	await process_frame  # root is still busy setting up during _initialize
	_test_health_and_status()
	_test_cooldowns()
	_test_pool_applies_wet()
	_test_bolt_dry()
	_test_bolt_wet_bonus()
	_test_conduct_shocks_only_wet_occupants()
	_test_wet_outside_pool_not_conducted()
	_test_player_in_pool_is_shocked()
	_test_pool_consumed_after_shock()
	_test_bolt_miss_leaves_pool()
	_test_enemy_windup_interrupted_by_stun()
	_test_dash_iframes_dodge()
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
	_world = Node2D.new()
	_world.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(_world)


func _player(pos := Vector2.ZERO) -> Player:
	var p := Player.new()
	_world.add_child(p)
	p.global_position = pos
	p.equip([load("res://data/abilities/lightning_bolt.tres"), load("res://data/abilities/water_pool.tres")])
	return p


func _enemy(pos: Vector2, target: Combatant = null) -> Enemy:
	var e := Enemy.new()
	e.target = target
	_world.add_child(e)
	e.global_position = pos
	return e


func _zone_at(pos: Vector2) -> GroundZone:
	var z := GroundZone.new()
	z.setup(load("res://data/abilities/water_pool.tres"))
	_world.add_child(z)
	z.global_position = pos
	return z


## Fire a bolt from `from` toward `to` and step until it resolves.
func _fire_bolt(from: Player, to: Vector2) -> void:
	check(from.cast(0, to) == "ok", "bolt cast ok")
	var bolt: Bolt
	for c in _world.get_children():
		if c is Bolt:
			bolt = c
	for i in 200:
		if not is_instance_valid(bolt) or bolt.is_queued_for_deletion():
			return
		bolt.step(1.0 / 60.0)


func _test_health_and_status() -> void:
	var h := Health.new(50.0)
	check(h.take_damage(20.0) == 20.0 and h.current == 30.0, "damage applies")
	h.invulnerable = true
	check(h.take_damage(10.0) == 0.0, "invulnerable blocks damage")
	h.invulnerable = false
	var died := [false]
	h.died.connect(func(): died[0] = true)
	h.take_damage(999.0)
	check(h.is_dead() and died[0], "death fires once health hits 0")
	var s := StatusController.new()
	s.apply("wet", 1.0)
	s.apply("wet", 0.5)
	check(s.remaining("wet") == 1.0, "reapply keeps longer duration")
	s.tick(1.1)
	check(not s.has("wet"), "status expires")


func _test_cooldowns() -> void:
	_fresh()
	var p := _player()
	check(p.cast(0, Vector2(100, 0)) == "ok", "first cast ok")
	check(p.cast(0, Vector2(100, 0)) == "cooldown", "second cast blocked by cooldown")
	p.caster.tick(1.0)
	check(p.cast(0, Vector2(100, 0)) == "ok", "cast ok after cooldown")
	check(p.cast(1, Vector2(100, 0)) == "ok" and p.cast(1, Vector2(100, 0)) == "cooldown", "pool has its own cooldown")


func _test_pool_applies_wet() -> void:
	_fresh()
	var p := _player(Vector2(-300, 0))
	var inside := _enemy(Vector2(0, 0))
	var outside := _enemy(Vector2(0, 300))
	p.cast(1, Vector2(0, 0))
	var z: GroundZone
	for c in _world.get_children():
		if c is GroundZone:
			z = c
	check(z != null and z.global_position.distance_to(Vector2(-300, 0)) <= 330.01, "pool spawns within cast range")
	z.global_position = Vector2.ZERO
	z.tick(0.1)
	check(inside.status.has(Statuses.WET), "occupant becomes wet")
	check(not outside.status.has(Statuses.WET), "non-occupant stays dry")


func _test_bolt_dry() -> void:
	_fresh()
	var p := _player(Vector2(-300, 0))
	var e := _enemy(Vector2(0, 0))
	_fire_bolt(p, Vector2(0, 0))
	check(is_equal_approx(e.health.current, e.health.max_health - 14.0), "dry hit deals base damage (got %s)" % e.health.current)
	check(not e.status.has(Statuses.STUNNED), "dry hit does not stun")


func _test_bolt_wet_bonus() -> void:
	_fresh()
	var p := _player(Vector2(-300, 0))
	var e := _enemy(Vector2(0, 0))
	e.status.apply(Statuses.WET, 3.0)
	_fire_bolt(p, Vector2(0, 0))
	check(is_equal_approx(e.health.current, e.health.max_health - 21.0), "wet hit deals x1.5 (got %s)" % e.health.current)


func _test_conduct_shocks_only_wet_occupants() -> void:
	_fresh()
	var p := _player(Vector2(-400, 0))
	var z := _zone_at(Vector2(0, 0))
	var in_pool := _enemy(Vector2(30, 0))
	var out_pool := _enemy(Vector2(0, 250))
	z.tick(0.1)
	check(in_pool.status.has(Statuses.WET), "setup: in-pool enemy wet")
	out_pool.status.apply(Statuses.WET, 3.0)
	_fire_bolt(p, Vector2(0, 0))
	check(in_pool.health.current < in_pool.health.max_health - 14.0, "conduct adds damage beyond direct hit (got %s)" % in_pool.health.current)
	check(in_pool.status.has(Statuses.STUNNED), "conduct stuns occupant")
	check(is_equal_approx(out_pool.health.current, out_pool.health.max_health), "wet enemy outside pool is untouched")


func _test_wet_outside_pool_not_conducted() -> void:
	_fresh()
	var p := _player(Vector2(-400, 0))
	var z := _zone_at(Vector2(0, 300))
	var e := _enemy(Vector2(0, 0))
	e.status.apply(Statuses.WET, 3.0)
	_fire_bolt(p, Vector2(0, 0))
	check(not z.shocked, "pool far from target not shocked")
	check(not e.status.has(Statuses.STUNNED), "lingering Wet outside pool gets bonus damage only, no stun")


func _test_player_in_pool_is_shocked() -> void:
	_fresh()
	var p := _player(Vector2(0, 0))
	var z := _zone_at(Vector2(0, 0))
	var e := _enemy(Vector2(60, 0))
	z.tick(0.1)
	_fire_bolt(p, Vector2(60, 0))
	check(p.health.current < p.health.max_health, "standing in your own pool gets you shocked (hp %s)" % p.health.current)


func _test_pool_consumed_after_shock() -> void:
	_fresh()
	var p := _player(Vector2(-400, 0))
	var z := _zone_at(Vector2(0, 0))
	var e := _enemy(Vector2(0, 0))
	z.tick(0.1)
	_fire_bolt(p, Vector2(0, 0))
	check(z.shocked, "pool marked shocked")
	z.tick(0.5)
	check(z.is_queued_for_deletion(), "shocked pool collapses")
	check(z.electrify(40.0, 1.0) == 0, "spent pool cannot be reused")


func _test_bolt_miss_leaves_pool() -> void:
	_fresh()
	var p := _player(Vector2(-400, 0))
	var z := _zone_at(Vector2(0, 0))
	var e := _enemy(Vector2(0, 0))
	z.tick(0.1)
	p.cast(0, Vector2(-400, 400))
	var bolt: Bolt
	for c in _world.get_children():
		if c is Bolt:
			bolt = c
	for i in 300:
		if bolt.is_queued_for_deletion():
			break
		bolt.step(1.0 / 60.0)
	check(not z.shocked and is_equal_approx(e.health.current, e.health.max_health), "bolt that misses everything changes nothing")


func _test_enemy_windup_interrupted_by_stun() -> void:
	_fresh()
	var p := _player(Vector2(0, 0))
	var e := _enemy(Vector2(40, 0), p)
	e._act(0.016)
	check(e.state == Enemy.State.WINDUP, "enemy starts windup in range")
	e.status.apply(Statuses.STUNNED, 1.0)
	e._stunned(0.016)
	check(e.state == Enemy.State.RECOVER, "stun cancels windup")
	for i in 120:
		e.status.tick(0.016)
	var hp := p.health.current
	e._timer = 0.0
	e._act(0.016)
	check(p.health.current == hp, "no hit lands from cancelled windup")


func _test_dash_iframes_dodge() -> void:
	_fresh()
	var p := _player(Vector2(0, 0))
	var e := _enemy(Vector2(40, 0), p)
	e.state = Enemy.State.WINDUP
	e._timer = 0.001
	p.health.invulnerable = true
	e._act(0.016)
	check(p.health.current == p.health.max_health, "invulnerable player dodges swing")
	e.state = Enemy.State.WINDUP
	e._timer = 0.001
	p.health.invulnerable = false
	e._act(0.016)
	check(p.health.current == p.health.max_health - e.damage, "swing hits otherwise")


func _test_main_scene_smoke() -> void:
	_fresh()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	check(main.player != null and main.enemy != null and main.hud != null, "main scene builds encounter")
	check(InputMap.has_action("ability_1") and InputMap.has_action("restart"), "input actions registered")
	main.player.cast(1, Vector2(100, 0))
	main.queue_free()
