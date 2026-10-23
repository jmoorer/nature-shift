extends Node3D
## 3D combat prototype encounter. R restarts, ESC frees the mouse.

const BOUNDS := Rect2(-20, -12, 40, 24)
const PLAYER_ABILITIES := [
	"res://data/abilities/3d/lightning_bolt.tres",
	"res://data/abilities/3d/water_pool.tres",
]

var player: Player3D
var enemy: Enemy3D
var hud: Hud


func _ready() -> void:
	InputSetup.register()
	var arena := Arena3D.new()
	arena.bounds = BOUNDS
	add_child(arena)

	player = Player3D.new()
	player.bounds = BOUNDS
	add_child(player)
	player.global_position = Vector3(-10, 0.1, 0)
	player.rotation.y = -PI / 2.0  # face +X toward the enemy
	var abilities := []
	for path in PLAYER_ABILITIES:
		abilities.append(load(path))
	player.equip(abilities)

	enemy = Enemy3D.new()
	enemy.bounds = BOUNDS
	enemy.target = player
	add_child(enemy)
	enemy.global_position = Vector3(10, 0.1, 0)

	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.player = player
	hud.enemy = enemy
	hud.crosshair = true
	layer.add_child(hud)

	player.died.connect(func(): hud.banner = "DEFEATED")
	enemy.died.connect(func(): hud.banner = "ENEMY DEFEATED")

	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().reload_current_scene()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
