class_name Combatant
extends Node2D
## Shared body for anything that fights: health, statuses, placeholder drawing.
## Subclasses implement _act (normal behaviour) and may override _stunned.

signal died

@export var faction := "neutral"
@export var radius := 18.0
@export var max_health := 100.0
@export var body_color := Color.WHITE

var health: Health
var status: StatusController
var bounds := Rect2(-800, -450, 1600, 900)
var facing := Vector2.RIGHT
var _flash := 0.0


func _ready() -> void:
	health = Health.new(max_health)
	status = StatusController.new()
	health.died.connect(func(): died.emit())
	add_to_group("combatants")


func _process(delta: float) -> void:
	status.tick(delta)
	_flash = maxf(0.0, _flash - delta * 5.0)
	if not health.is_dead():
		if status.has(Statuses.STUNNED):
			_stunned(delta)
		else:
			_act(delta)
	queue_redraw()


func _act(_delta: float) -> void:
	pass


func _stunned(_delta: float) -> void:
	pass


## kind: "lightning", "shock", "melee" - used for feedback colour only.
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
	var ft := FloatingText.new()
	ft.setup(text, col)
	get_parent().add_child(ft)
	ft.global_position = global_position + Vector2(randf_range(-10, 10), -radius - 20)


func _draw() -> void:
	var dead := health.is_dead()
	var col := Color(0.3, 0.3, 0.3) if dead else body_color.lerp(Color.WHITE, clampf(_flash, 0.0, 1.0))
	draw_circle(Vector2.ZERO, radius, col)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(0, 0, 0, 0.6), 2.0)
	if dead:
		return
	draw_line(Vector2.ZERO, facing * radius, Color(0, 0, 0, 0.7), 3.0)
	if status.has(Statuses.WET):
		draw_arc(Vector2.ZERO, radius + 5.0, 0.0, TAU, 32, Color(0.3, 0.6, 1.0, 0.9), 3.0)
	_draw_extra()
	var w := 46.0
	var y := -radius - 14.0
	draw_rect(Rect2(-w / 2, y, w, 5), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(-w / 2, y, w * health.current / health.max_health, 5), Color(0.9, 0.25, 0.25))
	var font := ThemeDB.fallback_font
	var tags := ""
	if status.has(Statuses.WET):
		tags += "WET "
	if status.has(Statuses.STUNNED):
		tags += "STUNNED"
	if tags != "":
		draw_string(font, Vector2(-w / 2, y - 4), tags, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


func _draw_extra() -> void:
	pass
