extends Node2D

const BulletScene: Script = preload("res://scripts/bullet.gd")
const PlayerScene: Script = preload("res://scripts/player_tank.gd")
const EnemyScene: Script = preload("res://scripts/enemy_tank.gd")

const TILE: int = 32
const PLAYER_SPAWN: Vector2 = Vector2(16 * TILE + TILE / 2, 13 * TILE + TILE / 2)
const MAP: Array[String] = [
	"##############################",
	"#............##............###",
	"#..BB..SS....##....SS..BB....#",
	"#..BB..............BB........#",
	"#......BB..BBBB..BB..........#",
	"#..SS..BB........BB..SS......#",
	"#............SS............###",
	"#..BBBB..BB......BB..BBBB....#",
	"#............................#",
	"#..SS....BBBB..BBBB....SS....#",
	"#........BB......BB..........#",
	"#..BB..........SS......BB....#",
	"#......BB........BB..........#",
	"#..........BBBBB.............#",
	"#............E...............#",
	"##############################",
]

var player: PlayerTank
var score := 0
var lives := 3
var enemies_left := 4
var base_health := 3
var game_over := false

@onready var world := Node2D.new()
@onready var bullets := Node2D.new()
@onready var hud := CanvasLayer.new()
@onready var score_label := Label.new()
@onready var status_label := Label.new()


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#14171f"))
	world.position = Vector2(0, 96)
	add_child(world)
	add_child(bullets)
	add_child(hud)
	_build_arena()
	_spawn_player()
	_spawn_enemies()
	_build_hud()
	_update_hud()


func _build_arena() -> void:
	var floor := ColorRect.new()
	floor.color = Color("#202532")
	floor.size = Vector2(MAP[0].length() * TILE, MAP.size() * TILE)
	world.add_child(floor)

	for row in range(MAP.size()):
		var row_text: String = MAP[row]
		for col in range(row_text.length()):
			var tile: String = row_text.substr(col, 1)
			var position := Vector2(col * TILE + TILE / 2, row * TILE + TILE / 2)
			match tile:
				"#":
					_add_block(position, Color("#363c49"), "arena_wall", false)
				"B":
					_add_block(position, Color("#b86645"), "brick", true)
				"S":
					_add_block(position, Color("#71808d"), "steel", false)
				"E":
					_add_base(position)


func _add_block(center: Vector2, color: Color, group_name: String, destructible: bool) -> void:
	var block := StaticBody2D.new()
	block.position = center
	block.add_to_group(group_name)
	block.set_meta("destructible", destructible)
	world.add_child(block)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE, TILE)
	collision.shape = shape
	block.add_child(collision)

	var visual := ColorRect.new()
	visual.color = color
	visual.size = Vector2(TILE - 2, TILE - 2)
	visual.position = Vector2(-(TILE - 2) / 2, -(TILE - 2) / 2)
	block.add_child(visual)

	if group_name == "brick":
		var stripe := ColorRect.new()
		stripe.color = Color("#8f4533")
		stripe.size = Vector2(TILE - 2, 4)
		stripe.position = Vector2(-(TILE - 2) / 2, -2)
		block.add_child(stripe)


func _add_base(center: Vector2) -> void:
	var base := StaticBody2D.new()
	base.position = center
	base.add_to_group("base")
	world.add_child(base)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE, TILE)
	collision.shape = shape
	base.add_child(collision)

	var visual := ColorRect.new()
	visual.color = Color("#f0d05a")
	visual.size = Vector2(TILE - 4, TILE - 4)
	visual.position = Vector2(-(TILE - 4) / 2, -(TILE - 4) / 2)
	base.add_child(visual)

	var core := ColorRect.new()
	core.color = Color("#242832")
	core.size = Vector2(12, 12)
	core.position = Vector2(-6, -6)
	base.add_child(core)


func _spawn_player() -> void:
	player = PlayerScene.new() as PlayerTank
	player.position = PLAYER_SPAWN
	player.fired.connect(_spawn_bullet)
	player.destroyed.connect(_on_player_destroyed)
	world.add_child(player)
	player.make_invulnerable(1.5)


