class_name Arena
extends Node2D

var bounds := Rect2(-800, -450, 1600, 900)


func _ready() -> void:
	z_index = -20


func _draw() -> void:
	draw_rect(bounds, Color(0.16, 0.17, 0.2))
	var x := bounds.position.x
	while x <= bounds.end.x:
		draw_line(Vector2(x, bounds.position.y), Vector2(x, bounds.end.y), Color(1, 1, 1, 0.04))
		x += 100.0
	var y := bounds.position.y
	while y <= bounds.end.y:
		draw_line(Vector2(bounds.position.x, y), Vector2(bounds.end.x, y), Color(1, 1, 1, 0.04))
		y += 100.0
	draw_rect(bounds, Color(0.6, 0.6, 0.7), false, 6.0)
