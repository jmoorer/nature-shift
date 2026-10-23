class_name Hud
extends Control

var player  # Player or Player3D
var enemy  # Enemy or Enemy3D
var crosshair := true
var banner := ""
var _toasts := []


func _ready() -> void:
	add_to_group("hud")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func toast(text: String, color: Color = Color.WHITE) -> void:
	_toasts.append({"text": text, "color": color, "t": 2.5})
	if _toasts.size() > 5:
		_toasts.pop_front()


func _process(delta: float) -> void:
	for t in _toasts:
		t.t -= delta
	_toasts = _toasts.filter(func(t): return t.t > 0.0)
    10|	_highlighted_enemy = null
	if enemy and not enemy.health.is_dead():
		var mouse := get_global_mouse_position()
		if mouse.distance_to(enemy.global_position) <= enemy.radius + 80:
			_highlighted_enemy = enemy

	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var s := size
	if player:
		_bar(Vector2(20, s.y - 36), Vector2(260, 16), player.health.current / player.health.max_health, Color(0.3, 0.85, 0.4), "YOU")
		for i in player.caster.slots.size():
			var ab: AbilityData = player.caster.slots[i]
			_slot(Vector2(s.x / 2 - 190 + i * 130, s.y - 64), ab.display_name, ["LMB", "RMB"][i], player.caster.cooldown_fraction(i), ab.color)
		_slot(Vector2(s.x / 2 + 70, s.y - 64), "Dash", "SPACE", player.dash_cooldown_left / player.DASH_COOLDOWN, Color(0.8, 0.8, 0.8))
	if enemy:
		_bar(Vector2(s.x / 2 - 150, 20), Vector2(300, 16), enemy.health.current / enemy.health.max_health, Color(0.9, 0.3, 0.3), "ENEMY")
	var y := 70.0
	for t in _toasts:
		draw_string(font, Vector2(20, y), t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(t.color, minf(1.0, t.t)))
		y += 24.0
	draw_string(font, Vector2(s.x - 480 if crosshair else s.x - 330, 28), "WASD move | LMB bolt | RMB pool | SPACE dash | R restart | ESC free mouse" if crosshair else "WASD move | LMB bolt | RMB pool | SPACE dash | R restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.6))
	if crosshair:
		var c := s / 2
		for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			draw_line(c + d * 6, c + d * 14, Color(1, 1, 1, 0.9), 2.0)
		draw_circle(c, 1.5, Color(1, 1, 1, 0.9))
		# Target reticle: range circle when aiming at enemy
		if _highlighted_enemy:
			var mouse := get_global_mouse_position()
			draw_circle(mouse, 6, Color(1, 1, 1, 0.9))
			draw_circle(mouse, 10, Color(0.4, 0.8, 1, 0.4))
	if banner != "":
		draw_string(font, Vector2(0, s.y / 2 - 20), banner, HORIZONTAL_ALIGNMENT_CENTER, s.x, 42, Color.WHITE)
		draw_string(font, Vector2(0, s.y / 2 + 20), "Press R to restart", HORIZONTAL_ALIGNMENT_CENTER, s.x, 22, Color(1, 1, 1, 0.8))


func _bar(pos: Vector2, sz: Vector2, frac: float, col: Color, label: String) -> void:
	draw_rect(Rect2(pos, sz), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(pos, Vector2(sz.x * clampf(frac, 0.0, 1.0), sz.y)), col)
	draw_string(ThemeDB.fallback_font, pos + Vector2(4, sz.y - 3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


func _slot(pos: Vector2, label: String, key: String, cd_frac: float, col: Color) -> void:
	var box := Rect2(pos, Vector2(120, 48))
	draw_rect(box, Color(0, 0, 0, 0.6))
	draw_rect(box, Color(col, 0.9 if cd_frac <= 0.0 else 0.3), false, 2.0)
	if cd_frac > 0.0:
		draw_rect(Rect2(pos, Vector2(box.size.x * cd_frac, box.size.y)), Color(0, 0, 0, 0.55))
	var font := ThemeDB.fallback_font
	draw_string(font, pos + Vector2(6, 20), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	draw_string(font, pos + Vector2(6, 40), key + ("  ready" if cd_frac <= 0.0 else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.7))
