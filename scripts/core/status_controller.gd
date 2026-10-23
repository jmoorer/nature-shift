class_name StatusController
extends RefCounted
## Timed statuses by id. Re-applying refreshes to the longer remaining time.

signal added(id: String)
signal removed(id: String)

var _remaining := {}


func apply(id: String, duration: float) -> void:
	var is_new := not _remaining.has(id)
	_remaining[id] = maxf(_remaining.get(id, 0.0), duration)
	if is_new:
		added.emit(id)


func has(id: String) -> bool:
	return _remaining.has(id)


func remaining(id: String) -> float:
	return _remaining.get(id, 0.0)


func ids() -> Array:
	return _remaining.keys()


func tick(delta: float) -> void:
	for id in _remaining.keys():
		_remaining[id] -= delta
		if _remaining[id] <= 0.0:
			_remaining.erase(id)
			removed.emit(id)
