class_name FloatingText3D
extends Label3D

var _age := 0.0
var _color := Color.WHITE


func setup(t: String, c: Color) -> void:
	text = t
	_color = c
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	pixel_size = 0.01
	font_size = 56
	outline_size = 12
	modulate = c


func _process(delta: float) -> void:
	_age += delta
	position.y += 1.4 * delta
	modulate = Color(_color, 1.0 - clampf((_age - 0.5) / 0.4, 0.0, 1.0))
	if _age > 0.9:
		queue_free()