func _spawn_enemies() -> void:
	var spawn_points: Array[Vector2] = [
		Vector2(3 * TILE + TILE / 2, 1 * TILE + TILE / 2),
		Vector2(10 * TILE + TILE / 2, 2 * TILE + TILE / 2),
		Vector2(18 * TILE + TILE / 2, 2 * TILE + TILE / 2),
		Vector2(27 * TILE + TILE / 2, 3 * TILE + TILE / 2),
	]
	for point in spawn_points:
		var enemy: EnemyTank = EnemyScene.new() as EnemyTank
		enemy.position = point
		enemy.fired.connect(_spawn_bullet)
		enemy.destroyed.connect(_on_enemy_destroyed)
		world.add_child(enemy)


func _spawn_bullet(_tank: Tank, start_position: Vector2, direction: Vector2, team: String) -> void:
	var bullet: Bullet = BulletScene.new() as Bullet
	bullet.add_to_group("bullet")
	bullets.add_child(bullet)
	_build_bullet_visuals(bullet)
	bullet.setup(start_position, direction, team)
	bullet.hit_brick.connect(_on_bullet_hit_brick)
	bullet.hit_base.connect(_on_base_hit)
	bullet.hit_tank.connect(_on_bullet_hit_tank)


func _build_bullet_visuals(bullet: Bullet) -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(6, 12)
	collision.shape = shape
	bullet.add_child(collision)

	var visual := ColorRect.new()
	visual.color = Color("#f7ef9a")
	visual.size = Vector2(6, 12)
	visual.position = Vector2(-3, -6)
	bullet.add_child(visual)


func _build_hud() -> void:
	var panel := ColorRect.new()
	panel.color = Color("#10131acc")
	panel.size = Vector2(960, 72)
	hud.add_child(panel)

	score_label.position = Vector2(18, 14)
	score_label.add_theme_font_size_override("font_size", 22)
	hud.add_child(score_label)

	status_label.position = Vector2(18, 42)
	status_label.add_theme_font_size_override("font_size", 16)
	hud.add_child(status_label)


func _on_bullet_hit_brick(block: Node) -> void:
	block.queue_free()


func _on_bullet_hit_tank(tank: Node) -> void:
	if tank.has_method("take_hit"):
		tank.take_hit()


func _on_enemy_destroyed(_enemy: Tank) -> void:
	score += 100
	enemies_left -= 1
	if enemies_left <= 0:
		game_over = true
		status_label.text = "Victoria: defendiste la base y eliminaste todos los tanques enemigos."
	_update_hud()


func _on_player_destroyed(_tank: Tank) -> void:
	lives -= 1
	if lives <= 0:
		_on_game_over("Derrota: el tanque se quedo sin vidas.")
		return
	_update_hud()
	status_label.text = "Tanque destruido: reapareciendo con invulnerabilidad breve."
	_clear_enemy_bullets_near_spawn()
	await get_tree().create_timer(0.45).timeout
	if not game_over:
		_spawn_player()
		_update_hud()


func _on_base_hit(_team: String) -> void:
	if game_over:
		return
	base_health -= 1
	if base_health <= 0:
		_on_game_over("Derrota: la base fue destruida.")
		return
	_update_hud()
	status_label.text = "Base golpeada: integridad restante %s/3." % base_health


func _on_game_over(message: String) -> void:
	game_over = true
	status_label.text = message
	if is_instance_valid(player):
		player.queue_free()


func _clear_enemy_bullets_near_spawn() -> void:
	var spawn_global := world.to_global(PLAYER_SPAWN)
	for bullet in bullets.get_children():
		if bullet is Bullet and bullet.owner_team == "enemy" and bullet.global_position.distance_to(spawn_global) < TILE * 4:
			bullet.queue_free()


func _update_hud() -> void:
	score_label.text = "Battle City Godot  |  Puntos: %s  |  Vidas: %s  |  Base: %s/3  |  Enemigos: %s" % [score, lives, base_health, enemies_left]
	if not game_over:
		status_label.text = "WASD para mover, Espacio para disparar. Objetivo: proteger la base inferior."
