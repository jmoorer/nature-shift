class_name InputSetup
extends RefCounted
## Registers input actions in code so project.godot stays free of event blobs.


static func register() -> void:
	_keys("move_left", [KEY_A, KEY_LEFT])
	_keys("move_right", [KEY_D, KEY_RIGHT])
	_keys("move_up", [KEY_W, KEY_UP])
	_keys("move_down", [KEY_S, KEY_DOWN])
	_keys("dash", [KEY_SPACE, KEY_SHIFT])
	_keys("restart", [KEY_R])
	_keys("ability_1", [KEY_J, KEY_1])
	_keys("ability_2", [KEY_K, KEY_2])
	_mouse("ability_1", MOUSE_BUTTON_LEFT)
	_mouse("ability_2", MOUSE_BUTTON_RIGHT)


static func _add(action: String, ev: InputEvent) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_add_event(action, ev)


static func _keys(action: String, keys: Array) -> void:
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		_add(action, ev)


static func _mouse(action: String, button: int) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	_add(action, ev)
