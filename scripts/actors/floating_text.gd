class_name FloatingText
extends Node2D

var text := ""
var color := Color.WHITE
var _age := 0.0


func setup(t: String, c: Color) -> void:
	text = t
	color = c
	z_index = 100


func _process(delta: float) -> void:
	_age += delta
	position.y -= 40.0 * delta
	if _age > 0.9:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var a := 1.0 - clampf((_age - 0.5) / 0.4, 0.0, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(color, a))
