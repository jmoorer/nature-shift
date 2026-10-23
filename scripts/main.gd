extends Node2D
## Combat prototype encounter: one arena, one player, one enemy. R restarts.

const BOUNDS := Rect2(-800, -450, 1600, 900)
const PLAYER_ABILITIES := [
	"res://data/abilities/lightning_bolt.tres",
	"res://data/abilities/water_pool.tres",
]

var player: Player
var enemy: Enemy
var hud: Hud


func _ready() -> void:
	InputSetup.register()
	var arena := Arena.new()
	arena.bounds = BOUNDS
	add_child(arena)

	player = Player.new()
	player.bounds = BOUNDS
	add_child(player)
	player.global_position = Vector2(-350, 0)
	var abilities := []
	for path in PLAYER_ABILITIES:
		abilities.append(load(path))
	player.equip(abilities)

	enemy = Enemy.new()
	enemy.bounds = BOUNDS
	enemy.target = player
	add_child(enemy)
	enemy.global_position = Vector2(350, 0)

	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.limit_left = int(BOUNDS.position.x) - 40
	cam.limit_top = int(BOUNDS.position.y) - 40
	cam.limit_right = int(BOUNDS.end.x) + 40
	cam.limit_bottom = int(BOUNDS.end.y) + 40
	player.add_child(cam)

	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.player = player
	hud.enemy = enemy
	layer.add_child(hud)

	player.died.connect(func(): hud.banner = "DEFEATED")
	enemy.died.connect(func(): hud.banner = "ENEMY DEFEATED")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
